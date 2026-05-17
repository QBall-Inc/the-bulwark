# Step 5 — Verification Log Template

## Purpose

Capture the audit's findings, AC re-interpretations, adjusted plan, verification checklist, decision, and ROI estimate in a single canonical log file. The log is the deliverable; downstream sessions and implementers consume it directly.

**Log path**: `$PROJECT_DIR/logs/spec-verify-{session}-{topic}.md`

- `{session}` is the current Bulwark session id (e.g., `122`).
- `{topic}` is a short slug derived from the subject spec filename (e.g., `P10.16` for `P10.16-statusline-lock-cleanup-observability.md`).

Example: `logs/spec-verify-122-P10.16.md`.

---

## Full Template

```yaml
# logs/spec-verify-{session}-{topic}.md
# Verification log for spec-drift-check run.
# Subject: {path-to-spec}
# Run timestamp: {ISO-8601}
# Skill version: 1.0.0

metadata:
  reviewer: spec-drift-check
  subject: {path-to-spec}
  session: {session-id}
  timestamp: {ISO-8601}
  spec_word_count: {N}
  claims_extracted: {N}
  claims_verified: {N}

findings:
  - id: D-01
    claim_id: C-01
    category: drift-line-ref | drift-wrong-file | drift-missing-scope | drift-undeclared-scope | ac-reinterpretation | gap | confirmed
    severity: LOW | MEDIUM | HIGH        # n/a for confirmed
    spec_claim: "<verbatim quote from spec>"
    actual_state: "<what current code/state shows, verbatim>"
    resolution: "<doc fix | plan adjustment | scope expansion | ask user | none>"
  # ... D-02, D-03, ...

ac_reinterpretations:
  - ac: AC-N
    ambiguity: "<what's unclear in the original AC>"
    chosen_interpretation: "<the reading we will execute against>"
    rationale: "<why this reading; what it implies for the plan>"
  # ... AC-M, ...

adjusted_plan:
  binding_status: "supersedes original spec for rest of WP"
  deliverables:
    - id: AD-01
      description: "<deliverable text>"
      original_spec_step: <number or null if newly added>
      change_from_spec: dropped | re-targeted | unchanged | added
      target_path: <path>
      token_estimate: "~5K"
    # ... AD-02, ...
  estimated_token_delta: "+5K | -10K | 0"

verification_checklist:
  - "<item the implementer must confirm at end of WP — typically per finding>"
  # ...

proceed_decision: PROCEED | PROCEED_ADJUSTED | STOP_USER_APPROVAL

decision_rationale: |
  {1-3 sentences explaining the verdict in terms of the finding mix.}

roi:
  spent_tokens_estimate: "~{N}K"
  estimated_savings: "~{N}K"
  net: positive | break-even | negative
  rationale: |
    {1-3 sentences explaining the savings estimate — what rework was avoided.}
```

---

## How to Fill Each Section

### `metadata`

Captured as the run begins. `claims_extracted` is the count from Stage 1; `claims_verified` should equal `claims_extracted` unless a verification command failed.

**Filled-in example**:
```yaml
metadata:
  reviewer: spec-drift-check
  subject: plans/task-briefs/P10.16-statusline-lock-cleanup-observability.md
  session: 122
  timestamp: 2026-05-09T14:32:00Z
  spec_word_count: 4521
  claims_extracted: 23
  claims_verified: 23
```

### `findings`

One entry per claim from Stage 1. CONFIRMED claims SHOULD be included (with `severity: n/a`) so the log is a complete record of what was checked. Drift findings carry the actual_state verbatim.

**Filled-in example**:
```yaml
findings:
  - id: D-01
    claim_id: C-03
    category: drift-line-ref
    severity: LOW
    spec_claim: "The recursion bug is at coverage_check.py:88."
    actual_state: "Line 88 is blank (the helper function moved to line 91 in S121 cleanup; verbatim line 91: `def parse_followup_edits_expected(diagnostic_path):`)."
    resolution: "doc fix — update spec line ref to 91 in implementation comments"

  - id: D-02
    claim_id: C-07
    category: drift-undeclared-scope
    severity: HIGH
    spec_claim: "Add 5 test cases to test-suggest-pipeline-stop.sh."
    actual_state: "Test harness `tests/hooks/test-suggest-pipeline-stop.sh:1` sets `set -euo pipefail` per process_test_harness_set_e_pattern.md. Adding test cases requires assertion-counter pattern (failures via counter, not exit), which the spec does not mention."
    resolution: "scope expansion — add `set -e` audit task to plan; ask user"
```

### `ac_reinterpretations`

One entry per acceptance criterion that Stage 3 flagged as ambiguous. The `chosen_interpretation` becomes binding for the WP via Stage 7.

**Filled-in example**:
```yaml
ac_reinterpretations:
  - ac: AC-3
    ambiguity: "Spec says 'update the schema' but two schemas exist (diagnostic schema in code-review/SKILL.md and findings schema in templates/findings-output.yaml)."
    chosen_interpretation: "Update the diagnostic schema (code-review/SKILL.md). The findings template already has the field."
    rationale: "Stage 2 verification of C-12 showed the findings template already includes `followup_edits_expected`; only the diagnostic surface is missing."
```

### `adjusted_plan`

The binding plan for the rest of the WP. Each deliverable has an explicit `change_from_spec` field so the implementer (and future readers) can audit the rewrite.

**Filled-in example**:
```yaml
adjusted_plan:
  binding_status: "supersedes original spec for rest of WP"
  deliverables:
    - id: AD-01
      description: "Update diagnostic schema in code-review/SKILL.md to include followup_edits_expected"
      original_spec_step: 2
      change_from_spec: re-targeted
      target_path: skills/code-review/SKILL.md
      token_estimate: "~3K"
    - id: AD-02
      description: "Add 5 test cases to test-suggest-pipeline-stop.sh + audit set -e"
      original_spec_step: 3
      change_from_spec: unchanged
      target_path: tests/hooks/test-suggest-pipeline-stop.sh
      token_estimate: "~6K"
  estimated_token_delta: "-4K"
```

### `verification_checklist`

Items the implementer (or a downstream reviewer) must confirm at the end of the WP to verify the verified plan was executed. Typically one item per drift finding that survives into the adjusted plan.

**Filled-in example**:
```yaml
verification_checklist:
  - "Diagnostic schema in skills/code-review/SKILL.md includes followup_edits_expected (field, not just prose)"
  - "test-suggest-pipeline-stop.sh has 5 new test cases, all using assertion-counter pattern (no premature exit)"
  - "AC-3 resolution committed: only diagnostic schema modified; findings template unchanged"
```

### `proceed_decision` + `decision_rationale`

The verdict itself + a 1-3 sentence summary tying the finding mix to the verdict. See `step-6-decision-matrix.md` for the matrix.

**Filled-in example**:
```yaml
proceed_decision: STOP_USER_APPROVAL
decision_rationale: |
  Finding D-02 is HIGH (DRIFT-undeclared-scope: set -e audit task missing from spec).
  Per the decision matrix, any HIGH finding triggers STOP_USER_APPROVAL.
  Surface the scope expansion to the user via AskUserQuestion before binding the adjusted plan.
```

### `roi`

The cost-vs-savings estimate. Approximate; the goal is signal, not accounting. Round to the nearest 1K. `net: positive` means estimated savings exceed spent tokens.

**Filled-in example**:
```yaml
roi:
  spent_tokens_estimate: "~6K"
  estimated_savings: "~20K"
  net: positive
  rationale: |
    Caught D-02 (undeclared scope: set -e audit) before implementation.
    Without this finding, the implementer would have added tests, hit a fail-fast
    on the missing audit, debugged for ~15K tokens, then re-implemented. ROI = +14K net.
```

---

## Field-Level Validation

Before writing the log, confirm:

- Every `findings` entry has BOTH `spec_claim` AND `actual_state` populated verbatim.
- Every `severity` value is one of LOW / MEDIUM / HIGH (or `n/a` for CONFIRMED).
- Every `category` value matches the 7-entry taxonomy from `step-3-categorization.md`.
- `proceed_decision` value matches the matrix in `step-6-decision-matrix.md` (any HIGH → STOP_USER_APPROVAL).
- `adjusted_plan.deliverables[*].change_from_spec` is set on every entry.

If any check fails, fix before writing — the log is binding (Stage 7) and downstream consumers parse it.

---

## After Writing the Log

The log path is the artifact. Surface it to the user. If the verdict is STOP_USER_APPROVAL, immediately follow with the AskUserQuestion flow per `step-6-decision-matrix.md`. The implementer (next session, next command) reads from this log, not from the original spec.
