#!/usr/bin/env bun
// run-loop.ts — Eval runner for Bulwark skills.
//
// Reads <skill>/evals/evals.json, executes each test via `claude -p` headless,
// captures stream-json trace to <skill>/evals/runs/<timestamp>/<test-id>.jsonl.
//
// Usage:
//   bun run <path-to-this-script> <path-to-skill>
//
// The plugin entrypoint is `just eval-skill <path>` which resolves the script
// path correctly regardless of whether the user is running from the plugin
// cache, a `.claude/skills/` copy, or a development checkout.
//
// Optional env vars:
//   BULWARK_PLUGIN_DIR — path to bulwark plugin checkout to pass via --plugin-dir.
//                        If unset, relies on installed plugin discovery.
//   BULWARK_EVAL_MODEL — override default model (e.g., "sonnet"). Optional.
//
// Schema: see ../references/eval-shape.md (eval-shape-v1).

import { existsSync, mkdirSync, statSync } from "fs";
import { resolve, join } from "path";

interface Assertion {
  type: string;
  [key: string]: unknown;
}

interface Test {
  id: string;
  description?: string;
  prompt: string;
  allowed_tools?: string[];
  timeout_seconds?: number;
  assertions: Assertion[];
}

interface EvalsFile {
  $schema: string;
  skill_path: string;
  skill_version: string;
  grading_mode: "objective" | "subjective";
  tests: Test[];
}

interface TestRunResult {
  id: string;
  exitCode: number;
  durationMs: number;
  tracePath: string;
  stderrPath: string;
}

const EVAL_SHAPE_VERSION = "eval-shape-v1";
const DEFAULT_TIMEOUT_SECONDS = 600;
const DEFAULT_ALLOWED_TOOLS = [
  "Read",
  "Write",
  "Edit",
  "Bash",
  "Task",
  "Glob",
  "Grep",
];

function fail(msg: string): never {
  console.error(`ERROR: ${msg}`);
  process.exit(1);
}

async function readEvalsFile(skillPath: string): Promise<EvalsFile> {
  const evalsPath = join(skillPath, "evals", "evals.json");
  if (!existsSync(evalsPath)) {
    fail(`evals.json not found at ${evalsPath}`);
  }
  let raw: string;
  try {
    raw = await Bun.file(evalsPath).text();
  } catch (e) {
    fail(`failed to read evals.json: ${(e as Error).message}`);
  }
  let data: EvalsFile;
  try {
    data = JSON.parse(raw) as EvalsFile;
  } catch (e) {
    fail(`evals.json is not valid JSON: ${(e as Error).message}`);
  }
  if (!data.$schema?.includes(EVAL_SHAPE_VERSION)) {
    fail(
      `evals.json schema mismatch — expected ${EVAL_SHAPE_VERSION}, got "${data.$schema}". ` +
        `See ../references/eval-shape.md (relative to this script) for the current schema.`,
    );
  }
  if (data.grading_mode !== "objective" && data.grading_mode !== "subjective") {
    fail(
      `grading_mode must be "objective" or "subjective", got "${data.grading_mode}"`,
    );
  }
  if (!Array.isArray(data.tests) || data.tests.length === 0) {
    fail(`evals.json has no tests`);
  }
  return data;
}

function nowTimestamp(): string {
  return new Date().toISOString().replace(/[:.]/g, "-");
}

// SEC-002: Tools that allow arbitrary code/process execution. Eval data is
// authored by humans who may not be the same human running `just eval-skill`,
// so a malicious evals.json could otherwise instruct the model to shell out.
// Permitted only when BULWARK_ALLOW_UNSAFE_TOOLS=1.
const UNSAFE_TOOLS = new Set(["Bash", "Task"]);

function validateAllowedTools(testId: string, tools: string[]): string[] {
  const allowUnsafe = process.env.BULWARK_ALLOW_UNSAFE_TOOLS === "1";
  const requested = new Set(tools);
  const blocked = [...requested].filter((t) => UNSAFE_TOOLS.has(t));
  if (blocked.length === 0 || allowUnsafe) {
    if (blocked.length > 0 && allowUnsafe) {
      console.warn(
        `  [${testId}] WARN: BULWARK_ALLOW_UNSAFE_TOOLS=1 — granting ${blocked.join(",")}`,
      );
    }
    return tools;
  }
  fail(
    `[${testId}] evals.json requests unsafe tool(s): ${blocked.join(", ")}. ` +
      `These can grant arbitrary code execution to the evaluated skill. ` +
      `Re-run with BULWARK_ALLOW_UNSAFE_TOOLS=1 if you trust the eval author.`,
  );
}

function buildClaudeArgs(test: Test, pluginDir: string | null): string[] {
  const requested = test.allowed_tools ?? DEFAULT_ALLOWED_TOOLS;
  const allowedTools = validateAllowedTools(test.id, requested);
  const args = [
    "-p",
    test.prompt,
    "--output-format",
    "stream-json",
    "--verbose",
    "--allowedTools",
    allowedTools.join(","),
  ];
  if (pluginDir) {
    args.push("--plugin-dir", pluginDir);
  }
  const model = process.env.BULWARK_EVAL_MODEL;
  if (model) {
    args.push("--model", model);
  }
  return args;
}

// L-003: extracted from runTest — pipe a Bun ReadableStream to a Bun FileSink.
async function pipeStreamToWriter(
  stream: ReadableStream<Uint8Array>,
  writer: ReturnType<ReturnType<typeof Bun.file>["writer"]>,
): Promise<void> {
  const reader = stream.getReader();
  let result = await reader.read();
  while (!result.done) {
    writer.write(result.value);
    result = await reader.read();
  }
  await writer.end();
}

async function runTest(
  test: Test,
  runDir: string,
  pluginDir: string | null,
): Promise<TestRunResult> {
  const tracePath = join(runDir, `${test.id}.jsonl`);
  const stderrPath = join(runDir, `${test.id}.stderr.log`);
  const args = buildClaudeArgs(test, pluginDir);
  const timeoutMs = (test.timeout_seconds ?? DEFAULT_TIMEOUT_SECONDS) * 1000;

  const traceWriter = Bun.file(tracePath).writer();
  const stderrWriter = Bun.file(stderrPath).writer();

  const started = Date.now();
  const proc = Bun.spawn(["claude", ...args], {
    stdout: "pipe",
    stderr: "pipe",
    env: { ...process.env },
  });

  const stdoutPromise = pipeStreamToWriter(proc.stdout, traceWriter);
  const stderrPromise = pipeStreamToWriter(proc.stderr, stderrWriter);

  const timeoutHandle = setTimeout(() => {
    proc.kill("SIGTERM");
  }, timeoutMs);

  let exitCode: number;
  try {
    exitCode = await proc.exited;
  } finally {
    clearTimeout(timeoutHandle);
  }
  await Promise.all([stdoutPromise, stderrPromise]);

  const durationMs = Date.now() - started;
  return { id: test.id, exitCode, durationMs, tracePath, stderrPath };
}

function resolvePluginDir(): string | null {
  const fromEnv = process.env.BULWARK_PLUGIN_DIR;
  if (fromEnv) {
    if (!existsSync(fromEnv)) {
      fail(`BULWARK_PLUGIN_DIR points to non-existent path: ${fromEnv}`);
    }
    return resolve(fromEnv);
  }
  return null;
}

function ensureDir(p: string): void {
  if (!existsSync(p)) {
    mkdirSync(p, { recursive: true });
  } else if (!statSync(p).isDirectory()) {
    fail(`expected directory, got file: ${p}`);
  }
}

async function main(): Promise<void> {
  const arg = process.argv[2];
  if (!arg) {
    fail(
      "Usage: just eval-skill <path-to-skill>  (or: bun run <this-script> <path-to-skill>)",
    );
  }
  const skillPath = resolve(arg);
  if (!existsSync(skillPath)) {
    fail(`skill path not found: ${skillPath}`);
  }
  if (!existsSync(join(skillPath, "SKILL.md"))) {
    fail(`not a skill directory (no SKILL.md): ${skillPath}`);
  }

  const evals = await readEvalsFile(skillPath);
  const ts = nowTimestamp();
  const runDir = join(skillPath, "evals", "runs", ts);
  ensureDir(runDir);

  const pluginDir = resolvePluginDir();

  console.log(
    `Running ${evals.tests.length} test(s) for ${evals.skill_path} v${evals.skill_version}`,
  );
  console.log(`  grading_mode: ${evals.grading_mode}`);
  console.log(`  run_dir: ${runDir}`);
  console.log(
    `  plugin_dir: ${pluginDir ?? "(installed plugin discovery)"}`,
  );

  const results: TestRunResult[] = [];
  for (const test of evals.tests) {
    process.stdout.write(`\n[${test.id}] ${test.description ?? ""}\n`);
    const result = await runTest(test, runDir, pluginDir);
    results.push(result);
    console.log(
      `  exit=${result.exitCode} duration=${(result.durationMs / 1000).toFixed(1)}s`,
    );
  }

  const manifest = {
    skill_path: evals.skill_path,
    skill_version: evals.skill_version,
    run_timestamp: ts,
    grading_mode: evals.grading_mode,
    plugin_dir: pluginDir,
    tests: results.map((r) => ({
      id: r.id,
      exit_code: r.exitCode,
      duration_ms: r.durationMs,
      trace: r.tracePath,
      stderr: r.stderrPath,
    })),
  };
  await Bun.write(
    join(runDir, "run-manifest.json"),
    JSON.stringify(manifest, null, 2),
  );

  console.log(`\nAll tests complete.`);
  console.log(`  Trace dir: ${runDir}`);
  console.log(`  Grade with: just eval-grade ${skillPath} ${ts}`);
}

void main().catch((e: Error) => {
  console.error(`run-loop failed: ${e.message}`);
  if (e.stack) console.error(e.stack);
  process.exit(1);
});
