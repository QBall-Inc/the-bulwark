# Fixture: P10.X — Coverage check observability extension (clean spec)

**Phase:** P10
**Estimated sessions:** 1
**Status:** PENDING

This fixture is a synthetic Work Package brief used by the `spec-drift-check` skill's smoke test. All concrete claims in this brief MUST match current Bulwark code state at the time of fixture authorship. When `spec-drift-check` runs against this fixture, it should emit a **PROCEED** verdict with zero drift findings.

---

## Discovery Context

The Stop hook coverage check resolves whether recent edits are covered by a recent pipeline run. The relevant module is `scripts/hooks/lib/coverage_check.py`, which exposes `parse_reviewed_files()` for the standard coverage path and `parse_followup_edits_expected()` for the P10.22 grace-window branch. Both parsers are invoked from `coverage_in_window()`.

This WP would extend observability of these functions by emitting log lines on each parse + coverage attempt. The implementation is small enough to fit in one session.

---

## Implementation Plan

### Step 1 — Add log emission to `parse_reviewed_files`

Modify `scripts/hooks/lib/coverage_check.py` at the `parse_reviewed_files` definition (line 188 in current state) to emit a log line each time it runs. Log format: `[coverage_check] parse_reviewed_files <path> -> <N> entries`.

### Step 2 — Add log emission to `parse_followup_edits_expected`

Mirror Step 1 for `parse_followup_edits_expected` (defined at `scripts/hooks/lib/coverage_check.py:275`). The two parsers share the SEC-003 1MB cap and SEC-006 symlink rejection — log lines should follow the same shape.

### Step 3 — Add log emission to `coverage_in_window`

The coverage decision lives in `coverage_in_window` (defined at `scripts/hooks/lib/coverage_check.py:373`). Log the decision: `[coverage_check] coverage_in_window <file> <bucket> -> covered=<bool>`.

### Step 4 — Update `skills/code-review/SKILL.md` from version 1.1.0

The Code Review skill currently ships at version 1.1.0 (post-P10.22 schema bump). Bump to 1.1.1 after this observability extension is complete to record that downstream pipelines now see richer coverage logs.

---

## Acceptance Criteria

| ID | Criterion | Pass condition |
|----|-----------|----------------|
| AC-1 | Coverage parser logs | `parse_reviewed_files` and `parse_followup_edits_expected` each emit one log line per invocation |
| AC-2 | Coverage decision log | `coverage_in_window` emits a decision log line including bucket + covered boolean |
| AC-3 | code-review version bump | `skills/code-review/SKILL.md` version field updated to 1.1.1 |

---

## Verification

1. Run `tests/hooks/test-suggest-pipeline-stop.sh` — all 100 asserts pass with new log lines visible in test output.
2. Manual smoke: trigger a Stop hook fire and inspect `~/.claude/hooks.log` for the three new log line patterns.
