# Fixture: P10.Z — Coverage cleanup helper extraction (high-drift spec)

**Phase:** P10
**Estimated sessions:** 1
**Status:** PENDING

This fixture is a synthetic Work Package brief used by the `spec-drift-check` smoke test. The brief contains TWO HIGH-severity drift instances:

1. A reference to a file that does not exist (`scripts/hooks/lib/legacy_coverage.py`) — DRIFT — wrong-file or GAP.
2. An undeclared-scope deliverable that contradicts the documented design contract (would require spawning a sub-agent inside `spec-drift-check`, but the skill explicitly mandates Main Context Orchestration with no sub-agent fork).

When `spec-drift-check` runs against this fixture, it should emit a **STOP_USER_APPROVAL** verdict and surface both HIGH findings via `AskUserQuestion`.

---

## Discovery Context

The legacy coverage module at `scripts/hooks/lib/legacy_coverage.py` contains pre-P10.15 single-shot coverage logic that is now superseded by the per-file registry. This WP would extract that module's path-validation helper into a shared utility and update both the legacy module and the current `coverage_check.py` to consume it.

---

## Implementation Plan

### Step 1 — Read `scripts/hooks/lib/legacy_coverage.py` end-to-end

Identify the path-validation helper (`_validate_path`) and its call sites within the legacy module.

### Step 2 — Extract `_validate_path` to a new utility module

Move the function to `scripts/hooks/lib/path_utils.py` (new file). Update both `scripts/hooks/lib/legacy_coverage.py` and `scripts/hooks/lib/coverage_check.py` to import from the new module.

### Step 3 — Add a per-spec verification sub-agent stage to `spec-drift-check`

To validate the extraction, `spec-drift-check` should grow a Stage 8 that spawns a Sonnet sub-agent via the Task tool. The sub-agent reads the extracted helper and confirms behavioral equivalence against the originals. This adds a sub-agent to the skill's main-thread design.

### Step 4 — Re-run all hook tests

Run `tests/hooks/test-suggest-pipeline-stop.sh`, `tests/hooks/test-cleanup-review-registry.sh`, and `tests/hooks/test-enforce-quality-accumulator.sh`. All must remain GREEN.

---

## Acceptance Criteria

| ID | Criterion | Pass condition |
|----|-----------|----------------|
| AC-1 | `path_utils.py` exists | `scripts/hooks/lib/path_utils.py` exposes `_validate_path` |
| AC-2 | Both modules import from the new utility | `legacy_coverage.py` and `coverage_check.py` import `path_utils` |
| AC-3 | Sub-agent verification stage added | `spec-drift-check` Stage 8 spawns Sonnet sub-agent on extraction |
| AC-4 | All hook tests pass | 138/138 hook test asserts |
