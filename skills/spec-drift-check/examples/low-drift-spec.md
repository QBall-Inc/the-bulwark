# Fixture: P10.Y — Add coverage parser unit tests (low-drift spec)

**Phase:** P10
**Estimated sessions:** 1
**Status:** PENDING

This fixture is a synthetic Work Package brief used by the `spec-drift-check` smoke test. The brief contains exactly ONE drift instance: a line-ref drift that does not change the file or symbol identity. When `spec-drift-check` runs against this fixture, it should emit a **PROCEED_ADJUSTED** verdict with one LOW-severity finding (DRIFT — line-ref).

---

## Discovery Context

`scripts/hooks/lib/coverage_check.py` exposes `parse_followup_edits_expected()` (the P10.22 grace-window parser). This WP would add focused unit tests covering edge cases the existing integration tests do not exercise (e.g., scalar-form `followup_edits_expected: null`, malformed flow-form lists, value parsing for `grace_window_seconds`).

---

## Implementation Plan

### Step 1 — Author unit tests for `parse_followup_edits_expected`

The parser is defined at `scripts/hooks/lib/coverage_check.py:200`. Author a new file `tests/hooks/test-coverage-parser.py` with three test cases:

1. Scalar `followup_edits_expected: null` parses to `None` without error.
2. Flow-form empty list `followup_edits_expected: []` parses to empty list.
3. Block-form list with `grace_window_seconds: 600` parses with the integer correctly extracted.

### Step 2 — Wire tests into Justfile

Add `test-coverage-parser` recipe in the project Justfile that runs `python3 tests/hooks/test-coverage-parser.py`.

---

## Acceptance Criteria

| ID | Criterion | Pass condition |
|----|-----------|----------------|
| AC-1 | Tests exist | `tests/hooks/test-coverage-parser.py` covers 3 cases above |
| AC-2 | Tests pass | `python3 tests/hooks/test-coverage-parser.py` exits 0 |
| AC-3 | Justfile recipe | `just test-coverage-parser` executes the test file |
