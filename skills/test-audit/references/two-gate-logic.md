# Two-Gate REWRITE_REQUIRED Logic

The Test Audit pipeline determines whether automatic rewrites are required by applying two sequential gates against the audit report.

---

## Gate 1 — Impact

```
IF any P0 violations exist:
    REWRITE_REQUIRED = true
    gate_triggered = "Gate 1: Impact (P0 violations - false confidence)"
```

P0 violations represent false confidence: tests that pass but do not actually verify behavior. Any P0 forces a rewrite regardless of effectiveness scores.

---

## Gate 2 — Threshold

```
ELSE IF P1 violations exist:
    IF any file has test_effectiveness < 95%:
        REWRITE_REQUIRED = true
        gate_triggered = "Gate 2: Threshold (P1 + effectiveness < 95%)"
    ELSE:
        REWRITE_REQUIRED = false
        status = "Advisory only (P1 above 95% threshold)"
```

P1 violations are real but tolerable when the affected files still demonstrate ≥95% test effectiveness. Below the threshold, the cumulative risk justifies a rewrite.

---

## Advisory (Default)

```
ELSE (P2 only):
    REWRITE_REQUIRED = false
    status = "Advisory only (P2 pattern issues)"
```

P2 violations are pattern-level concerns surfaced for awareness. They do not gate releases.
