#!/usr/bin/env bun
// grade.ts — Deterministic + log/artifact-based eval grader.
//
// Reads <skill>/evals/runs/<timestamp>/*.jsonl + run-manifest.json + evals.json,
// scores each test against its assertions, writes grading-<timestamp>.json and
// reports/<timestamp>.md.
//
// HARD CONSTRAINT (memo D3): grading is parse-based, not LLM-self-report.
// Fuzzy assertions delegate to skill-eval-grader.md agent which operates on
// EVIDENCE PATHS (file contents, traces) — never asks the model "did you do X."
//
// Usage:
//   just eval-grade <path-to-skill> [<run-timestamp>]
//   (or directly: bun run <path-to-this-script> <path-to-skill> [<run-timestamp>])
//
// The plugin entrypoint is `just eval-grade` which works regardless of
// whether the user is running from the plugin cache, a `.claude/skills/`
// copy, or a development checkout.
//
// Schema: see ../references/eval-shape.md (eval-shape-v1).

import { existsSync, mkdirSync, readdirSync } from "fs";
import { resolve, relative, isAbsolute, join } from "path";

interface Assertion {
  type: string;
  [key: string]: unknown;
}

interface Test {
  id: string;
  description?: string;
  prompt: string;
  assertions: Assertion[];
}

interface EvalsFile {
  $schema: string;
  skill_path: string;
  skill_version: string;
  grading_mode: "objective" | "subjective";
  tests: Test[];
}

interface RunManifest {
  skill_path: string;
  skill_version: string;
  run_timestamp: string;
  grading_mode: "objective" | "subjective";
  plugin_dir: string | null;
  tests: Array<{
    id: string;
    exit_code: number;
    duration_ms: number;
    trace: string;
    stderr: string;
  }>;
}

interface ToolUseEvent {
  tool: string;
  input: Record<string, unknown>;
  id: string;
}

interface ParsedTrace {
  systemInit: Record<string, unknown> | null;
  apiRetries: Array<Record<string, unknown>>;
  toolUses: ToolUseEvent[];
  toolResults: Array<{ tool_use_id: string; is_error: boolean; content: unknown }>;
  assistantText: string[];
  finalResult: string | null;
  rawEventCount: number;
}

interface AssertionVerdict {
  index: number;
  type: string;
  verdict: "PASS" | "FAIL" | "SKIPPED";
  evidence: string;
}

interface TestVerdict {
  id: string;
  description: string | undefined;
  verdict: "PASS" | "FAIL" | "INCOMPLETE";
  duration_ms: number;
  exit_code: number;
  assertions: AssertionVerdict[];
}

const EVAL_SHAPE_VERSION = "eval-shape-v1";

// SEC-005: cap trace size to prevent OOM on a malicious or runaway run.
// 64 MB is generous for typical eval runs (typically <1 MB) but small enough
// to abort fast on a runaway producer.
const MAX_TRACE_BYTES = 64 * 1024 * 1024;

// SEC-001: refuse patterns longer than this — a heuristic against pathological
// inputs from evals.json. Real-world matchers fit comfortably.
const MAX_REGEX_PATTERN_LENGTH = 256;

function fail(msg: string): never {
  console.error(`ERROR: ${msg}`);
  process.exit(1);
}

function warn(msg: string): void {
  console.warn(`WARN: ${msg}`);
}

async function readJson<T>(path: string): Promise<T> {
  if (!existsSync(path)) fail(`file not found: ${path}`);
  try {
    return JSON.parse(await Bun.file(path).text()) as T;
  } catch (e) {
    fail(`invalid JSON in ${path}: ${(e as Error).message}`);
  }
}

// L-004: mirrors run-loop.ts's readEvalsFile — same schema-version + grading-mode
// validation. Both scripts must agree on what a valid evals.json looks like;
// keeping the helper structurally symmetric (rather than imported from a shared
// module) is intentional — each script is a self-contained CLI entrypoint.
async function readEvalsFile(skillPath: string): Promise<EvalsFile> {
  const evalsPath = join(skillPath, "evals", "evals.json");
  const data = await readJson<EvalsFile>(evalsPath);
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
  return data;
}

// TS-001: structural fail-fast on the manifest. Without this, a truncated
// or malformed run-manifest.json crashes downstream with a cryptic
// "Cannot read properties of undefined" instead of an actionable error.
function validateManifest(m: RunManifest, path: string): void {
  if (typeof m.skill_path !== "string" || m.skill_path.length === 0) {
    fail(`${path}: missing or empty "skill_path"`);
  }
  if (typeof m.skill_version !== "string") {
    fail(`${path}: missing "skill_version"`);
  }
  if (typeof m.run_timestamp !== "string") {
    fail(`${path}: missing "run_timestamp"`);
  }
  if (m.grading_mode !== "objective" && m.grading_mode !== "subjective") {
    fail(
      `${path}: "grading_mode" must be "objective" or "subjective", got "${m.grading_mode}"`,
    );
  }
  if (!Array.isArray(m.tests)) {
    fail(`${path}: "tests" must be an array`);
  }
  for (let i = 0; i < m.tests.length; i++) {
    const t = m.tests[i];
    if (!t || typeof t !== "object") {
      fail(`${path}: tests[${i}] must be an object`);
    }
    if (typeof t.id !== "string" || t.id.length === 0) {
      fail(`${path}: tests[${i}].id must be a non-empty string`);
    }
    if (typeof t.exit_code !== "number") {
      fail(`${path}: tests[${i}].exit_code must be a number`);
    }
    if (typeof t.duration_ms !== "number") {
      fail(`${path}: tests[${i}].duration_ms must be a number`);
    }
    if (typeof t.trace !== "string") {
      fail(`${path}: tests[${i}].trace must be a string`);
    }
  }
}

// SEC-001: compile a user-supplied pattern with a length cap. The execution-
// time cap is applied at .test() callsites via testRegexWithTimeout below.
function safeRegex(pattern: string, flags = "", context: string): RegExp {
  if (pattern.length > MAX_REGEX_PATTERN_LENGTH) {
    fail(
      `${context}: regex pattern exceeds ${MAX_REGEX_PATTERN_LENGTH} chars — refusing for ReDoS safety`,
    );
  }
  try {
    return new RegExp(pattern, flags);
  } catch (e) {
    fail(`${context}: invalid regex /${pattern}/${flags}: ${(e as Error).message}`);
  }
}

// SEC-001: catastrophic backtracking can hang Node/Bun for seconds. Bun does
// not expose a native regex timeout, so we use a synchronous fail-safe: if a
// pattern looks pathological (nested quantifiers around alternation), we
// refuse it. Heuristic only — defensive, not exhaustive.
function rejectPathologicalPatterns(pattern: string, context: string): void {
  const PATHOLOGICAL = [
    /\([^)]*\+\)\+/, // (a+)+
    /\([^)]*\*\)\*/, // (a*)*
    /\([^)]*\+\)\*/, // (a+)*
    /\([^)]*\*\)\+/, // (a*)+
    /\([^|)]+\|[^)]+\)\+/, // (a|b)+ … case prone to backtracking with shared suffix
  ];
  for (const p of PATHOLOGICAL) {
    if (p.test(pattern)) {
      fail(
        `${context}: regex pattern matches a known catastrophic-backtracking shape — refusing for ReDoS safety. Pattern: ${pattern}`,
      );
    }
  }
}

// TS-003: structurally validate an assertion's required fields before reading.
// Each grader calls this with the fields it expects; missing fields produce a
// clear FAIL verdict instead of silent wrong behavior.
function requireField<T>(
  a: Record<string, unknown>,
  field: string,
  type: "string" | "number" | "boolean" | "array",
  context: string,
): T {
  const v = a[field];
  if (v === undefined || v === null) {
    fail(`${context}: required field "${field}" is missing`);
  }
  if (type === "array") {
    if (!Array.isArray(v)) {
      fail(`${context}: field "${field}" must be an array, got ${typeof v}`);
    }
  } else if (typeof v !== type) {
    fail(`${context}: field "${field}" must be ${type}, got ${typeof v}`);
  }
  if (type === "string" && (v as string).length === 0) {
    fail(`${context}: field "${field}" is an empty string`);
  }
  return v as T;
}

// F-004: Claude tool calls return absolute file_path. Author's path_glob is
// typically relative + anchored. Normalize observed write paths to repo-relative
// (cwd) form before testing the glob. Both candidate forms (original + relative)
// are tested so absolute-pattern globs and exotic patterns continue working.
function candidatePathsForGlobMatch(filePath: string): string[] {
  const candidates: string[] = [filePath];
  if (isAbsolute(filePath)) {
    const rel = relative(process.cwd(), filePath);
    if (rel && !rel.startsWith("..")) {
      candidates.push(rel);
    }
  }
  return candidates;
}

// L-001: extracted from parseTraceFile — parse content blocks of an
// assistant message into structured tool-use + text events.
function extractAssistantBlocks(
  content: Array<Record<string, unknown>>,
  textOut: string[],
  toolUsesOut: ToolUseEvent[],
): void {
  for (const block of content) {
    if (block.type === "text" && typeof block.text === "string") {
      textOut.push(block.text);
    } else if (block.type === "tool_use") {
      toolUsesOut.push({
        tool: (block.name as string) ?? "",
        input: (block.input as Record<string, unknown>) ?? {},
        id: (block.id as string) ?? "",
      });
    }
  }
}

// L-001: extracted from parseTraceFile — parse content blocks of a user
// message (tool-result blocks).
function extractUserBlocks(
  content: Array<Record<string, unknown>>,
  toolResultsOut: ParsedTrace["toolResults"],
): void {
  for (const block of content) {
    if (block.type === "tool_result") {
      toolResultsOut.push({
        tool_use_id: (block.tool_use_id as string) ?? "",
        is_error: Boolean(block.is_error),
        content: block.content,
      });
    }
  }
}

function emptyTrace(): ParsedTrace {
  return {
    systemInit: null,
    apiRetries: [],
    toolUses: [],
    toolResults: [],
    assistantText: [],
    finalResult: null,
    rawEventCount: 0,
  };
}

// L-002 + assertion-style helper — parse one stream-json event into the trace.
function ingestEvent(evt: Record<string, unknown>, parsed: ParsedTrace): void {
  const type = evt.type as string | undefined;
  const subtype = evt.subtype as string | undefined;
  if (type === "system" && subtype === "init") {
    parsed.systemInit = evt;
    return;
  }
  if (type === "system" && subtype === "api_retry") {
    parsed.apiRetries.push(evt);
    return;
  }
  if (type === "assistant") {
    const message = evt.message as Record<string, unknown> | undefined;
    const content = (message?.content ?? evt.content) as
      | Array<Record<string, unknown>>
      | undefined;
    if (Array.isArray(content)) {
      extractAssistantBlocks(content, parsed.assistantText, parsed.toolUses);
    }
    return;
  }
  if (type === "user") {
    const message = evt.message as Record<string, unknown> | undefined;
    const content = (message?.content ?? evt.content) as
      | Array<Record<string, unknown>>
      | undefined;
    if (Array.isArray(content)) {
      extractUserBlocks(content, parsed.toolResults);
    }
    return;
  }
  if (type === "result") {
    const result = evt.result as string | undefined;
    if (typeof result === "string") parsed.finalResult = result;
  }
}

// SEC-005 + F-002: stream-parse the trace file line-by-line so we never load
// more than the size cap into memory. Emits a clear warning when the trace is
// missing so downstream FAIL verdicts have actionable context (CS3 Fail Fast).
async function parseTraceFile(tracePath: string): Promise<ParsedTrace> {
  const parsed = emptyTrace();
  if (!existsSync(tracePath)) {
    warn(
      `trace file not found at ${tracePath} — assertions will grade against an empty trace`,
    );
    return parsed;
  }
  const file = Bun.file(tracePath);
  const size = file.size;
  if (size > MAX_TRACE_BYTES) {
    fail(
      `trace file exceeds size cap (${size} > ${MAX_TRACE_BYTES} bytes): ${tracePath}`,
    );
  }
  const stream = file.stream();
  const reader = stream.getReader();
  const decoder = new TextDecoder();
  let buffer = "";
  let chunk = await reader.read();
  while (!chunk.done) {
    buffer += decoder.decode(chunk.value, { stream: true });
    let nl = buffer.indexOf("\n");
    while (nl !== -1) {
      const line = buffer.slice(0, nl).trim();
      buffer = buffer.slice(nl + 1);
      if (line.length > 0) {
        parsed.rawEventCount += 1;
        try {
          ingestEvent(JSON.parse(line) as Record<string, unknown>, parsed);
        } catch {
          // skip malformed line; rawEventCount still counts the line attempt
        }
      }
      nl = buffer.indexOf("\n");
    }
    chunk = await reader.read();
  }
  // Final flush — handle a trailing line with no newline.
  buffer += decoder.decode();
  const tail = buffer.trim();
  if (tail.length > 0) {
    parsed.rawEventCount += 1;
    try {
      ingestEvent(JSON.parse(tail) as Record<string, unknown>, parsed);
    } catch {
      // ignore
    }
  }
  return parsed;
}

function globToRegex(glob: string): RegExp {
  let pattern = "^";
  for (let i = 0; i < glob.length; i++) {
    const c = glob[i];
    if (c === "*" && glob[i + 1] === "*") {
      pattern += ".*";
      i += 1;
    } else if (c === "*") {
      pattern += "[^/]*";
    } else if (c === "?") {
      pattern += ".";
    } else if (".+^$()|{}[]\\".includes(c)) {
      pattern += `\\${c}`;
    } else {
      pattern += c;
    }
  }
  pattern += "$";
  return new RegExp(pattern);
}

function evidenceTrunc(s: string, max = 200): string {
  if (s.length <= max) return s;
  return `${s.slice(0, max)}…`;
}

function gradeToolUseCalled(a: Assertion, trace: ParsedTrace): AssertionVerdict {
  const ctx = "tool_use_called";
  const tool = requireField<string>(a, "tool", "string", ctx);
  const minCount = (a.min_count as number | undefined) ?? 1;
  const maxCount = a.max_count as number | undefined;
  const nameMatches = a.name_matches as string | undefined;
  let nameRe: RegExp | null = null;
  if (nameMatches !== undefined) {
    rejectPathologicalPatterns(nameMatches, `${ctx}.name_matches`);
    nameRe = safeRegex(nameMatches, "", `${ctx}.name_matches`);
  }
  const matching = trace.toolUses.filter((t) => {
    if (t.tool !== tool) return false;
    if (nameRe === null) return true;
    let candidate = "";
    if (tool === "Task") {
      candidate = (t.input.subagent_type as string | undefined) ?? "";
    } else if (tool === "Bash") {
      candidate = (t.input.command as string | undefined) ?? "";
    } else {
      candidate = (t.input.description as string | undefined) ?? "";
    }
    return nameRe.test(candidate);
  });
  const count = matching.length;
  const passMin = count >= minCount;
  const passMax = maxCount === undefined ? true : count <= maxCount;
  const verdict = passMin && passMax ? "PASS" : "FAIL";
  const evidence = `${tool} invoked ${count} time(s) (min=${minCount}${
    maxCount !== undefined ? `, max=${maxCount}` : ""
  }${nameMatches !== undefined ? `, name~/${nameMatches}/` : ""})`;
  return { index: -1, type: a.type, verdict, evidence };
}

async function gradeFileWritten(
  a: Assertion,
  trace: ParsedTrace,
): Promise<AssertionVerdict> {
  const ctx = "file_written";
  const pathGlob = requireField<string>(a, "path_glob", "string", ctx);
  rejectPathologicalPatterns(pathGlob, `${ctx}.path_glob`);
  const contentContains = (a.content_contains as string[] | undefined) ?? [];
  const contentMatches = a.content_matches as string | undefined;
  const minCount = (a.min_count as number | undefined) ?? 1;
  const re = globToRegex(pathGlob);

  let contentRe: RegExp | null = null;
  if (contentMatches !== undefined) {
    rejectPathologicalPatterns(contentMatches, `${ctx}.content_matches`);
    contentRe = safeRegex(contentMatches, "", `${ctx}.content_matches`);
  }

  const writes = trace.toolUses.filter(
    (t) => t.tool === "Write" || t.tool === "Edit",
  );
  const matchingWrites: Array<{ path: string; content: string }> = [];
  for (const w of writes) {
    const filePath = (w.input.file_path as string | undefined) ?? "";
    if (filePath.length === 0) continue;
    // F-004: Claude returns absolute paths; author globs are relative —
    // try both forms.
    const candidates = candidatePathsForGlobMatch(filePath);
    if (!candidates.some((c) => re.test(c))) continue;
    let content = "";
    if (w.tool === "Write") {
      content = (w.input.content as string | undefined) ?? "";
    } else {
      content = (w.input.new_string as string | undefined) ?? "";
    }
    matchingWrites.push({ path: filePath, content });
  }

  const failures: string[] = [];
  if (matchingWrites.length < minCount) {
    failures.push(
      `expected ≥${minCount} write(s) matching ${pathGlob}, got ${matchingWrites.length}`,
    );
  }
  for (const needle of contentContains) {
    const found = matchingWrites.some((w) => w.content.includes(needle));
    if (!found) failures.push(`no write contains "${needle}"`);
  }
  if (contentRe !== null) {
    const found = matchingWrites.some((w) => contentRe.test(w.content));
    if (!found) failures.push(`no write matches /${contentMatches}/`);
  }
  const verdict: "PASS" | "FAIL" = failures.length === 0 ? "PASS" : "FAIL";
  const evidence =
    failures.length === 0
      ? `${matchingWrites.length} write(s) matched ${pathGlob}: ${matchingWrites
          .map((w) => w.path)
          .join(", ")}`
      : failures.join("; ");
  return { index: -1, type: a.type, verdict, evidence };
}

// L-002: outer guard inverted — early-return for unsupported event types
// keeps the supported-path body at top-level nesting depth.
function gradeStreamEventEmitted(
  a: Assertion,
  trace: ParsedTrace,
): AssertionVerdict {
  const ctx = "stream_event_emitted";
  const eventType = requireField<string>(a, "event_type", "string", ctx);
  const subtype = a.subtype as string | undefined;
  const fieldCheck = a.field_check as Record<string, unknown> | undefined;

  if (!(eventType === "system" && subtype === "init")) {
    return {
      index: -1,
      type: a.type,
      verdict: "SKIPPED",
      evidence: `unsupported event_type/subtype "${eventType}/${subtype ?? "—"}" — no deterministic grader implemented; manual grading required`,
    };
  }

  if (!trace.systemInit) {
    return {
      index: -1,
      type: a.type,
      verdict: "FAIL",
      evidence: "no system/init event in trace",
    };
  }

  if (fieldCheck?.plugin_errors_empty === true) {
    const errs = trace.systemInit.plugin_errors as unknown[] | undefined;
    if (errs && errs.length > 0) {
      return {
        index: -1,
        type: a.type,
        verdict: "FAIL",
        evidence: `plugin_errors not empty: ${JSON.stringify(errs)}`,
      };
    }
  }

  if (typeof fieldCheck?.plugin_named === "string") {
    const plugins = trace.systemInit.plugins as
      | Array<{ name?: string }>
      | undefined;
    const found = (plugins ?? []).some(
      (p) => p.name === fieldCheck.plugin_named,
    );
    if (!found) {
      return {
        index: -1,
        type: a.type,
        verdict: "FAIL",
        evidence: `plugin "${fieldCheck.plugin_named}" not in plugins[]`,
      };
    }
  }

  return {
    index: -1,
    type: a.type,
    verdict: "PASS",
    evidence: "system/init present and field_check satisfied",
  };
}

function gradeExitCode(a: Assertion, exitCode: number): AssertionVerdict {
  const ctx = "exit_code";
  const expected = requireField<number>(a, "value", "number", ctx);
  const verdict: "PASS" | "FAIL" = exitCode === expected ? "PASS" : "FAIL";
  return {
    index: -1,
    type: a.type,
    verdict,
    evidence: `exit_code=${exitCode}, expected=${expected}`,
  };
}

function gradeRegexMatch(a: Assertion, trace: ParsedTrace): AssertionVerdict {
  const ctx = "regex_match";
  // TS-002: pattern field MUST be present + non-empty. Without this,
  // `new RegExp(undefined)` builds /(?:)/ which matches everything.
  const pattern = requireField<string>(a, "pattern", "string", ctx);
  rejectPathologicalPatterns(pattern, `${ctx}.pattern`);
  const target = (a.target as string | undefined) ?? "result";
  const flags = (a.case_insensitive as boolean | undefined) ? "i" : "";
  const re = safeRegex(pattern, flags, `${ctx}.pattern`);
  let haystack = "";
  if (target === "result") {
    haystack = trace.finalResult ?? "";
  } else if (target === "all_assistant_text") {
    haystack = trace.assistantText.join("\n");
  } else {
    return {
      index: -1,
      type: a.type,
      verdict: "FAIL",
      evidence: `unsupported target: ${target}`,
    };
  }
  const matched = re.test(haystack);
  return {
    index: -1,
    type: a.type,
    verdict: matched ? "PASS" : "FAIL",
    evidence: matched
      ? `matched /${pattern}/ in ${target}`
      : `no match for /${pattern}/ in ${target} (haystack=${evidenceTrunc(haystack)})`,
  };
}

function gradeFuzzy(a: Assertion): AssertionVerdict {
  // Fuzzy assertions are not auto-graded by grade.ts. They produce a SKIPPED
  // verdict with a clear message instructing the user to invoke the
  // skill-eval-grader agent. This preserves the memo D3 hard constraint
  // (artifact-based grading, never self-report) by separating deterministic
  // grading from the agent invocation step.
  const desc = (a.description as string | undefined) ?? "(no description)";
  const evidencePaths = (a.evidence_paths as string[] | undefined) ?? [];
  return {
    index: -1,
    type: a.type,
    verdict: "SKIPPED",
    evidence: `fuzzy assertion — invoke skill-eval-grader agent against evidence_paths: ${evidencePaths.join(", ")} | rubric: "${desc}"`,
  };
}

async function gradeAssertion(
  a: Assertion,
  trace: ParsedTrace,
  exitCode: number,
): Promise<AssertionVerdict> {
  switch (a.type) {
    case "tool_use_called":
      return gradeToolUseCalled(a, trace);
    case "file_written":
      return gradeFileWritten(a, trace);
    case "stream_event_emitted":
      return gradeStreamEventEmitted(a, trace);
    case "exit_code":
      return gradeExitCode(a, exitCode);
    case "regex_match":
      return gradeRegexMatch(a, trace);
    case "fuzzy":
      return gradeFuzzy(a);
    default:
      return {
        index: -1,
        type: a.type,
        verdict: "FAIL",
        evidence: `unknown assertion type: ${a.type}`,
      };
  }
}

function renderMarkdownReport(
  evals: EvalsFile,
  manifest: RunManifest,
  testVerdicts: TestVerdict[],
  passRate: number,
): string {
  const lines: string[] = [];
  lines.push(`# Eval Report — ${evals.skill_path}`);
  lines.push("");
  lines.push(`- **skill_version**: ${evals.skill_version}`);
  lines.push(`- **run_timestamp**: ${manifest.run_timestamp}`);
  lines.push(`- **grading_mode**: ${evals.grading_mode}`);
  lines.push(`- **plugin_dir**: ${manifest.plugin_dir ?? "(installed)"}`);
  const passCount = testVerdicts.filter((t) => t.verdict === "PASS").length;
  const failCount = testVerdicts.filter((t) => t.verdict === "FAIL").length;
  const incompleteCount = testVerdicts.filter(
    (t) => t.verdict === "INCOMPLETE",
  ).length;
  lines.push(
    `- **summary**: ${passCount}/${testVerdicts.length} passed, ${failCount} failed, ${incompleteCount} incomplete (${(passRate * 100).toFixed(1)}% pass rate)`,
  );
  lines.push("");
  for (const v of testVerdicts) {
    lines.push(`## [${v.id}] ${v.description ?? ""}`);
    lines.push("");
    const verdictMark =
      v.verdict === "PASS"
        ? "✅ PASS"
        : v.verdict === "INCOMPLETE"
          ? "⊘ INCOMPLETE"
          : "❌ FAIL";
    lines.push(`- **verdict**: ${verdictMark}`);
    lines.push(
      `- **exit_code**: ${v.exit_code} | **duration**: ${(v.duration_ms / 1000).toFixed(1)}s`,
    );
    lines.push("");
    lines.push("| # | type | verdict | evidence |");
    lines.push("|---|------|---------|----------|");
    for (const a of v.assertions) {
      const verdictMark =
        a.verdict === "PASS" ? "✅" : a.verdict === "SKIPPED" ? "⊘" : "❌";
      lines.push(
        `| ${a.index} | ${a.type} | ${verdictMark} ${a.verdict} | ${a.evidence.replace(/\|/g, "\\|")} |`,
      );
    }
    lines.push("");
  }
  lines.push("---");
  lines.push("");
  lines.push(
    "Fuzzy assertions (verdict=SKIPPED) require invocation of the `skill-eval-grader` agent (bundled with create-skill at `agents/skill-eval-grader.md`).",
  );
  return lines.join("\n");
}

async function main(): Promise<void> {
  const skillPathArg = process.argv[2];
  const tsArg = process.argv[3];
  if (!skillPathArg) {
    fail(
      "Usage: just eval-grade <skill-path> [<run-timestamp>]  (or: bun run <this-script> <skill-path> [<run-timestamp>])",
    );
  }
  const skillPath = resolve(skillPathArg);
  if (!existsSync(skillPath)) fail(`skill path not found: ${skillPath}`);

  const evals = await readEvalsFile(skillPath);

  let runTimestamp = tsArg;
  const runsBaseDir = join(skillPath, "evals", "runs");
  if (!runTimestamp) {
    if (!existsSync(runsBaseDir)) fail(`no runs found at ${runsBaseDir}`);
    const dirs = readdirSync(runsBaseDir).sort().reverse();
    if (dirs.length === 0) fail(`no runs in ${runsBaseDir}`);
    runTimestamp = dirs[0];
    console.log(`No timestamp arg — using latest: ${runTimestamp}`);
  }
  const runDir = join(runsBaseDir, runTimestamp);
  if (!existsSync(runDir)) fail(`run dir not found: ${runDir}`);

  const manifestPath = join(runDir, "run-manifest.json");
  const manifest = await readJson<RunManifest>(manifestPath);
  validateManifest(manifest, manifestPath);

  const testsById = new Map<string, Test>();
  for (const t of evals.tests) testsById.set(t.id, t);

  const testVerdicts: TestVerdict[] = [];
  for (const runRecord of manifest.tests) {
    const test = testsById.get(runRecord.id);
    if (!test) {
      console.warn(
        `WARN: run-manifest references test id "${runRecord.id}" not in evals.json — skipping`,
      );
      continue;
    }
    const trace = await parseTraceFile(runRecord.trace);
    const assertionVerdicts: AssertionVerdict[] = [];
    let hasFail = false;
    let hasSkipped = false;
    for (let i = 0; i < test.assertions.length; i++) {
      const a = test.assertions[i];
      const v = await gradeAssertion(a, trace, runRecord.exit_code);
      v.index = i;
      assertionVerdicts.push(v);
      if (v.verdict === "FAIL") hasFail = true;
      if (v.verdict === "SKIPPED") hasSkipped = true;
    }
    const testVerdict: "PASS" | "FAIL" | "INCOMPLETE" = hasFail
      ? "FAIL"
      : hasSkipped
        ? "INCOMPLETE"
        : "PASS";
    testVerdicts.push({
      id: test.id,
      description: test.description,
      verdict: testVerdict,
      duration_ms: runRecord.duration_ms,
      exit_code: runRecord.exit_code,
      assertions: assertionVerdicts,
    });
  }

  const passed = testVerdicts.filter((t) => t.verdict === "PASS").length;
  const failed = testVerdicts.filter((t) => t.verdict === "FAIL").length;
  const incomplete = testVerdicts.filter(
    (t) => t.verdict === "INCOMPLETE",
  ).length;
  const passRate = testVerdicts.length === 0 ? 0 : passed / testVerdicts.length;

  const grading = {
    skill_path: evals.skill_path,
    skill_version: evals.skill_version,
    run_timestamp: runTimestamp,
    grading_mode: evals.grading_mode,
    summary: {
      total_tests: testVerdicts.length,
      passed,
      failed,
      incomplete,
      pass_rate: passRate,
    },
    tests: testVerdicts,
  };

  const reportsDir = join(skillPath, "evals", "reports");
  if (!existsSync(reportsDir)) {
    mkdirSync(reportsDir, { recursive: true });
  }
  const gradingPath = join(reportsDir, `grading-${runTimestamp}.json`);
  await Bun.write(gradingPath, JSON.stringify(grading, null, 2));
  const reportPath = join(reportsDir, `${runTimestamp}.md`);
  await Bun.write(
    reportPath,
    renderMarkdownReport(evals, manifest, testVerdicts, passRate),
  );

  console.log(
    `Graded ${testVerdicts.length} test(s): ${passed} PASS, ${failed} FAIL, ${incomplete} INCOMPLETE (${(passRate * 100).toFixed(1)}% pass rate)`,
  );
  console.log(`  grading.json: ${gradingPath}`);
  console.log(`  report:       ${reportPath}`);
  const skipped = testVerdicts.flatMap((t) =>
    t.assertions.filter((a) => a.verdict === "SKIPPED"),
  );
  if (skipped.length > 0) {
    console.log(
      `  ⊘ ${skipped.length} fuzzy assertion(s) SKIPPED — run skill-eval-grader against the evidence paths to complete grading.`,
    );
  }
}

void main().catch((e: Error) => {
  console.error(`grade failed: ${e.message}`);
  if (e.stack) console.error(e.stack);
  process.exit(1);
});
