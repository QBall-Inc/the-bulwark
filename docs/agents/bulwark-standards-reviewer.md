# bulwark-standards-reviewer

Analyzes a Claude Code asset against official Anthropic standards and produces a severity-rated validation report.

## Model

Sonnet.

## Invocation guidance

**Tier 3 — Pipeline-only.** Not recommended for standalone use.

The agent receives its asset path and standards as structured inputs from the orchestrating skill. Without that context, there is no target to analyze. Invoke the parent skill instead:

```
/the-bulwark:anthropic-validator <path-to-asset>
```

See the [anthropic-validator](../skills/anthropic-validator.md) skill for full usage. This agent is also used within the [fix-bug](../skills/fix-bug.md) and code-review pipelines when those pipelines include a standards check stage.

## What it does

Given an asset file and the relevant Anthropic standards, the agent checks each applicable rule in order, rates any violation by severity (Critical, High, Medium, or Low), and records a specific remediation for each finding. A verdict of PASS or FAIL is determined by whether any Critical findings exist.

Asset types covered: skills, hooks, agents, commands, MCP servers, and plugins. For each type, the agent applies a dedicated checklist covering required fields, valid values, file locations, and structural constraints.

## Output

Two files are written on every run. Filenames include a timestamp in ISO-8601 format with hyphens for filesystem safety (e.g., `2026-01-17T10-30-00`).

| File | Contents |
|------|----------|
| `logs/validations/{asset-name}-{timestamp}.yaml` | Full validation report: all findings with severity, rule, violation description, location, and remediation. Includes a summary block with finding counts and the PASS/FAIL verdict. |
| `logs/diagnostics/bulwark-standards-reviewer-{timestamp}.yaml` | Execution metadata: asset analyzed, asset type, whether standards were provided, finding count, verdict, and report path. |
