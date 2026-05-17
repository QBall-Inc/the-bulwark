# Step 4 — Plan Adjustment

## Purpose

Rewrite the spec's implementation-plan section based on the Stage 3 findings. The output of this stage becomes the **adjusted plan** — the source of truth for the rest of the WP. Stage 7 binds it: the implementer follows this plan, not the original spec.

If Stage 3 produced zero non-CONFIRMED findings, Stage 4 is a no-op (the original plan stands). Otherwise, every finding must be reflected in the rewrite.

---

## Procedure

For each finding category, apply the matching adjustment:

### DRIFT-missing-scope (deliverable is a no-op)

**Action**: Drop the deliverable from the plan. Note the drop in the `verification_checklist:` so the implementer doesn't accidentally re-add it.

**Token-budget impact**: subtract the original estimate for the dropped deliverable.

### DRIFT-undeclared-scope (deliverable missing from spec)

**Action**: Add the new deliverable to the plan. If severity is HIGH (which it should be by default), the verdict is STOP_USER_APPROVAL and the user must sign off before this addition is binding.

**Token-budget impact**: add an estimate for the new deliverable.

### DRIFT-wrong-file (path target is wrong)

**Action**: Re-target the deliverable's path in the plan to the correct path. Note the re-target in the `verification_checklist:`.

**Token-budget impact**: usually zero (same scope, different target).

### DRIFT-line-ref (line off, file correct)

**Action**: Update the line reference (or the contextual cue, if the spec used "around line 200" framing) to match current state. This is typically a doc fix; the deliverable itself is unchanged.

**Token-budget impact**: zero.

### AC re-interpretation (ambiguous AC)

**Action**: Resolve the ambiguity explicitly. Document the chosen reading + the rationale in the `ac_reinterpretations:` section of the log. Update any plan deliverables that depend on the resolved AC.

**Token-budget impact**: usually zero, occasionally negative (a tighter interpretation drops scope).

### GAP (claim references nothing)

**Action**: STOP. GAP findings escalate to STOP_USER_APPROVAL; the user must clarify the spec. Do NOT silently drop the deliverable that referenced the GAP — surface it.

**Token-budget impact**: deferred until the user clarifies.

### CONFIRMED

**Action**: None. Carry the original deliverable forward unchanged.

---

## Re-Estimate Tokens

After applying the adjustments above, re-estimate the token budget for the WP. The adjusted budget appears in the log's `adjusted_plan.estimated_token_delta:` field as a signed delta from the original estimate (`+5K`, `-10K`, `0`).

A non-trivial delta (≥10K either direction) is itself a signal worth surfacing in the verdict summary, even if the finding mix doesn't otherwise force STOP_USER_APPROVAL.

---

## Before / After Example

### Original spec plan section

```markdown
## Implementation Plan

### Step 1 — Add `parseFollowupEdits()` helper to `coverage_check.py`
- 80 lines, ~5K tokens
- File: `scripts/hooks/coverage_check.py:88`

### Step 2 — Update `code-review` skill schema
- Add `followup_edits_expected` field to diagnostic YAML template
- File: `skills/code-review/SKILL.md:391`

### Step 3 — Test coverage
- Add 5 test cases to `tests/hooks/test-suggest-pipeline-stop.sh`
```

### Stage 3 findings (hypothetical)

- D-01: `coverage_check.py:88` actually shows the helper at line 91 → DRIFT-line-ref, LOW
- D-02: `code-review` SKILL.md does not have a line 391; the schema section is at line 416 → DRIFT-line-ref, LOW
- D-03: `parseFollowupEdits()` already exists at `coverage_check.py:91` from a prior session → DRIFT-missing-scope, MEDIUM (Step 1 is a no-op)
- D-04: tests file `tests/hooks/test-suggest-pipeline-stop.sh` exists, but adding tests requires the file to be writable and a `set -e` audit per `process_test_harness_set_e_pattern.md` — undeclared in spec → DRIFT-undeclared-scope, HIGH

### Adjusted plan after Stage 4

```markdown
## Adjusted Implementation Plan
(supersedes original spec; binding per Stage 7)

### Step 1 — DROPPED — `parseFollowupEdits()` already exists
- Dropped per finding D-03 (DRIFT-missing-scope, MEDIUM)
- Token savings: -5K

### Step 2 — Update `code-review` skill schema
- Add `followup_edits_expected` field to diagnostic YAML template
- File: `skills/code-review/SKILL.md` (line ref updated; current location ~line 416 per finding D-02)

### Step 3 — Test coverage
- Add 5 test cases to `tests/hooks/test-suggest-pipeline-stop.sh`
- ALSO: confirm `set -e` is present in the test harness per `process_test_harness_set_e_pattern.md` (undeclared in original spec; finding D-04 surfaces this)
- Token addition: +1K

estimated_token_delta: -4K
```

If finding D-04 is severity HIGH (undeclared scope), the verdict is STOP_USER_APPROVAL and the user must approve adding the `set -e` audit task before Stage 7 binding takes effect.

---

## What NOT To Do at This Stage

- Do NOT auto-apply LOW findings to the original spec by editing the brief. The skill is read-only. Capture the corrections in the log, not in the source.
- Do NOT silently merge HIGH findings into the adjusted plan — they require Stage 6 to emit STOP_USER_APPROVAL and the user to confirm.
- Do NOT carry forward a deliverable that DRIFT-missing-scope flagged as a no-op. Doing so wastes the next session's tokens.
- Do NOT estimate token deltas with false precision. Round to the nearest 1K; the goal is signal, not accounting.
