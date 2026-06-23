# Diagnostic Schema (Phase 3 Output)

Full schema, field rules, and examples for the code-review Phase 3 diagnostic log. Load this when emitting diagnostic output. The SKILL.md `## Diagnostic Output` section carries the binding contract (where to write + which top-level fields are mandatory); this file is the detailed reference.

Write diagnostic output to: `logs/diagnostics/code-review-{timestamp}.yaml` (ISO-8601 timestamp, hyphens for filename safety).

---

## Full Format

```yaml
diagnostic:
  skill: code-review
  timestamp: 2026-01-31T12:00:00Z
  invocation:
    mode: comprehensive | quick
    sections_run: [security, type_safety, linting, standards]
    framework_detected: react
    framework_override: null
    files_count: 5
    lines_total: 450
  static_analysis:
    typecheck: passed | failed | skipped
    lint: passed | failed | skipped
  findings_summary:
    critical: 1
    important: 3
    suggestion: 5
  duration_ms: 1200

# Files reviewed (top-level field — consumed by the Stop hook for per-file
# pipeline-recursion suppression). MUST be a flat list of paths relative
# to ${CLAUDE_PROJECT_DIR}. Empty list `[]` is valid if the diagnostic
# was emitted with no specific file scope. Missing field = strict mode
# disables suppression for this log.
reviewed_files:
  - src/auth/token.ts
  - src/api/users.ts

# Language applicability (top-level field — P10.21). Per-file record of which
# review sections were applied vs skipped, the detected language, and a rationale
# for any skip. Lets pipeline orchestration + audits confirm that, e.g., Type
# Safety was deliberately skipped on a bash file rather than silently missed.
# `partial` is recorded by suffixing the section name (e.g., type_safety_partial).
language_applicability:
  - file: scripts/foo.py
    detected_language: python
    sections_applied: [security, type_safety_partial, linting, standards]
    sections_skipped: []
  - file: scripts/foo.sh
    detected_language: bash
    sections_applied: [security, linting, standards]
    sections_skipped: [type_safety]
    skip_rationale: "Bash has no static type system"

# Followup edits expected (top-level field — consumed by the Stop hook
# grace-window logic, P10.22). OPTIONAL list-of-mappings. Emit one entry
# per file that received at least one critical or important finding.
# Subsequent edits to a listed file within grace_window_seconds of this
# log being written are treated as pre-covered (no re-fire).
followup_edits_expected:
  - file: src/auth/token.ts
    grace_window_seconds: 1800
    finding_ids: [SEC-001]
    rationale: "1 critical (SQL injection); user-applied fix expected within grace window"
```

---

## Followup Edits Expected (Stop Hook Grace Window — P10.22)

**Purpose**: When a code-review run produces actionable findings (severity `critical` or `important`), the user typically applies fixes immediately after reviewing the output. Without this metadata, those fix-edits trigger a fresh Stop hook fire because the pipeline log was written BEFORE the fix-edits — recursion. The `followup_edits_expected` field tells the Stop hook coverage check that edits to the listed files within the grace window are pre-covered.

**When to emit** — emit one entry per file with at least one finding of severity `critical` or `important`. Files with `suggestion`-only findings do NOT need a followup entry (suggestions are cosmetic and user-driven).

**Field schema**:
- `file` (required) — path relative to `${CLAUDE_PROJECT_DIR}`. Must match exactly the path used in `reviewed_files` for the same file.
- `grace_window_seconds` (optional, default 1800) — duration in seconds after this log is written during which subsequent edits to the file are treated as covered. 1800 (30 min) accommodates user deliberation + multi-fix application.
- `finding_ids` (optional, informational) — list of finding identifiers driving the followup expectation. Used for diagnostic clarity; not consulted by coverage logic.
- `rationale` (optional, informational) — human-readable explanation. Surfaced in diagnostic output.

**When NOT to emit** — if a review pass produces zero `critical` or `important` findings, omit the field entirely (or emit `followup_edits_expected: []`). Suggestions-only output should NOT register followup expectations.

**Example**:
```yaml
followup_edits_expected:
  - file: src/auth/token.ts
    grace_window_seconds: 1800
    finding_ids: [SEC-001]
    rationale: "1 critical SQL injection finding; user-applied fix expected"
  - file: src/api/users.ts
    grace_window_seconds: 1800
    finding_ids: [TYPE-001, SEC-002]
    rationale: "1 important type-safety + 1 important auth check"
```

**Pipeline-stage emission**: when code-review runs as a pipeline (`SecurityReviewer |> TypeSafetyReviewer |> LintReviewer |> StandardsReviewer |> ReviewSynthesizer`), each section reviewer emits its own `followup_edits_expected` in its sectional output (per `templates/output-pipeline.yaml`). The orchestrator's Stage 5 ReviewSynthesizer aggregates across all 4 reviewer logs into the consolidated `logs/diagnostics/code-review-{timestamp}.yaml`.

**Stage 5 aggregation algorithm** — consolidate the 4 sectional `followup_edits_expected` lists into one top-level list:
1. **Group by `file`** (string equality on path). For each unique file mentioned in any of the 4 reviewer logs:
2. **Union `finding_ids`** across all reviewer entries for that file (deduplicate; preserve order: security first, then type_safety, linting, standards).
3. **Max `grace_window_seconds`** — take the largest grace window declared by any reviewer for that file. Reviewers with stricter (smaller) windows are subsumed by reviewers with longer windows.
4. **Concatenate `rationale`** with `; ` separator, prefixed by section name (e.g., `"security: 1 critical (SQL inj); type_safety: 1 important (any usage)"`).
5. **Skip files with zero entries** — if no reviewer emitted a followup for a file, do not include it in the synthesized list.

Emit the aggregated list as the top-level `followup_edits_expected` field of the synthesis log. The Stop hook's `coverage_check.py:parse_followup_edits_expected()` reads this consolidated field directly; per-reviewer logs are also scanned independently, so partial coverage is preserved if synthesis is skipped.

---

## Language Applicability (P10.21)

Per-file record of which review sections ran. Shape:
- `file` — path relative to `${CLAUDE_PROJECT_DIR}` (match `reviewed_files`).
- `detected_language` — from file extension (see SKILL.md `## Framework Detection` → Language Detection).
- `sections_applied` — list of applied sections; record `partial` applicability by suffixing the section name (e.g., `type_safety_partial`).
- `sections_skipped` — list of skipped sections.
- `skip_rationale` (when any section skipped) — one-line reason (e.g., `"Bash has no static type system"`).

In **pipeline-stage** output (`templates/output-pipeline.yaml`), each reviewer records ITS single section's per-file `decision` (applied | partial | skipped); ReviewSynthesizer (Stage 5) consolidates these into the `sections_applied`/`sections_skipped` shape above.
