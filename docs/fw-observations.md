# Framework Observations

Items identified during development that affect the broader framework. Not blocking current work - to be revisited after framework development is complete.

**Identifiers:**
- `FW-OBS-xxx` - Observations (potential issues, naming discrepancies)
- `FW-ENH-xxx` - Enhancements (framework-wide improvements)

---

## Open Observations

### FW-OBS-001: `tools` vs `allowed-tools` in skill frontmatter

**Identified:** Session 43 (2026-02-07)
**Source:** anthropic-validator run on subagent-output-templating; WebFetch of official docs
**Severity:** Low (functional, naming discrepancy)
**Status:** Open

**Finding:** Official Anthropic docs (https://code.claude.com/docs/en/skills) list `allowed-tools` as the supported frontmatter field for restricting tool access in skills. The Bulwark project uses `tools:` instead.

**Affected Skills:**
- `skills/bulwark-statusline/SKILL.md` (line 5: `tools:`)
- No other skills use either `tools:` or `allowed-tools:`

**Also noted in agents:**
- Agent frontmatter uses `tools:` which IS the documented field name for agents
- This discrepancy is skills-only

**Risk:** Low. `tools:` may work as an undocumented alias, or the official docs may have renamed the field. Functional behavior appears unaffected.

**Action:** After framework development is complete, verify whether `tools:` and `allowed-tools:` are interchangeable in skill frontmatter. If not, update `bulwark-statusline` and the fallback checklist at `skills/anthropic-validator/references/skills-checklist.md`.

---

### FW-OBS-002: `skills` dependency field undocumented for skills

**Identified:** Session 43 (2026-02-07)
**Source:** anthropic-validator run; WebFetch of official docs
**Severity:** Informational (works in practice)
**Status:** Acknowledged - no action needed

**Finding:** The official skills frontmatter reference table does not list `skills:` (dependency array) as a supported field for skills. It IS documented for sub-agents. However, multiple Bulwark skills use `skills:` in frontmatter and it works correctly in practice (loads dependency skill content into context).

**Affected Skills:** Multiple (code-review, test-audit, anthropic-validator, etc.)

**Decision:** Empirically validated, keep using. The feature likely exists but is undocumented, or was added after the docs snapshot. No action required.

---

### FW-OBS-003: claude-code-guide agent fails to fetch official docs for skills

**Identified:** Session 43 (2026-02-07)
**Source:** anthropic-validator sequential validation runs
**Severity:** Medium (requires manual fallback)
**Status:** Open - needs fix in anthropic-validator

**Finding:** The `claude-code-guide` agent (built-in Claude Code agent) behaves inconsistently when fetching official documentation:

- **Agents docs** (https://docs.anthropic.com/en/docs/claude-code/sub-agents): Fetched correctly. Returned comprehensive, accurate standards data from official source.
- **Skills docs** (https://docs.anthropic.com/en/docs/claude-code/skills): Failed to fetch. Instead of accessing the URL, the agent read local project files and presented project-specific patterns as "official standards." Output contained phrases like "Your project confirms these" and incorrectly stated `tools:` is "NOT DOCUMENTED" for skills.

**Impact:** When the agent fails, the anthropic-validator skill must fall back to:
1. Existing references (`references/skills-checklist.md`)
2. WebFetch on official docs (URL redirects from docs.anthropic.com to code.claude.com/docs/en/skills)

This fallback works but is manual - the orchestrator must detect the failure and execute the fallback steps. The anthropic-validator skill's current fallback section covers this scenario but doesn't automate detection of "agent read local files instead of fetching docs."

**Root Cause (suspected):** The claude-code-guide agent may have inconsistent behavior depending on URL routing, caching, or whether the docs site returns a redirect. The skills URL redirects (301) from `docs.anthropic.com` to `code.claude.com` which may confuse the agent.

**Action:** Update anthropic-validator skill to:
1. Add explicit instructions for detecting unreliable claude-code-guide output (look for phrases like "Your project confirms", "Based on your architecture", or references to local file paths)
2. Add automatic fallback trigger when detection fires
3. Document the WebFetch redirect: `docs.anthropic.com` → `code.claude.com/docs/en/skills`

---

### FW-OBS-004: Rules.md token cost — split rules from reasoning

**Identified:** Session 45 (2026-02-08)
**Source:** User observation during P4.4 testing
**Severity:** Medium (token efficiency)
**Status:** Open

**Finding:** `Rules.md` includes both the rules themselves and the reasoning/justification behind each rule. Every session loads the full file, consuming tokens on explanatory text that the model doesn't need every time. The file has grown to ~300 lines.

**Proposed Fix:**
1. Slim `Rules.md` to rules-only: concise, mandatory, no-ambiguity language
2. Create `docs/rules-reasoning.md` with the justifications, examples, and rationale
3. `Rules.md` references `docs/rules-reasoning.md` for human consumption but doesn't require it be loaded

**Benefit:** Reduced per-session token consumption. Rules remain binding. Reasoning available for human reference and future sessions where context is needed.

**Action:** Implement during a future cleanup pass (not during active P4 testing).

---

### FW-OBS-005: Justfile `test` recipe has no jest backend

**Identified:** Session 45 (2026-02-08)
**Source:** P4.4-3 manual testing — agent attempted `just test`, failed, fell back to `npx jest`
**Severity:** Low (workaround exists, not blocking)
**Status:** Open

**Finding:** The Justfile `test` recipe exists but has no actual jest runner configured behind it. When the bulwark-implementer agent calls `just test`, it fails. The agent then falls back to `npx jest` directly, which works but bypasses the `just` abstraction required by V2.

**Impact:** Agents that follow V2 (`just test` not `npx jest`) will hit a failure on first attempt. Self-correcting agents recover by trying `npx jest`, but this is an unnecessary retry and violates the principle that `just` commands should work.

**Action:** Configure the Justfile `test` recipe with a working jest backend. Ensure `just test` runs jest successfully without fallback.
