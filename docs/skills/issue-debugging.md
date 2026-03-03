# issue-debugging

Systematic debugging methodology that guides root cause analysis, impact mapping, tiered validation planning, and confidence assessment.

## Invocation and usage

This skill is not invoked directly. It is loaded as a reference by the `bulwark-issue-analyzer` and `bulwark-fix-validator` agents via the `skills` dependency field. You engage it indirectly through `/the-bulwark:fix-bug`.

If you want to use the methodology outside of a pipeline, reference the skill explicitly in your session:

```
/the-bulwark:issue-debugging
```

Then describe the issue. The skill instructs Claude to follow the full debugging protocol.

**Example scenarios it handles:**

```
/the-bulwark:issue-debugging
"Login fails with a 500 error for new accounts created after the migration"
```

```
/the-bulwark:issue-debugging
"Tests pass locally but CI fails on the auth module"
```

```
/the-bulwark:issue-debugging
"Cart total shows NaN when a discount code is applied twice — this regressed after the pricing refactor"
```

## Who is it for

- Developers who want a structured protocol before reaching for a fix, especially on medium or high-complexity bugs.
- Teams debugging regressions where the root cause is unclear and impact needs mapping before anything changes.
- Anyone who has been burned by "fixed the symptom, missed the cause" and wants a repeatable methodology to prevent it.

## How it works

The skill walks through five areas in order.

**Root cause analysis.** Uses the 5 Whys method to drill past the point of failure to the underlying cause. Hypothesis-driven debugging applies: form a falsifiable hypothesis, test it, document the result, and move to the next if rejected. This prevents circular investigation and builds an evidence trail.

**Impact mapping.** For each affected file, traces upstream callers and downstream consumers. Assigns a risk scope: isolated (unit tests only), medium (integration tests), or broad (integration, E2E, and manual testing required).

**Validation planning.** Produces a tiered test list. P1 tests are direct tests of the affected function and always run. P2 tests cover upstream and downstream callers and run when time and tokens allow. P3 tests cover E2E flows and edge cases. Beyond tests, the plan lists user-level verifications, such as "user can log in successfully."

**Confidence assessment.** After validation, assigns HIGH, MEDIUM, or LOW confidence based on which test tiers passed and whether any functionality went unverified.

**Escalation.** When confidence is LOW, risk scope is broad, or any functionality cannot be validated automatically, the skill emits a structured escalation message with recommended manual test steps.

Debug reports are written to `logs/debug-reports/{issue-id}-{timestamp}.yaml`. The schema captures symptom, root cause, fix approach, impact analysis, validation plan, confidence criteria, and (for medium and high complexity) a full debug journey with each hypothesis tested and rejected.
