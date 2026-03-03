# bulwark-issue-analyzer

Analyzes a bug or issue to identify its root cause, map its impact, and produce a structured debug report with a tiered validation plan.

## Model

Sonnet.

## Invocation guidance

**Tier 2: Skill-preferred.** Can be invoked directly, but works best through its parent skill.

The agent accepts open-ended input (an issue description, a file path, or a directory) and does not depend on artifacts from prior stages. Direct invocation is possible and produces a complete debug report. However, running it through [fix-bug](../skills/fix-bug.md) or [issue-debugging](../skills/issue-debugging.md) integrates the output with downstream stages: a fix implementer reads the debug report, and a fix validator executes the tiered test plan the analyzer produces. Standalone, those stages do not run.

**Direct invocation:**

```bash
claude -p --agent bulwark-issue-analyzer "Login endpoint returns 500. Investigate src/auth/login.ts"
claude -p --agent bulwark-issue-analyzer "Tests failing in CI. Investigate src/payments/"
```

**Via parent skills:**

```
/the-bulwark:fix-bug
/the-bulwark:issue-debugging
```

## What it does

The analyzer reads the issue description and any provided file paths, then traces the execution path from the observable symptom to the underlying root cause. It applies a 5 Whys methodology: forming and testing hypotheses systematically, using git history, test execution, and code inspection as evidence sources. It distinguishes between production bugs, test code bugs, and infrastructure failures, adjusting its investigation focus accordingly.

Once root cause is established, it maps impact across affected files, upstream callers, and downstream effects, and assigns a risk scope (isolated, medium, or broad). It then produces a tiered validation plan categorizing tests by priority (P1 must pass, P2 should pass, P3 nice-to-have) and defines confidence criteria that a downstream fix validator can use to assess whether a fix is complete.

## Output

| File | Contents |
|------|----------|
| `logs/debug-reports/{issue-id}-{timestamp}.yaml` | Root cause, fix approach, impact analysis, tiered validation plan, confidence criteria, debug journey (for medium/high complexity) |
| `logs/diagnostics/bulwark-issue-analyzer-{timestamp}.yaml` | Execution metadata: files examined, hypotheses tested, root cause found, output paths |
