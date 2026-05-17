# Output Template — Canonical YAML Schema

## Purpose

This is the **schema reference** for the verification log written in Stage 5 (`logs/spec-verify-{session}-{topic}.md`) and the structured findings in `templates/findings-output.yaml`. SKILL.md, `step-5-log-template.md`, and the templates file all mirror this schema — when in doubt, this file is canonical.

---

## Full Schema

```yaml
metadata:
  reviewer: spec-drift-check          # string — fixed value
  subject: <path>                     # string — the spec file being audited
  session: <id>                       # string or int — Bulwark session id
  timestamp: <ISO-8601>               # string — UTC ISO-8601
  spec_word_count: <N>                # int — approximate word count of the subject spec
  claims_extracted: <N>               # int — Stage 1 claim count
  claims_verified: <N>                # int — Stage 2 verification count

findings:
  - id: D-NN                          # string — sequential within this run (D-01, D-02, ...)
    claim_id: C-NN                    # string — back-reference to the Stage 1 claim
    category: <one of seven>          # enum — see Field Reference below
    severity: <one of four>           # enum — LOW | MEDIUM | HIGH (or n/a for confirmed)
    spec_claim: <verbatim quote>      # string — the spec's assertion, verbatim
    actual_state: <verbatim quote>    # string — current state evidence, verbatim
    resolution: <one of five>         # enum — see Field Reference below

ac_reinterpretations:
  - ac: AC-N                          # string — the original AC identifier
    ambiguity: <text>                 # string — what's unclear in the original AC
    chosen_interpretation: <text>     # string — the reading we will execute against
    rationale: <text>                 # string — why this reading

adjusted_plan:
  binding_status: <text>              # string — typically "supersedes original spec for rest of WP"
  deliverables:
    - id: AD-NN                       # string — sequential within this plan
      description: <text>             # string — deliverable text
      original_spec_step: <int|null>  # int or null — null for newly added deliverables
      change_from_spec: <one of four> # enum — dropped | re-targeted | unchanged | added
      target_path: <path>             # string — file or directory the deliverable touches
      token_estimate: <text>          # string — e.g., "~5K"
  estimated_token_delta: <text>       # string — signed delta vs original, e.g., "+5K", "-10K", "0"

verification_checklist:
  - <text>                            # string — items the implementer confirms at WP end

proceed_decision: <one of three>      # enum — PROCEED | PROCEED_ADJUSTED | STOP_USER_APPROVAL
decision_rationale: <text>            # string — 1-3 sentences

roi:
  spent_tokens_estimate: <text>       # string — e.g., "~5K"
  estimated_savings: <text>           # string — e.g., "~15-25K"
  net: <one of three>                 # enum — positive | break-even | negative
  rationale: <text>                   # string — 1-3 sentences
```

---

## Field Reference

### `findings[*].category`

One of seven:
- `confirmed` — claim matches reality
- `drift-line-ref` — file correct, line off
- `drift-wrong-file` — path stale; content moved to a different path
- `drift-missing-scope` — spec lists deliverable that's a no-op
- `drift-undeclared-scope` — spec missing a deliverable real impl needs
- `ac-reinterpretation` — ambiguous AC; resolvable with documented choice
- `gap` — claim references nonexistent thing

Mirror in `step-3-categorization.md` Category Table; mirror in SKILL.md Severity Rubric.

### `findings[*].severity`

One of four:
- `LOW` — line-ref drift; doc fix in implementation comments
- `MEDIUM` — missing-scope or AC-reinterpretation; adjustable without scope expansion
- `HIGH` — wrong-file, undeclared-scope, GAP; scope-changing
- `n/a` — for confirmed findings

CRITICAL is reserved (escalates to HIGH for verdict purposes per the rubric in SKILL.md). Do not use CRITICAL unless an explicit safety/security blocker is in play.

### `findings[*].resolution`

One of five:
- `doc fix` — update spec line ref or wording in implementation comments; no plan change
- `plan adjustment` — rewrite the relevant deliverable in `adjusted_plan`
- `scope expansion` — add a new deliverable; requires HIGH severity + STOP_USER_APPROVAL
- `ask user` — defer to user via AskUserQuestion; surface in Stage 6
- `none` — for confirmed findings

### `adjusted_plan.deliverables[*].change_from_spec`

One of four:
- `dropped` — the original spec deliverable was a no-op (per DRIFT-missing-scope)
- `re-targeted` — same scope, different file path (per DRIFT-wrong-file)
- `unchanged` — original spec deliverable carried forward
- `added` — new deliverable not in original spec (per DRIFT-undeclared-scope)

### `proceed_decision`

One of three:
- `PROCEED` — all CONFIRMED; original plan stands
- `PROCEED_ADJUSTED` — only LOW + MEDIUM findings; adjusted plan binds; flag in summary
- `STOP_USER_APPROVAL` — any HIGH finding; surface to user before binding

Mirror in `step-6-decision-matrix.md`; mirror in SKILL.md Verdict Decision Matrix.

### `roi.net`

One of three:
- `positive` — estimated savings exceed spent tokens
- `break-even` — savings ≈ spent
- `negative` — overhead exceeded savings (initial runs may be negative; aggregate is what matters)

---

## Validation Rules

Before writing the log:

1. Every `findings[*]` entry has both `spec_claim` AND `actual_state` populated verbatim.
2. Every `findings[*].severity` is one of LOW / MEDIUM / HIGH (or n/a only when category=confirmed).
3. Every `findings[*].category` is one of the seven enum values.
4. Every `adjusted_plan.deliverables[*].change_from_spec` is set.
5. `proceed_decision` matches the matrix: any HIGH severity → STOP_USER_APPROVAL; only LOW+MEDIUM → PROCEED_ADJUSTED; all CONFIRMED → PROCEED.
6. `roi.net` is `positive`, `break-even`, or `negative` — no other values.

If any check fails, fix before writing — the log is binding via Stage 7 and downstream consumers parse it.

---

## Cross-References

- `step-3-categorization.md` — full taxonomy + severity decision tree
- `step-5-log-template.md` — filled-in examples of each section
- `step-6-decision-matrix.md` — verdict matrix + AskUserQuestion templates
- `templates/findings-output.yaml` — copy-pasteable YAML scaffold mirroring this schema
