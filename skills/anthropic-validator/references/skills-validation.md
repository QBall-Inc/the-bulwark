# Skills Validation

Per-asset-type workflow + validation points for **skills** (`SKILL.md` files). Loaded by `anthropic-validator` SKILL.md Step 1 routing when `asset_type == "skill"`.

---

## Official Documentation

- **Canonical**: https://code.claude.com/docs/en/skills (preferred — authoritative)
- **Alternate**: https://docs.anthropic.com/en/docs/claude-code/skills (redirects to canonical)

---

## Validation Workflow

1. Read the skill's `SKILL.md` file
2. **Check for supporting subdirectories**:
   - `references/` — list files if present (OPTIONAL — not all skills need this)
   - `examples/`, `scripts/`, `templates/`, `data/` — list if present
3. **Verify referenced files** — scan SKILL.md for file mentions (`references/*.md`, etc.) and confirm they exist
4. Spawn `claude-code-guide` with prompt:
   ```
   Fetch current standards for Claude Code skills from https://code.claude.com/docs/en/skills
   Focus on: frontmatter fields, SKILL.md structure, user-invocable, agent field, context field
   ```
5. Spawn `bulwark-standards-reviewer` with:
   - Skill content
   - Fetched standards
   - **Supporting files inventory** (list of files in references/, examples/, etc.)
   - **Referenced files verification** (which mentioned files exist/missing)
6. Write report to `logs/validations/` (include top-level `reviewed_files: [...]` per the schema in `SKILL.md` Output Format — Stop-hook contract)

**Important**: A missing `references/` folder is NOT a violation unless the skill explicitly references files that don't exist. Many skills are self-contained and don't need supporting files.

---

## Key Validation Points

### Anthropic-Official Fields (15 total — Last verified 2026-04-26)

| Field | Type | Requirement |
|-------|------|-------------|
| `name` | string (lowercase, ≤64 chars) | Optional; if absent, matches directory name |
| `description` | string | Recommended (Anthropic explicitly recommends this so the model knows when to use the skill) |
| `when_to_use` | string | Optional — guidance for auto-invocation |
| `argument-hint` | string | Optional — display hint for arguments |
| `arguments` | space-separated string OR YAML list | Optional — argument schema |
| `disable-model-invocation` | boolean | Optional — `true` blocks auto-invocation but keeps `/` invocation working |
| `user-invocable` | boolean | Optional — controls `/` menu visibility |
| `allowed-tools` | space-separated string OR YAML list | Optional — **pre-authorizes** the listed tools (skips approval prompts while the skill is active); does NOT restrict which tools are available (NOT `tools`; that field is for AGENTS) |
| `disallowed-tools` | space-separated/comma string OR YAML list | Optional — **the actual tool-restriction field for SKILLS**: removes the listed tools from Claude's available pool while the skill is active (restriction clears on the next user message) |
| `model` | string | Optional — `haiku`, `sonnet`, `opus` |
| `agent` | string (subagent name) | Optional — delegate to a named subagent |
| `effort` | enum: `low`, `medium`, `high`, `xhigh`, `max` | Optional — model effort level |
| `context` | `fork` | Optional — isolated execution context |
| `hooks` | YAML object | Optional — skill-scoped hooks |
| `paths` | comma-separated string OR YAML list | Optional — path-based auto-activation |
| `shell` | `bash` or `powershell` | Optional — shell selection |

**Sources**: https://code.claude.com/docs/en/skills (canonical) / https://docs.anthropic.com/en/docs/claude-code/skills (redirects to canonical).

**Important — `tools` vs `allowed-tools`**:
- For **skills** (`SKILL.md`): the official field is `allowed-tools`. `tools:` in SKILL.md is **not official** and should be flagged as `unknown` (HIGH violation) — recommend migration to `allowed-tools:`.
- For **agents** (`agents/*.md`): the official field is `tools` (per https://docs.anthropic.com/en/docs/claude-code/sub-agents). Do NOT flag `tools:` in agent frontmatter.

### Bulwark-Adopted Fields (informational notes, not violations)

| Field | Notes |
|-------|-------|
| `version` | Semver string. Defaults to `1.0.0` for new skills via `create-skill`. |
| `author` | Attribution string. Uniform `"Ashay Kubal @ Qball Inc."` for first-party Bulwark assets. |
| `skills` | Cross-skill dependency declaration. Adopted for skill frontmatter; documentary only (Anthropic parser ignores unknown fields). |

See "Bulwark-Adopted Fields Allowlist" section in main SKILL.md for full classification rules.

---

## Fallback Checklist

If doc fetch fails, use: `references/skills-checklist.md`
