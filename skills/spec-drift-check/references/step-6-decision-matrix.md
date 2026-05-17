# Step 6 — Decision Matrix

## Purpose

Map the **mix of findings** from Stage 3 to a verdict. The verdict is one of three values:

- **PROCEED** — original plan stands; no adjustments needed.
- **PROCEED_ADJUSTED** — adjusted plan in the verification log supersedes the original; flag in summary; no user gate.
- **STOP_USER_APPROVAL** — surface findings to the user via AskUserQuestion; do NOT bind the adjusted plan until the user signs off.

---

## Decision Matrix

| Finding mix | Verdict | Rationale |
|-------------|---------|-----------|
| All CONFIRMED | **PROCEED** | The spec is in alignment with current code; no plan rewrite needed. |
| Only LOW + MEDIUM findings | **PROCEED_ADJUSTED** | Drift exists but is contained; the adjusted plan resolves it without scope changes. |
| Any HIGH finding | **STOP_USER_APPROVAL** | Scope changes, wrong-file drift, GAPs, or undeclared-scope additions need explicit user sign-off. |

Reading order: **HIGH wins**. If the run produces 30 LOW findings and 1 HIGH, the verdict is STOP_USER_APPROVAL. The matrix is not a vote count.

---

## Tie-Breaking

The matrix above resolves cleanly — there are no genuine ties. Two situations that look like ties:

- **All CONFIRMED + a single AC-reinterpretation MEDIUM** → still PROCEED_ADJUSTED. The ambiguity must be resolved in the log; that resolution is binding via Stage 7.
- **Mostly CONFIRMED + a borderline finding (LOW vs MEDIUM)** → choose MEDIUM (per `step-3-categorization.md` tie-breaker). Verdict stays PROCEED_ADJUSTED in either case.

---

## STOP_USER_APPROVAL Escalation

When the verdict is STOP_USER_APPROVAL, the orchestrator must:

1. **Write the verification log first** (Stage 5). The log is the source of truth; the user reviews from it.
2. **Surface each HIGH finding individually** to the user via AskUserQuestion. Do NOT batch HIGH findings into a single yes/no — the user must adjudicate each.
3. **Propose an adjusted scope** for each HIGH finding: drop the deliverable / add the deliverable / re-target the path / clarify the AC.
4. **Wait for user input** before binding the adjusted plan via Stage 7. Do NOT proceed to implementation.

### AskUserQuestion Template

Use this fragment, customized per finding. One AskUserQuestion call per HIGH finding (or per logically-coupled group of findings).

```text
question: "spec-drift-check found HIGH-severity drift in {spec-path}. Approve scope adjustment?"

multiSelect: false

header: "Spec Drift — HIGH ({finding-id})"

options:
  - label: "Approve adjusted scope"
    description: |
      Finding {D-NN} ({category}): {short summary}.
      Spec claim: "{verbatim spec quote, truncated to ~120 chars}"
      Actual state: "{verbatim actual quote, truncated to ~120 chars}"
      Proposed adjustment: {proposed adjustment in 1-2 sentences}
      Token-budget impact: {+NK | -NK | 0}

  - label: "Reject adjustment — keep original spec"
    description: |
      Implementation will follow the original spec verbatim despite the drift.
      The orchestrator will document the override in the verification log.

  - label: "Need more detail"
    description: |
      Open the verification log at logs/spec-verify-{session}-{topic}.md and
      review finding {D-NN} in full before deciding.
```

### Worked AskUserQuestion Example

For a hypothetical D-02 (DRIFT-undeclared-scope: `set -e` audit task missing from spec):

```text
question: "spec-drift-check found HIGH-severity drift in plans/task-briefs/P10.16-...md. Approve scope adjustment?"

multiSelect: false

header: "Spec Drift — HIGH (D-02)"

options:
  - label: "Approve adjusted scope"
    description: |
      Finding D-02 (drift-undeclared-scope): the test plan implicitly requires
      a set -e audit per process_test_harness_set_e_pattern.md, which the spec
      does not mention.
      Spec claim: "Add 5 test cases to test-suggest-pipeline-stop.sh."
      Actual state: "Harness uses set -euo pipefail; new tests must use the
      assertion-counter pattern, not naive expect-fail."
      Proposed adjustment: add a Step 3a "audit set -e + counter pattern"
      task before adding test cases.
      Token-budget impact: +1K

  - label: "Reject adjustment — keep original spec"
    description: |
      Implementation will follow the original spec verbatim. The orchestrator
      will document the override in the verification log.

  - label: "Need more detail"
    description: |
      Open the verification log at logs/spec-verify-122-P10.16.md and
      review finding D-02 in full before deciding.
```

---

## Procedure: STOP and Surface

When the verdict fires STOP_USER_APPROVAL, follow this exact sequence:

1. **Stage 5 log written.** Confirm the log file exists and contains every HIGH finding with both `spec_claim` and `actual_state` populated verbatim.
2. **List each HIGH finding** to the user in the orchestrator's text response. Format: `D-NN ({category}, severity HIGH): {one-line summary}`. This gives the user a quick scan before the AskUserQuestion fires.
3. **Propose adjusted scope** in the same text response. One bullet per HIGH finding.
4. **Fire AskUserQuestion** per HIGH finding (in the next assistant message). Use the template above.
5. **Wait for the response** to each AskUserQuestion before proceeding. Do NOT chain multiple AskUserQuestion calls in parallel — sequential adjudication is intentional.
6. **Bind the adjusted plan (Stage 7)** only after every HIGH finding has an explicit user decision recorded in the log.

If the user rejects an adjustment, document the rejection in the log under `decision_rationale:` and either:
- Carry the original spec deliverable forward unchanged (and accept the implementation risk), OR
- Defer the entire WP back to the user for spec revision.

---

## Decision Rationale Field

Every verdict — even PROCEED — should populate `decision_rationale:` in the log with a 1-3 sentence summary. Examples:

- **PROCEED**: "All 23 claims CONFIRMED. Spec aligns with current code; no adjustments needed."
- **PROCEED_ADJUSTED**: "5 LOW findings (line-ref drift), 2 MEDIUM (1 missing-scope, 1 AC-reinterpretation). Adjusted plan drops the no-op deliverable and resolves AC-3 explicitly. No scope changes."
- **STOP_USER_APPROVAL**: "1 HIGH finding (D-02, drift-undeclared-scope: set -e audit). Surface to user before binding adjusted plan."

The rationale becomes part of the audit trail; downstream sessions read it to understand why this WP's plan was rewritten.
