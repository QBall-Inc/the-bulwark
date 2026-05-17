#!/usr/bin/env bun
// check-skill-size.ts — Tiered SKILL.md line-count enforcement (memo D8 amended S107).
//
// Tiers:
//   <200       OK             exit 0, status line + PASS message
//   200-499    Advisory       exit 0, status line + soft note ("consider extracting if it grows")
//   500-599    Strong warn    exit 0, status line + loud warning (Anthropic 500-line cap reached)
//   ≥600       HARD CAP       exit 1, refactor proposal listing extraction candidates
//
// Per memo D8 (S107): 200 advisory / 500 strong (Anthropic spec) / 600 hard (Bulwark refusal).
//
// Exit codes:
//   0 — PASS / Advisory / Strong warn (under hard cap)
//   1 — HARD CAP exceeded (≥600 lines) — refactor proposal printed
//   2 — Usage error (missing/invalid path) OR I/O error (permission denied, file too large)
//
// Usage:
//   just check-skill-size <path-to-SKILL.md>
//   bun "${CLAUDE_PLUGIN_ROOT}/skills/create-skill/scripts/check-skill-size.ts" <path>

import { existsSync, readFileSync, statSync } from "fs";
import { resolve } from "path";

const ADVISORY_TIER = 200;
const STRONG_TIER = 500;
const HARD_CAP = 600;
const MIN_EXTRACTABLE_LINES = 30;
const MAX_FILE_BYTES = 512 * 1024; // 512 KB — generous for any SKILL.md (SEC-T022 size gate)

interface Section {
  heading: string;
  level: number;
  startLine: number;
  endLine: number;
  lineCount: number;
}

function usage(reason: string): never {
  console.error(`check-skill-size: ${reason}`);
  console.error("");
  console.error("Usage:");
  console.error("  just check-skill-size <path-to-SKILL.md>");
  console.error("  bun check-skill-size.ts <path-to-SKILL.md>");
  process.exit(2);
}

function ioError(reason: string): never {
  console.error(`check-skill-size: ${reason}`);
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

function parseSections(content: string): Section[] {
  const lines = content.split("\n");
  const sections: Section[] = [];
  let inFence = false;
  let current: Partial<Section> | null = null;

  const finalize = (endLine: number): void => {
    if (current && typeof current.startLine === "number") {
      current.endLine = endLine;
      current.lineCount = endLine - current.startLine + 1;
      sections.push(current as Section);
    }
  };

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    if (/^```/.test(line.trimStart())) {
      inFence = !inFence;
      continue;
    }
    if (inFence) continue;

    const headingMatch = /^(#{1,6})\s+(.+)$/.exec(line);
    if (!headingMatch) continue;
    const level = headingMatch[1].length;
    if (level > 3) continue;

    finalize(i - 1);
    current = {
      heading: headingMatch[2].trim(),
      level,
      startLine: i,
    };
  }
  finalize(lines.length - 1);
  return sections;
}

function classifyExtractionTarget(heading: string): string {
  const h = heading.toLowerCase();
  if (/example|sample|demo|fixture/.test(h)) return "examples/";
  if (/reference|schema|catalog|convention|guidance|definition/.test(h)) return "references/";
  if (/template|skeleton|boilerplate/.test(h)) return "templates/";
  if (/script|implementation detail|algorithm/.test(h)) return "scripts/ (or references/)";
  if (/diagnostic|trace|log format/.test(h)) return "templates/ (YAML schema)";
  return "references/";
}

function refactorProposal(sections: Section[], totalLines: number): string {
  const candidates = sections
    .filter((s) => s.level >= 2 && s.lineCount >= MIN_EXTRACTABLE_LINES)
    .sort((a, b) => b.lineCount - a.lineCount)
    .slice(0, 8);

  if (candidates.length === 0) {
    return "  (no large extractable sections detected — consider splitting into multiple skills)";
  }

  const overhang = totalLines - HARD_CAP;
  const lines: string[] = [];
  lines.push(`  Total: ${totalLines} lines (over by ${overhang}). Largest extractable sections:`);
  for (const s of candidates) {
    const target = classifyExtractionTarget(s.heading);
    lines.push(
      `    L${s.startLine + 1}-${s.endLine + 1} (${s.lineCount} lines) "${s.heading}" → ${target}`,
    );
  }
  lines.push("");
  lines.push("  Strategy: move 1-2 largest sections to their respective subdirectories,");
  lines.push("  replace the moved section in SKILL.md with a one-line cross-reference.");
  return lines.join("\n");
}

function main(): void {
  const argv = process.argv.slice(2);
  if (argv.length !== 1) usage("missing or extra arguments — expected exactly one SKILL.md path");
  if (argv[0].trim().length === 0) usage("path argument must not be empty");

  const skillPath = resolve(argv[0]);
  if (!existsSync(skillPath)) usage(`SKILL.md not found at ${skillPath}`);

  const content = safeReadFile(skillPath);
  const lineCount = content.split("\n").length;

  let tier: "OK" | "ADVISORY" | "STRONG" | "HARD";
  if (lineCount >= HARD_CAP) tier = "HARD";
  else if (lineCount >= STRONG_TIER) tier = "STRONG";
  else if (lineCount >= ADVISORY_TIER) tier = "ADVISORY";
  else tier = "OK";

  console.log(`check-skill-size: ${skillPath}`);
  console.log(`  Lines: ${lineCount}`);
  console.log(`  Tier:  ${tier} (advisory ≥${ADVISORY_TIER}, strong ≥${STRONG_TIER}, hard ≥${HARD_CAP})`);

  if (tier === "OK") {
    console.log("  PASS: under all tiers.");
    process.exit(0);
  }

  if (tier === "ADVISORY") {
    console.log(`  ADVISORY: SKILL.md has crossed ${ADVISORY_TIER} lines.`);
    console.log("           Consider extracting reference content if it grows further.");
    process.exit(0);
  }

  if (tier === "STRONG") {
    console.log(`  STRONG WARN: SKILL.md has crossed Anthropic's ${STRONG_TIER}-line soft cap.`);
    console.log("               Strongly recommend splitting reference content into references/.");
    console.log("               Continued growth risks load-time penalties and reduced LLM coherence.");
    process.exit(0);
  }

  // HARD
  const sections = parseSections(content);
  console.log(`  HARD CAP REACHED: SKILL.md is ${lineCount} lines (cap ${HARD_CAP}).`);
  console.log(`  STOP — generator must refuse to emit a single SKILL.md exceeding ${HARD_CAP} lines.`);
  console.log("");
  console.log("  Refactor proposal:");
  console.log(refactorProposal(sections, lineCount));
  process.exit(1);
}

main();
