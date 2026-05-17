#!/usr/bin/env bun
// check-description.ts — Description quality gate for SKILL.md frontmatter.
//
// Catches Issue #9817 / #4700 / #881 class authoring defects:
//   1. Multi-line description (silently breaks skill discovery)
//   2. Description > 250 chars (silently truncates in /menu)
//   3. Missing trigger phrase ("Use when ...") — warning only
//   4. Prettier-wrapped artifacts (block scalars, continuation lines)
//   5. Empty description (passes legacy null guard but breaks discovery — TS-T022-001)
//   6. Missing YAML frontmatter or absent description: field (no scaffold to gate on)
//
// Exit codes:
//   0 — PASS (with optional warnings on soft issues)
//   1 — FAIL (any of: multi-line, over-length, empty, missing frontmatter, missing field)
//   2 — Usage error (missing/invalid path) OR I/O error (permission denied, file too large)
//
// Usage:
//   just check-description <path-to-SKILL.md>
//   bun "${CLAUDE_PLUGIN_ROOT}/skills/create-skill/scripts/check-description.ts" <path>

import { existsSync, readFileSync, statSync } from "fs";
import { resolve } from "path";

const MAX_DESCRIPTION_CHARS = 250;
const MAX_FILE_BYTES = 512 * 1024; // 512 KB — generous for any SKILL.md (SEC-T022 size gate per T-026 SEC-005 pattern)
const TRIGGER_PHRASES = ["use when", "use this skill when", "use this when"];

type Severity = "block" | "warn" | "info";

interface Finding {
  severity: Severity;
  rule: string;
  message: string;
  remediation: string;
}

function usage(reason: string): never {
  console.error(`check-description: ${reason}`);
  console.error("");
  console.error("Usage:");
  console.error("  just check-description <path-to-SKILL.md>");
  console.error("  bun check-description.ts <path-to-SKILL.md>");
  process.exit(2);
}

function ioError(reason: string): never {
  console.error(`check-description: ${reason}`);
  process.exit(2);
}

// Bounded read — guards against OOM on /dev/random, multi-GB files, or pathological inputs.
// Surfaces actionable errors instead of raw Node stack traces (CS3 fail-fast).
function safeReadFile(path: string): string {
  let stat;
  try {
    stat = statSync(path);
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    ioError(`could not stat file at ${path}: ${msg}`);
  }
  if (!stat.isFile()) {
    ioError(`path is not a regular file: ${path}`);
  }
  if (stat.size > MAX_FILE_BYTES) {
    ioError(
      `file is ${stat.size} bytes, exceeds ${MAX_FILE_BYTES}-byte cap. SKILL.md should be far smaller.`,
    );
  }
  try {
    return readFileSync(path, "utf8").replace(/\r\n/g, "\n");
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    ioError(`could not read file at ${path}: ${msg}`);
  }
}

// Line-based frontmatter parser. Replaces the prior regex (`/^---\n([\s\S]*?)\n---\n/m`)
// which had two security issues: (1) `/m` flag matched mid-document `---` (HR/table separator),
// (2) lazy `[\s\S]*?` quantifier was a ReDoS vector. Line-based scan is O(n) and unambiguous.
function extractFrontmatter(content: string): string | null {
  if (!content.startsWith("---\n")) return null;
  const lines = content.split("\n");
  for (let i = 1; i < lines.length; i++) {
    if (lines[i] === "---") {
      return lines.slice(1, i).join("\n");
    }
  }
  return null;
}

interface DescriptionShape {
  raw: string | null;
  startLine: number;
  multiLineIndicator: "|" | ">" | null;
  continuationLines: string[];
}

function extractDescription(frontmatter: string): DescriptionShape {
  const lines = frontmatter.split("\n");
  for (let i = 0; i < lines.length; i++) {
    const m = /^description:\s*(.*)$/.exec(lines[i]);
    if (!m) continue;

    const inlineValue = m[1];
    const blockMatch = /^([|>])([+-]?[0-9]*)\s*$/.exec(inlineValue);
    if (blockMatch) {
      const indicator = blockMatch[1] as "|" | ">";
      const spanned: string[] = [];
      for (let j = i + 1; j < lines.length; j++) {
        const lj = lines[j];
        if (lj.length > 0 && !lj.startsWith(" ") && !lj.startsWith("\t")) break;
        spanned.push(lj.replace(/^\s+/, ""));
      }
      return {
        raw: spanned.join("\n"),
        startLine: i + 1,
        multiLineIndicator: indicator,
        continuationLines: spanned,
      };
    }

    const spanned: string[] = [];
    for (let j = i + 1; j < lines.length; j++) {
      if (lines[j].startsWith(" ") || lines[j].startsWith("\t")) {
        spanned.push(lines[j]);
      } else {
        break;
      }
    }
    return {
      raw: inlineValue,
      startLine: i + 1,
      multiLineIndicator: null,
      continuationLines: spanned,
    };
  }
  return { raw: null, startLine: 0, multiLineIndicator: null, continuationLines: [] };
}

function checkDescription(shape: DescriptionShape): Finding[] {
  const findings: Finding[] = [];
  const raw = shape.raw ?? "";
  const cleaned = raw.replace(/^["']|["']$/g, "").trim();

  if (shape.multiLineIndicator !== null) {
    findings.push({
      severity: "block",
      rule: "single-line",
      message: `Description uses block scalar indicator '${shape.multiLineIndicator}' — multi-line descriptions silently break skill discovery (GitHub #9817 / #4700).`,
      remediation:
        "Convert to a single-line value. If your editor (e.g., Prettier) auto-wraps, add `# prettier-ignore` above the description line OR set `proseWrap: false` in `.prettierrc`.",
    });
  } else if (shape.continuationLines.length > 0) {
    findings.push({
      severity: "block",
      rule: "single-line",
      message: `Description spans ${shape.continuationLines.length + 1} lines via YAML continuation. Prettier-style auto-wrapping likely caused this.`,
      remediation:
        "Reformat the description on a single line. Add `# prettier-ignore` above it OR set `proseWrap: false` in `.prettierrc` to prevent re-wrapping.",
    });
  }

  if (cleaned.length > MAX_DESCRIPTION_CHARS) {
    findings.push({
      severity: "block",
      rule: "max-length",
      message: `Description is ${cleaned.length} chars (limit: ${MAX_DESCRIPTION_CHARS}). Over-length descriptions silently truncate (GitHub #881).`,
      remediation: `Truncate to ≤${MAX_DESCRIPTION_CHARS} chars. Move detail into Skill body / Dependencies / Usage sections.`,
    });
  }

  const lower = cleaned.toLowerCase();
  const hasTrigger = TRIGGER_PHRASES.some((t) => lower.includes(t));
  if (!hasTrigger) {
    findings.push({
      severity: "warn",
      rule: "trigger-phrase",
      message:
        "Description does not include a 'Use when ...' trigger phrase. Claude relies on trigger phrases for skill selection.",
      remediation:
        "Add 'Use when X, Y, or Z.' to the description so Claude knows when to load this skill.",
    });
  }

  return findings;
}

function main(): void {
  const argv = process.argv.slice(2);
  if (argv.length !== 1) usage("missing or extra arguments — expected exactly one SKILL.md path");
  if (argv[0].trim().length === 0) usage("path argument must not be empty");

  const skillPath = resolve(argv[0]);
  if (!existsSync(skillPath)) usage(`SKILL.md not found at ${skillPath}`);

  const content = safeReadFile(skillPath);
  const fm = extractFrontmatter(content);
  if (fm === null) {
    console.error("check-description: SKILL.md is missing YAML frontmatter (--- ... ---). FAIL.");
    process.exit(1);
  }

  const shape = extractDescription(fm);
  if (shape.raw === null) {
    console.error("check-description: SKILL.md frontmatter has no 'description:' field. FAIL.");
    process.exit(1);
  }

  if (shape.raw.replace(/^["']|["']$/g, "").trim().length === 0) {
    console.error(
      "check-description: SKILL.md frontmatter has 'description:' set to an empty value. " +
        "Empty descriptions break skill discovery in the /menu. FAIL.",
    );
    process.exit(1);
  }

  const findings = checkDescription(shape);

  let blocked = false;
  for (const f of findings) {
    const tag = f.severity === "block" ? "FAIL" : f.severity === "warn" ? "WARN" : "INFO";
    console.log(`[${tag}] ${f.rule}: ${f.message}`);
    console.log(`        → ${f.remediation}`);
    if (f.severity === "block") blocked = true;
  }

  if (findings.length === 0) {
    console.log("check-description: PASS — description is single-line, within length cap, and has trigger phrase.");
  } else {
    const blocks = findings.filter((f) => f.severity === "block").length;
    const warns = findings.filter((f) => f.severity === "warn").length;
    console.log(`check-description: ${blocks} block, ${warns} warn`);
  }

  process.exit(blocked ? 1 : 0);
}

main();
