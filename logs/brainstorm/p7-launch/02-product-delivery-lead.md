---
role: product-delivery-lead
topic: "P7.1 Launch: Plugin Manifest, Initialization, and Distribution"
recommendation: proceed
key_findings:
  - "Init must solve two distinct user problems: plugin install (solved by /plugin marketplace add + claude plugin install) and project configuration (requires init.sh); these must not be conflated"
  - "The minimum viable init is mandatory-only: governance files to .claude/rules/ + CLAUDE.md injection; LSP, Justfile, statusline are all recommended/optional and should be delegated not absorbed"
  - "AC17 cleanup is a correctness gap (unbounded log growth) but low user impact on day 1 — defer from P7.1 mandatory scope, ship as optional enhancement"
  - "Test agents (code-analyzer, file-counter) shipping in .claude/agents/ is the highest-severity distribution risk — exposes internal tooling to users with no benefit"
  - "Delegate pattern (init calls bulwark-scaffold, init offers setup-lsp) has better ROI than absorb pattern — avoids duplication, lets each skill evolve independently"
---

# P7.1 Launch — Product & Delivery Lead

## Summary

P7.1 is fundamentally a packaging and user onboarding problem. The plugin structure is ~90% complete; the remaining 10% is init orchestration, agent cleanup, and a handful of manifest metadata gaps. The highest-value work is a clean, guided init.sh that separates mandatory governance setup from optional enhancements, and the highest-risk gap is test agents shipping in the production agent directory. Distribution via GitHub marketplace is confirmed as the correct and only required channel; homebrew is out of scope for v1.

---

## Detailed Analysis

### User Value & Prioritization

**Who benefits and how?**

The Bulwark's core value proposition — transforming stochastic AI output into deterministic, engineering-grade artifacts — is fully built. P7.1 is about making that value accessible to a new user in under 5 minutes, from zero to enforced governance.

The user journey has three moments of value:

1. **Discovery**: Plugin listed in marketplace, README communicates the "why" clearly
2. **Installation**: `claude plugin install the-bulwark` works, hooks activate, skills appear in `/` menu
3. **Configuration**: init.sh copies governance files to user's project, hooks start enforcing quality

Current state: Moments 1 and 2 are nearly complete (plugin.json valid, hooks.json correctly structured). Moment 3 requires the init pipeline work.

**Prioritization within P7.1:**

| Feature | User Impact | Effort | Priority |
|---------|------------|--------|----------|
| Remove test agents from distribution | High (correctness) | Trivial | P0 — do first |
| CN1/CN2 sync to lib/templates/rules.md | High (correctness) | Trivial | P0 — do first |
| init.sh mandatory steps (rules + CLAUDE.md) | Critical | Low | Mandatory |
| CN rules split for LSP conditional inclusion | High | Low | Mandatory |
| hooks.json timeout correction (60000→60) | Medium | Trivial | Mandatory |
| plugin.json marketplace metadata | Medium | Trivial | Mandatory |
| init.sh optional steps (LSP delegation, Justfile delegation) | High value for adopters | Low (delegation pattern) | Recommended |
| AC17 cleanup script | Medium (operational) | Medium | Optional — defer from P7.1 |
| init.sh statusline delegation | Low | Low | Optional |

### Scope Boundaries (v1 vs Deferred)

**v1 MANDATORY (must ship for P7.1 to be complete):**

1. Remove `code-analyzer.md` and `file-counter.md` from `.claude/agents/` before distribution
2. Sync CN1/CN2 from `Rules.md` to `lib/templates/rules.md`
3. Split CN rules into `lib/templates/cn-rules.md` for conditional inclusion
4. Update `init-rules.sh` target path from `$TARGET/Rules.md` to `$TARGET/.claude/rules/rules.md`
5. Create `scripts/init.sh` that orchestrates the mandatory steps in order
6. Correct hooks.json timeout values (60000→60, 30000→30, 5000→5) — confirmed as seconds per Session 85
7. Add marketplace metadata to `plugin.json` (repository, homepage, license, keywords)
8. Document first-run hook failure (GitHub #10997): user must restart session after plugin install

**v1 RECOMMENDED (init.sh optional steps, high value but not blocking):**

9. init.sh offers LSP setup: delegates to `setup-lsp` skill, invokes only if user opts in, conditionally includes cn-rules.md
10. init.sh offers Justfile generation: delegates to `bulwark-scaffold` skill

**DEFERRED from P7.1:**

- AC17 cleanup script: operational correctness, not blocking initial release. Low user impact on day 1 (new installs have no log accumulation yet). Can be added as P6.x or P7.1.5 patch.
- init.sh statusline delegation: lower priority than LSP and Justfile steps
- P6.1 (subagent-prompting dependency addition to skills): P6 work, after P7.1

**Why defer AC17?**

The value of AC17 is preventing unbounded log growth over time. For a new install, there are no stale logs — the problem doesn't manifest until weeks in. The implementation is non-trivial: the SessionStart hook must distinguish new session vs resume vs post-compact (the SME noted this is the hardest part). Getting this wrong causes data loss (deleting logs that should be kept). Better to ship a clean v1 and add AC17 as a follow-on once the session distinction mechanism is validated.

**Why defer statusline?**

Statusline is cosmetic. It adds zero governance value. Users who want it can invoke `/bulwark-statusline` manually. Init offering it would extend the onboarding sequence for a feature that most users won't need on day 1.

### Implementation Feasibility & Effort

**Validated against actual codebase:**

1. **init-rules.sh already has 90% of the logic needed.** It copies `lib/templates/rules.md`, backs up existing files, validates directories. The only change is the target path (`$TARGET/.claude/rules/rules.md`). Also needs to handle `.claude/rules/` directory creation.

2. **init-project-rules.sh is complete and correct.** It already does idempotency checking, creates CLAUDE.md if absent, appends templates. No structural changes needed — only ensure the `--bulwark` flag is NOT set for external users.

3. **init.sh is the orchestrator.** Calls `init-rules.sh` then `init-project-rules.sh` in sequence. Adds prompts for optional steps. Simple bash script with interactive prompts. No new tooling needed.

4. **CN rules split is straightforward.** Create `lib/templates/cn-rules.md` containing CN1/CN2 only. Modify init.sh to conditionally copy it based on LSP opt-in response. Two-file approach is cleaner than dynamic generation.

5. **Agent removal is trivial.** Move `code-analyzer.md` and `file-counter.md` to `tests/fixtures/agents/` (preserving them for testing) and remove from `.claude/agents/`.

6. **plugin.json metadata addition** is 5 lines of JSON.

7. **hooks.json timeout correction**: change 60000→60, 30000→30, 5000→5. NOTE: The SME flagged these as "correct per Claude Code's JSON schema" but Session 85 notes say "must fix (60000→60, 30000→30, 5000→5) — confirmed seconds." This contradiction needs resolution before implementation. Recommend: verify against official docs and/or test a hook timeout value in practice.

**Feasibility concerns:**

- **LSP delegation complexity**: The `setup-lsp` skill has a 9-stage pipeline with a restart checkpoint (install → restart → verify → configure). Init.sh cannot orchestrate a skill that requires Claude Code to restart mid-flow. The delegation must be a recommendation ("run `/setup-lsp` after restarting"), not a direct script call. Init.sh prints the instruction; user follows it.

- **Justfile delegation**: `bulwark-scaffold` is a skill (not a script), so init.sh cannot directly invoke it. Same pattern as LSP: print the instruction to run `/bulwark-scaffold`. This is the correct "delegate" pattern — init.sh is a bash script, skills are Claude Code constructs.

**Implication**: The "optional steps" in init.sh are not interactive delegations — they are printed instructions. init.sh does the mandatory governance setup (bash-scriptable), then prints a post-init checklist with recommended skill invocations. This is simpler to implement and more reliable.

### Build Order & Dependencies

**Dependency graph:**

```
Step 1 (no deps): Remove test agents from .claude/agents/
Step 2 (no deps): Sync CN1/CN2 to lib/templates/rules.md
Step 3 (after Step 2): Create lib/templates/cn-rules.md (CN rules split)
Step 4 (after Step 2): Update init-rules.sh target path to .claude/rules/
Step 5 (after Steps 3, 4): Create scripts/init.sh (mandatory steps + post-init checklist)
Step 6 (no deps): Correct hooks.json timeouts (after resolving milliseconds vs seconds question)
Step 7 (no deps): Add marketplace metadata to plugin.json
Step 8 (no deps): Document first-run hook failure in README/quickstart
```

**Build order for sessions:**

Session 1 (P7.1 implementation):
- Steps 1, 2, 3 (trivial correctness fixes — 30 min combined)
- Steps 4, 5 (init.sh implementation — primary work of the session)
- Steps 6, 7 (manifest/hooks fixes — 20 min combined)
- Step 8 (documentation note — in README draft)

Session 2 (P7.1 validation):
- User tests init.sh on a fresh project directory
- Verify governance files land in correct locations
- Verify CLAUDE.md injection is idempotent
- Verify CN rules are excluded when LSP opt-in is declined
- Verify test agents no longer appear for end users

**Estimated sessions: 2 (matches P7.1 task brief)**

### Value-Effort Trade-offs

**Highest ROI:**

1. **Removing test agents** — Zero effort, eliminates a confusing user experience (two unexplained test agents appearing in agent list).

2. **init.sh with delegation pattern (printed checklist)** — Low effort (~150 lines bash), high value (single command gets user to governed state). The delegation-over-absorption pattern avoids duplicating bulwark-scaffold logic.

3. **CN rules split for conditional inclusion** — Low effort (one new file, one conditional copy in init.sh), directly addresses the LSP opt-out requirement without over-engineering.

**Lowest ROI (correctly deferred):**

- AC17 cleanup: Medium effort (session distinction logic), low day-1 impact, data-loss risk if session detection is wrong.
- Statusline in init: Low effort, very low value (cosmetic, not governance).

**Key trade-off decision: LSP delegation in init.sh**

The SME confirmed LSP setup requires a restart mid-flow, which means init.sh cannot orchestrate it as a sequential script step. The correct implementation is:
- init.sh asks: "Would you like LSP support? (Recommended — enables CN1/CN2 rules)"
- If yes: copies cn-rules.md to `.claude/rules/cn-rules.md`, prints "Restart Claude Code and run /setup-lsp to complete LSP configuration"
- If no: does not copy cn-rules.md

This gives the user the conditional governance file placement (the hard part) while leaving the LSP binary installation to the skill (where it belongs). This is the right decomposition — scripts handle file system operations, skills handle AI-guided configuration.

---

## Post-Debate Update (after Critical Analyst review)

**Critical Analyst's top finding challenged and corrected:**

The Critical Analyst asserted that `agents/` at the repository root does not exist. This is **incorrect**. Verified: `/mnt/c/projects/the-bulwark/agents/` exists and contains 10 agents (4 bulwark-* pipeline agents, 4 plan-creation agents, statusline-setup.md, standards-reviewer.md). The conflation was between `.claude/agents/` (dev dogfooding, 19 agents) and root `agents/` (plugin distribution, 10 agents).

**Refined gap assessment for agent distribution:**

The actual agent gaps are more nuanced:
1. `product-ideation-*` agents (6) and `markdown-reviewer.md` exist in `.claude/agents/` but NOT in root `agents/` — these skill-specific sub-agents are missing from the distribution. Decision needed: should they ship?
2. `standards-reviewer.md` and `bulwark-standards-reviewer.md` in root `agents/` are **byte-identical duplicates** (confirmed via diff) — one must be removed.
3. Test agents (`code-analyzer.md`, `file-counter.md`, `test-validator.md`) are only in `.claude/agents/` (dev environment) — they affect Bulwark devs, not plugin users. Real concern, lower severity than the Critical Analyst framed.

**Agreement with Critical Analyst — CN simplification:**

CN1/CN2 should be included in base `lib/templates/rules.md` unconditionally. Rules are preference-based ("prefer LSP > Grep > Glob") and degrade gracefully without LSP installed. Removing conditional inclusion removes 4-6 hours of init.sh complexity with zero governance cost. **My recommendation changes accordingly: drop the cn-rules.md split, include CN1/CN2 in base template.**

**Agreement with Critical Analyst — init.sh delegation:**

A bash script cannot invoke Claude Code skills. The printed post-init checklist pattern (which I independently proposed and they independently arrived at) is confirmed as the correct model. We are aligned.

**Additional scope items arising from verification:**

- Remove duplicate `standards-reviewer.md` from root `agents/` (trivial, high correctness value)
- Decide which skill-specific sub-agents ship in root `agents/` (product-ideation-*, markdown-reviewer) — evaluate user-facing value for distributed plugin

---

## Recommendation

**Proceed** — P7.1 is well-defined and achievable in 2 sessions. The work is mostly integration and orchestration of existing components, not new feature development.

**Revised critical path (post-debate):** Remove duplicate standards-reviewer.md from root agents/ → sync CN rules to base lib/templates/rules.md (unconditionally, no split) → update init-rules.sh target path → create init.sh (mandatory steps + printed post-init checklist) → fix manifest/hooks metadata.

**Strong guidance on scope:** Do not absorb bulwark-scaffold or setup-lsp into init.sh. The delegation pattern (print post-init checklist with skill invocations) is simpler, more reliable, and respects CS1 (Single Responsibility). init.sh governs file system setup only.

**Key open question for architect:** hooks.json timeout values — milliseconds vs seconds. SME says current values are correct; Session 85 notes say they must be corrected. This must be resolved with a definitive test before implementation, not assumed.

**AC17 — position revised after TA debate:** Include in P7.1 scope. The T-10 day age threshold is the implicit session-distinction mechanism — files under 10 days old are never at risk regardless of whether the hook fires on resume, new session, or post-compact. My original deferral concern (session detection complexity causing data-loss risk) was based on a flawed premise. Implementation: cleanup-stale.sh with `find -mtime +10`, added as a second SessionStart hook, 30s timeout.

**Live debate not yet resolved:** CN conditional inclusion. TA proposes two-file split (rules-core.md + rules-cn.md in .claude/rules/). CA and I maintain unconditional inclusion (CN rules are preference-based, degrade gracefully). This is the one remaining open question for the lead to adjudicate.

---

## Final Position Summary (all peers reviewed)

| Topic | Position | Confidence |
|-------|----------|-----------|
| Init pipeline | Thin orchestrator + atomic scripts + printed delegation | High — all peers aligned |
| CN inclusion | Unconditional (base rules.md) | Medium — TA disagrees, live debate |
| Justfile delegation | Printed recommendation, not scripted | High — all peers aligned |
| AC17 cleanup | Include in P7.1, T-10 threshold, every SessionStart | High — revised after TA argument |
| Distribution | Marketplace primary, homebrew tier 2 | High — all peers aligned |
| Test agents (dist) | Not a distribution risk (root agents/ correct) | High — verified via codebase |
| Duplicate agent | Remove standards-reviewer.md from root agents/ | High — confirmed byte-identical |
| Timeout units | Resolve against official schema before any change | High — SME and research conflict |
