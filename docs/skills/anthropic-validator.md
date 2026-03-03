# anthropic-validator

Validates Claude Code assets (skills, hooks, agents, commands, MCP servers, plugins) against official Anthropic standards by fetching the latest documentation dynamically.

## Invocation and usage

```
/the-bulwark:anthropic-validator [path]
```

**Arguments:**

| Argument | Description |
|----------|-------------|
| `[path]` | Path to a single asset file or a directory. Omit to validate from context. |

**Examples:**

```
/the-bulwark:anthropic-validator skills/my-skill/SKILL.md
```

Validate a single skill definition against current Anthropic standards.

```
/the-bulwark:anthropic-validator hooks/hooks.json
```

Validate a hooks configuration file.

```
/the-bulwark:anthropic-validator skills/
```

Validate every skill in the directory. Each asset is validated individually, then results are aggregated into a batch summary.

```
/the-bulwark:anthropic-validator
```

No argument provided. The skill infers the asset from the current conversation context. If nothing can be inferred, it asks what to validate.

## Who is it for

- Plugin authors who want to confirm their skills, agents, or hooks comply with current Anthropic field requirements before shipping.
- Teams who have assets created across multiple sessions and want to catch drift from evolving standards.
- Anyone using `create-skill` or `create-subagent` and wanting an independent compliance check before using the generated asset in production.

## How it works

The skill follows a two-agent pipeline for every asset.

**Step 1: Fetch latest standards.** The `claude-code-guide` agent retrieves the relevant Anthropic documentation page for the detected asset type (skill, hook, agent, command, MCP server, or plugin). This keeps validation current. It does not rely on embedded checklists unless the fetch fails, in which case it falls back to reference files in `references/` and notes the fallback in the report.

**Step 2: Critical analysis.** The `bulwark-standards-reviewer` agent reads the asset content against the fetched standards. It checks every required and optional field, verifies that any files referenced in the asset actually exist, and rates each finding by severity: Critical, High, Medium, or Low. It writes a structured YAML report to `logs/validations/`.

After both agents complete, the orchestrator presents a human-readable summary with the verdict (PASS or FAIL), a count of findings by severity, and the path to the full report. FAIL is triggered by any Critical finding. All findings are listed regardless of verdict.

**Batch mode.** When a directory is passed, each asset is validated separately with full depth. Results are aggregated into a `logs/validations/batch-summary-{timestamp}.yaml` file listing pass/fail per asset.

## Output

| File | Contents |
|------|----------|
| `logs/validations/{asset-name}-{timestamp}.yaml` | Structured findings with severity, rule, violation, location, and remediation for each issue |
| `logs/validations/batch-summary-{timestamp}.yaml` | Aggregate pass/fail summary across all assets (batch mode only) |
| `logs/diagnostics/anthropic-validator-{timestamp}.yaml` | Pipeline execution metadata: asset type detected, standards fetch result, agent outputs, verdict |
