# Skills Validation Checklist (Fallback)

This checklist is used when dynamic documentation fetch fails. May be outdated - prefer fetched standards.

**Last Updated**: 2026-04-26

---

## Frontmatter Requirements

### Anthropic-Official Fields (15 total)

All skill frontmatter fields are technically optional per the Anthropic spec. `description` is explicitly recommended so the model knows when to use the skill.

| Field | Type | Description |
|-------|------|-------------|
| `name` | string (lowercase, ≤64 chars) | Skill name; if absent, matches directory name |
| `description` | string | Concise explanation of skill purpose (recommended) |
| `when_to_use` | string | Guidance for auto-invocation |
| `argument-hint` | string | Display hint for arguments |
| `arguments` | string or YAML list | Argument schema (space-separated string or list) |
| `disable-model-invocation` | boolean | `true` blocks auto-invocation but keeps `/skill-name` working |
| `user-invocable` | boolean | `true` to show in `/` menu, `false` to hide |
| `allowed-tools` | string or YAML list | **Pre-authorizes** listed tools (skips approval prompts); does NOT restrict tool availability (NOT `tools`) |
| `disallowed-tools` | string or YAML list | **Restriction field for SKILLS**: removes tools from the available pool while the skill is active (clears on next message) |
| `model` | string | `haiku`, `sonnet`, `opus` |
| `agent` | string | Subagent name to delegate to |
| `effort` | enum | `low`, `medium`, `high`, `xhigh`, `max` |
| `context` | `fork` | Isolated execution context |
| `hooks` | YAML object | Skill-scoped hooks |
| `paths` | string or YAML list | Path-based auto-activation |
| `shell` | `bash` or `powershell` | Shell selection |

**`tools` vs `allowed-tools`**:
- Skills: the official field is `allowed-tools`. `tools:` in SKILL.md is **not official** → flag as HIGH violation.
- Agents: the official field is `tools`. (See `agents-checklist.md`.)

### Bulwark-Adopted Fields (informational notes, not violations)

These fields are non-Anthropic-official but intentionally standardized across Bulwark assets. They appear in the validator's `bulwark_adopted_fields` report section and do not count against the verdict.

| Field | Type | Description |
|-------|------|-------------|
| `version` | string | Semver string for traceability (e.g., `1.0.0`). Default for new skills via `create-skill`. |
| `author` | string | Attribution. First-party Bulwark uniform: `"Ashay Kubal @ Qball Inc."` |
| `skills` | array | Cross-skill dependency declaration. **Note**: `skills:` IS official for *agent* frontmatter; for *skill* frontmatter it is bulwark-adopted (documentary only — Anthropic parser ignores it). |

Any frontmatter field not in either of the above tables is `unknown` and remains a HIGH-severity violation.

---

## File Structure

### Required

- `SKILL.md` in `skills/{skill-name}/` directory
- Name in frontmatter matches directory name

### Optional

- `references/` subdirectory for supporting files
- Additional markdown files for sections

---

## Content Guidelines

### Critical Rules

- [ ] Frontmatter is valid YAML between `---` markers
- [ ] `name` field matches directory name exactly
- [ ] `description` field is present and non-empty
- [ ] SKILL.md is under 500 lines (recommended)

### High Priority

- [ ] `user-invocable` is boolean if present
- [ ] `agent` is one of: `haiku`, `sonnet`, `opus` if present
- [ ] `context` is `fork` if present (no other values)
- [ ] `skills` is array of strings if present
- [ ] `tools` is array of valid tool names if present

### Medium Priority

- [ ] Description explains when to use the skill
- [ ] Clear section structure with headers
- [ ] Examples provided where appropriate

### Low Priority

- [ ] Consistent formatting
- [ ] No dead links in references
- [ ] Related skills section included

---

## Common Violations

| Violation | Severity | Remediation |
|-----------|----------|-------------|
| Missing `name` | Critical | Add `name: skill-name` to frontmatter |
| Missing `description` | Critical | Add `description: ...` to frontmatter |
| Name mismatch | Critical | Ensure name matches directory |
| Invalid `agent` value | High | Use `haiku`, `sonnet`, or `opus` |
| Non-boolean `user-invocable` | High | Use `true` or `false` |
| Missing frontmatter | Critical | Add `---` markers with YAML |
