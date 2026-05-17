# Step 3 — Categorization

## Purpose

For every Stage 2 verification result, assign:

1. A **category** — what kind of drift (or non-drift) is this?
2. A **severity** — how much does it block?
3. A **decision implication** — what does the orchestrator do about it?

Categorization is the bridge from raw verification evidence to the verdict. The category dictates how Stage 4 rewrites the plan; the severity dictates whether Stage 6 emits PROCEED, PROCEED_ADJUSTED, or STOP_USER_APPROVAL.

---

## Category Table

| Category | Definition | Severity | Example | Decision Implication |
|----------|------------|----------|---------|----------------------|
| **CONFIRMED** | Claim matches reality (Stage 2 returned exact verbatim match) | n/a | Spec says `coverage_check.py:88`; Read at line 88 shows the asserted content. | No action; carry the original plan forward |
| **DRIFT — line-ref** | File correct; content has moved to a different line OR a literal value off by a small amount | LOW | Spec says line 88; actual content is at line 91 (file is otherwise unchanged). | Doc fix in implementation comments; PROCEED_ADJUSTED |
| **DRIFT — wrong file** | File path stale; content lives at a different path | HIGH | Spec says `scripts/hooks/foo.sh`; actual file is `scripts/foo.sh`. | STOP_USER_APPROVAL — wrong-file drifts often signal larger refactors the spec doesn't reflect |
| **DRIFT — missing scope** | Spec lists deliverable X but X is a no-op (already done, or no longer needed) | MEDIUM | Spec says "add X function"; X already exists at the asserted path with the asserted shape. | Drop the deliverable; PROCEED_ADJUSTED |
| **DRIFT — undeclared scope** | Spec missing a deliverable that real implementation requires | HIGH | Spec says "modify A"; modifying A safely also requires modifying B (uncovered by spec). | STOP_USER_APPROVAL — scope expansion needs sign-off |
| **AC re-interpretation** | Acceptance criterion is ambiguous; can resolve against current code with documented choice | MEDIUM | Spec says "update the schema"; current code has two schemas; AC is unclear which one. | Resolve explicitly with rationale; PROCEED_ADJUSTED |
| **GAP** | Claim references a thing that does not exist anywhere | HIGH | Spec says `parseFooBar()`; no such function in the repo. | STOP_USER_APPROVAL — the spec is referencing fiction |

---

## Severity Decision Tree

Use this tree when a finding is borderline. The tree maps **finding shape** → **severity tier** deterministically.

```
Is the claim CONFIRMED (verbatim match)?
├── YES → category=CONFIRMED, severity=n/a, no decision impact
└── NO → drift exists; continue
    │
    Does the claim reference a file path?
    ├── YES → does the file exist at the asserted path?
    │   ├── YES (file ok, content drift only)
    │   │   └── Is the content at a different line in the SAME file?
    │   │       ├── YES → DRIFT-line-ref, severity LOW
    │   │       └── NO  → content gone or wrong → GAP or DRIFT-wrong-file (case below)
    │   └── NO (file path wrong)
    │       └── Does similar content exist at a DIFFERENT path?
    │           ├── YES → DRIFT-wrong-file, severity HIGH
    │           └── NO  → GAP, severity HIGH
    │
    Does the claim reference a deliverable / scope item?
    ├── Is the deliverable a no-op (already done)?
    │   └── YES → DRIFT-missing-scope, severity MEDIUM
    ├── Does completing the spec REQUIRE additional work the spec didn't list?
    │   └── YES → DRIFT-undeclared-scope, severity HIGH
    │
    Is the claim ambiguous (multiple plausible readings against current code)?
    ├── YES → AC re-interpretation, severity MEDIUM (must document chosen reading)
    │
    Does the claim reference a function/symbol/value that does not exist anywhere?
    └── YES → GAP, severity HIGH
```

**Tie-breaker rules**:
- When in doubt between LOW and MEDIUM, choose **MEDIUM** (you can downgrade in Stage 4 if it's truly trivial; you can't upgrade after the verdict ships).
- When in doubt between MEDIUM and HIGH, choose **HIGH** (the user should see the finding; over-stopping is recoverable, under-stopping ships bad work).
- CRITICAL is reserved (the rubric in SKILL.md notes it escalates to HIGH for verdict purposes). Do not use CRITICAL unless an explicit safety/security concern is in play; otherwise, HIGH is the top tier.

---

## Severity Tier Reference

| Severity | Definition | Verdict Implication |
|----------|------------|---------------------|
| **CRITICAL** | Reserved — used only for explicit safety/security blockers; escalates to HIGH for verdict purposes | STOP_USER_APPROVAL |
| **HIGH** | Wrong-file DRIFT, undeclared-scope DRIFT, GAP — scope-changing or block-level | STOP_USER_APPROVAL |
| **MEDIUM** | Missing-scope DRIFT, AC re-interpretation — adjustable without scope expansion | PROCEED_ADJUSTED |
| **LOW** | Line-ref DRIFT — file correct, line off | PROCEED_ADJUSTED (doc fix in implementation comments) |

This tier table is mirrored in SKILL.md. If you change one, change both (cross-file consistency).

---

## Output Format Per Finding

Each finding from Stage 3 carries:

```yaml
- id: D-NN                  # sequential within this run
  claim_id: C-NN            # back-reference to the Stage 1 claim
  category: confirmed | drift-line-ref | drift-wrong-file | drift-missing-scope | drift-undeclared-scope | ac-reinterpretation | gap
  severity: LOW | MEDIUM | HIGH      # n/a for CONFIRMED
  spec_claim: "<verbatim quote from spec>"
  actual_state: "<verbatim evidence from Stage 2>"
  resolution: "<doc fix | plan adjustment | scope expansion | ask user | none>"
```

Multiple findings can map to a single claim if the claim has compound assertions (e.g., "the function `foo` at `bar.ts:42`" yields one finding for the function name and one for the line ref).

---

## Anti-Pattern Reminders for This Stage

- Do NOT mark a finding CONFIRMED based on recall. Stage 2 evidence must be verbatim.
- Do NOT skip the severity field. Severity drives the verdict; an unsevered finding is invisible to Stage 6.
- Do NOT invent new categories. The 7 categories above cover all observed drift shapes; extending the taxonomy mid-run breaks downstream consumers (Stage 6 decision matrix and the YAML schema).
- Do NOT auto-downgrade HIGH → MEDIUM to "save the user a question". HIGH is HIGH because the orchestrator cannot proceed without a sign-off.
