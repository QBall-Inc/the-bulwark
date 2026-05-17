# Commands Validation

Per-asset-type workflow + validation points for **commands**. Loaded by `anthropic-validator` SKILL.md Step 1 routing when `asset_type == "command"`.

**Note**: Commands and skills merged in Claude Code v2.1.3. New commands should typically be created as user-invocable skills.

---

## Official Documentation

https://docs.anthropic.com/en/docs/claude-code/skills (commands merged with skills in v2.1.3)

---

## Validation Workflow

1. Read the command file
2. Spawn `claude-code-guide` with prompt:
   ```
   Fetch current standards for Claude Code commands/skills from https://docs.anthropic.com/en/docs/claude-code/skills
   Focus on: command invocation, argument passing ($ARGUMENTS, $1, $2), user-invocable field
   Note: Commands and skills merged in v2.1.3
   ```
3. Spawn `bulwark-standards-reviewer` with command content and fetched standards
4. Write report to `logs/validations/` (include top-level `reviewed_files: [...]` per the schema in `SKILL.md` Output Format — Stop-hook contract)

---

## Key Validation Points

| Aspect | Requirement |
|--------|-------------|
| Invocation | `/skill-name arg1 arg2` |
| Arguments | `$ARGUMENTS` (all), `$1`/`$2` (positional) |
| Environment | `${ENV_VAR}` for environment variables |
| Visibility | `user-invocable: true` for `/` menu |

---

## Fallback Checklist

If doc fetch fails, use: `references/commands-checklist.md`
