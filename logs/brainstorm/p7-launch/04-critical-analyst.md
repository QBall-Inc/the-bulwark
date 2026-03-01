---
role: critical-analyst
topic: "P7.1 Launch: Plugin Manifest, Initialization, and Distribution"
verdict: modify
verdict_confidence: high
conditions:
  - "CN1/CN2 conditional inclusion design is simplified (single opt-out flag, not dual file system)"
  - "Init script is kept thin — mandatory copy steps only, no orchestration of optional/recommended steps at runtime"
  - "Agents/ directory mismatch (plugin.json says agents/ root, agents live in .claude/agents/) is resolved before distribution"
  - "Timeout values corrected before any real-world testing of hooks"
  - "test-validator.md removed alongside code-analyzer.md and file-counter.md (SME missed it)"
key_challenges:
  - "agents/ directory does not exist at plugin root — plugin.json declares agents/ but .claude/agents/ is where agents actually live. This is a structural gap, not a cosmetic issue."
  - "CN conditional inclusion adds complexity to a simple copy-on-init model — the right design is unclear and under-specified"
  - "No automated tests for launch-critical init scripts — idempotency is assumed, not verified"
  - "First-run hook failure (#10997) has no mitigation beyond documentation — the user experience is broken on first install"
  - "Monolithic vs modular plugin decision deferred — but the answer has cost implications for every user's context window"
---

# P7.1 Launch — Critical Analysis

## Problem Validation

**Should P7.1 be solved at all?**

Yes, unambiguously. The plugin is functionally ready — hooks fire, skills exist, agents exist. The gap is delivery plumbing: the plugin cannot be installed by external users because the init story is incomplete and the agents/ directory structure is wrong. Without P7.1, Bulwark is a local dev tool, not a distributable plugin. The problem is real and the investment is commensurate.

**Is the premise of "90% complete" accurate?**

Partially. The claim is directionally correct but obscures a structural gap. `plugin.json` declares `"agents": "agents/"` (root-level directory). That directory does not exist — agents live in `.claude/agents/`. This is not a cosmetic mismatch; it means agents don't ship with the plugin at all until resolved. The SME correctly identified this as requiring audit but framed it as "which agents to migrate" rather than "the agents directory doesn't exist at the declared path." This distinction matters for scope estimation.

**Is the problem statement asking the right questions?**

Four of the five design questions are correct. Question 3 (delegate Just recipe to bulwark-scaffold) is already answered: delegate, not absorb. It should not be in the design question list — it's a resolved implementation detail, not an open design question. The real question that should replace it: **How do we handle the agents/ directory mismatch — migrate agents to root agents/ or change plugin.json to reference .claude/agents/?**

---

## Cost-Benefit Assessment

**High-value work (must do):**
- Correcting timeout values (60000→60): 30 minutes. Critical path to correct hook behavior. If a hook times out in 60ms (current behavior unknown — may be using ms not s) or runs for 16.7 hours, users will notice.
- Resolving agents/ directory mismatch: 1-2 hours. Without this, production agents don't ship.
- Removing test agents (code-analyzer.md, file-counter.md, test-validator.md): 15 minutes. Test agents exposed to users is a quality signal problem.
- CN1/CN2 sync to lib/templates/rules.md: 1 hour. Missing rules = silent governance gap for all users.
- Correcting init-rules.sh target path: 30 minutes. Currently copies to $TARGET/Rules.md; must copy to .claude/rules/rules.md.

**Medium-value work (should do for v1):**
- Creating init.sh orchestrator: 2-3 hours. Users need a single entry point. Without it, they must know to run two scripts in order — documentation overhead.
- Creating cleanup-stale.sh for AC17: 3-4 hours. Logs/tmp accumulate. Not blocking for launch, but a known pain point.
- CN conditional inclusion: 4-6 hours. Adds complexity. The split-file approach (lib/templates/cn-rules.md) is cleaner than dynamic generation.

**Low-value work (defer):**
- Homebrew/npm packaging: Not needed for v1. GitHub marketplace is sufficient. Multi-channel distribution before v1 user feedback is premature optimization.
- Automated init tests: Valuable but not launch-critical. Manual test protocol has been sufficient for all previous Bulwark launches.
- Monolithic vs modular plugin design: The answer is monolithic for v1. The "extension bundles" idea requires packaging infrastructure that doesn't exist. Ship everything, learn from adoption.

**Total justified investment**: High. The 90% complete claim means the last 10% is delivery plumbing, which is always the highest-leverage work before launch.

---

## Assumption Challenges

### CATALOG — All Assumptions Made

1. Plugin structure is "~90% complete" — the hard work is done.
2. agents/ at plugin root exists and just needs population.
3. init-rules.sh and init-project-rules.sh are sufficient foundations for init.sh.
4. CN conditional inclusion is necessary at init time (not at rule-file level).
5. The dependency field (`skills:`) in skill frontmatter will continue working as an undocumented feature through launch.
6. GitHub marketplace is the right primary channel for this type of tool.
7. The thin-copy principle (copy-once, no lifecycle management) is the right UX model.
8. First-run hook failure (#10997) is acceptable to document and move on.
9. The timeout values being wrong (60000ms vs 60s) is a known bug, not an unknown behavior.
10. .claude/rules/ auto-loading will work reliably for all Bulwark-installed users.
11. monolithic plugin (all 28 skills + 16 production agents) will not cause context window issues for users.
12. bulwark-scaffold delegation for Justfile is complete enough that init.sh need not know about it.
13. The first-run restart requirement is a documentation problem, not a UX problem.
14. Test agents are clearly labeled and can be removed without affecting any production flow.
15. sync-hooks-for-dev.sh correctly stays out of the init pipeline.
16. lib/templates/claudemd-injection.md is current and correct (not audited in SME output).
17. SessionStart governance re-injection after /clear is the right behavior (not once: true).
18. External users need the same 198-line Rules.md as Bulwark devs.

### RANK — By Risk (Probability Wrong × Impact Wrong)

| Rank | Assumption | Risk |
|------|-----------|------|
| 1 | agents/ at plugin root exists | HIGH probability wrong (it doesn't exist), HIGH impact (agents don't ship) |
| 2 | 198-line Rules.md is right for external users | MEDIUM probability wrong, HIGH impact (governance failure for users without MEMORY.md) |
| 3 | First-run failure is a documentation problem | LOW probability it's fixable, HIGH impact on user's first impression |
| 4 | Monolithic plugin won't cause context window issues | MEDIUM probability wrong for power users, MEDIUM impact |
| 5 | CN conditional inclusion at init time (vs rule-file level) | MEDIUM probability wrong design, MEDIUM impact |

### STRESS-TEST — Top 3 Highest-Risk Assumptions

**Assumption 1: agents/ directory at plugin root exists**

- Evidence supporting: SME says "audit required to determine which agents ship with plugin" — implies it's a population question.
- Evidence contradicting: `ls agents/` at root returns nothing. `plugin.json` declares `"agents": "agents/"`. `.claude/agents/` has 19 agents. There is no root-level `agents/` directory.
- If wrong: No agents ship with the plugin. Users get no bulwark-implementer, no bulwark-issue-analyzer, no pipeline enforcement. The core value proposition (sub-agent orchestration) breaks entirely.
- Cost to validate: Already validated — directory doesn't exist. Cost to fix: create `agents/` at root, move or symlink production agents.

**Assumption 2: 198-line Rules.md is right for external users**

- Evidence supporting: P8.1 validated that the current slim Rules.md with nuance works in production at Jefferies. The user confirmed quality parity.
- Evidence contradicting: Bulwark devs have 80+ sessions of MEMORY.md context that primes compliance behavior. External users have no MEMORY.md. The Rules.md was designed for a context-rich session environment. OR/SA rules in CLAUDE.md (which won't be present for external users in the same form) may be prerequisites for some Rules.md sections to make sense.
- If wrong: External users get governance files that look complete but produce lower compliance than Bulwark devs experience. Impossible to detect without external user telemetry.
- Cost to validate: Would require a test session with a clean environment (no MEMORY.md) and the exact files an external user would receive. Worth doing before launch.

**Assumption 3: First-run hook failure is a documentation problem**

- Evidence supporting: GitHub #10997 is a known race condition. "Works on subsequent runs" is verified behavior. Documentation is the standard mitigation for known bugs.
- Evidence contradicting: The first impression of a plugin is its most important moment. A user who installs Bulwark, sees no governance protocol injected, and doesn't know they need to restart will conclude the plugin is broken. The rate of "restart after first install" as discovered behavior (vs documented requirement) is likely very low.
- If wrong: User adoption fails at install step. The plugin gets a reputation for being unreliable before it's even tried.
- Cost to validate: Test by installing from marketplace (or local plugin dir) in a fresh Claude Code session. Observe whether SessionStart fires. If it doesn't, decide whether to add an in-CLAUDE.md fallback or accept the documentation mitigation.

---

> **Highest-Risk Assumption**: `plugin.json` declares `"agents": "agents/"` but no `agents/` directory exists at the repository root — agents live in `.claude/agents/`.
> **If wrong**: Production agents (bulwark-implementer, bulwark-issue-analyzer, etc.) do not ship with the plugin. The plugin's core enforcement value is absent for all users.
> **To validate**: `ls /mnt/c/projects/the-bulwark/agents/` — confirmed empty/nonexistent. Immediate action: create `agents/` at root, populate with production agents (4 bulwark-*, plan-creation-*, product-ideation-*, statusline-setup.md, markdown-reviewer.md — excluding code-analyzer.md, file-counter.md, test-validator.md).

---

## Gaps in Proposals

**1. agents/ directory structural gap understated**

The SME frames this as "which agents to migrate" but the directory doesn't exist. This isn't a population question — it's a structural gap that means zero agents ship today. The SME's recommendation should have been "create agents/ and populate it" not "audit and migrate."

**2. test-validator.md missed by SME**

SME identified code-analyzer.md and file-counter.md as test-only agents to remove. But `.claude/agents/` also contains `test-validator.md`. The SME's list of 19 agents with only 2 flagged for removal is incomplete. Three agents need removal: code-analyzer.md, file-counter.md, and test-validator.md.

**3. lib/templates/claudemd-injection.md not audited**

The SME thoroughly reviewed lib/templates/rules.md (found CN1/CN2 missing) but did not audit lib/templates/claudemd-injection.md. This file is the other half of the init pipeline — it injects the Binding Contract + Mandatory Rules section into the user's CLAUDE.md. If it's stale (e.g., references OR/SA rules that have been modified, or missing AC references), users get an inconsistent governance setup. This is a gap in the SME analysis.

**4. CN conditional inclusion design is under-specified**

Both SME and research synthesis mention that CN rules should be conditionally included based on LSP opt-in/opt-out. Two approaches are proposed (split file vs dynamic generation) but neither is decided. The brainstorm needs to pick one. The split-file approach (.claude/rules/rules.md + .claude/rules/cn-rules.md) is architecturally cleaner but requires init.sh to know about LSP state — which means either asking the user or delegating to setup-lsp skill before init completes. This is a UX sequencing problem, not just a file design problem.

**5. init.sh interaction with setup-lsp is unresolved**

The research and SME both say "delegate to setup-lsp for LSP." But init.sh runs as a bash script. setup-lsp is a Claude Code skill. A bash script cannot invoke a Claude Code skill directly. This means either: (a) init.sh prompts the user to run /setup-lsp manually after init, or (b) init.sh is not a pure bash script — it's a Claude Code slash command (/bulwark:init) that can invoke skills. The brainstorm has not addressed this interaction mechanism.

**6. No rollback mechanism for init**

init-rules.sh creates a .backup file if Rules.md exists. But there's no rollback command or documented rollback process. If init fails partway through (rules installed but CLAUDE.md injection fails), the project is in a partially configured state. For v1, this is acceptable — document "if init fails, revert .backup and delete .claude/rules/rules.md." But the current proposal doesn't mention partial failure states at all.

**7. Version pinning not discussed**

GitHub marketplace install (`/plugin marketplace add ashaykubal/the-bulwark`) will presumably install from the default branch. What happens when Bulwark updates Rules.md in a future version? Existing users' `.claude/rules/rules.md` is a static copy — they don't get updates. The thin-copy principle handles this (users own their copy), but the update story ("run /bulwark:update or re-run init-rules.sh") is completely absent from the proposals.

---

## Simpler Alternatives

**Alternative 1: Skip init.sh entirely for v1**

Hooks and skills deliver value immediately after plugin install — zero init required for enforcement. The only init step that's truly mandatory is governance file delivery (Rules.md). Could we ship a CONTRIBUTING.md or README.md with manual copy instructions instead of an automated init script?

**Assessment**: Too high friction. The Husky v7 parallel (thin init, not lifecycle manager) is the right model. Users won't manually copy files. init.sh is necessary. But this alternative highlights that init.sh must be thin — it shouldn't try to be a wizard.

**Alternative 2: Don't conditionally include CN rules — ship them in lib/templates/rules.md and let users delete if unwanted**

The conditional inclusion design adds complexity to both init.sh (must know LSP state) and the template structure (split files). External users without LSP can simply ignore CN1/CN2 — the rules say "prefer LSP" which degrades gracefully to grep when LSP isn't available.

**Assessment**: This is the right simplification. CN1/CN2 should be in the base rules.md template. The rules themselves are written as preferences (LSP > Grep > Glob), so they're self-degrading when LSP is absent. Conditional inclusion is over-engineering a preference rule. **Recommend: include CN1/CN2 in base template, remove conditional inclusion complexity.**

**Alternative 3: Change plugin.json agents path to .claude/agents/ instead of creating a new agents/ directory**

Instead of migrating 16 agents to a new root-level agents/ directory, update plugin.json to point at `.claude/agents/`.

**Assessment**: This is worth considering. The plugin.json schema accepts a directory path string. If `.claude/agents/` is valid as a path relative to the plugin root, this avoids restructuring. However, the SME says agents/ at root is "the root agents/ directory" convention for plugins. The risk: if .claude/agents/ is a Claude Code-internal convention (not a plugin distribution path), Claude Code might not expose those agents to users of the installed plugin. Needs verification. If both work, prefer .claude/agents/ (avoids churn). If only agents/ works, migrate. **This is a concrete validation task before finalizing the design.**

**Alternative 4: Treat P7.1 as two sequential milestones**

Milestone A (pre-launch): Fix structural gaps (agents/ directory, timeout values, test agent removal, CN1/CN2 sync). These are correctness fixes, not new features.

Milestone B (launch): init.sh, cleanup script, documentation.

**Assessment**: Useful mental model. Milestone A can be done in a single session with no design decisions. Milestone B requires the brainstorm output. The team should sequence this way.

---

## Kill Criteria

P7.1 should be deferred (not killed) if:

1. **agents/ path in plugin.json cannot resolve to .claude/agents/ AND creating root agents/ breaks the existing .claude/agents/ workflow for Bulwark devs.** Mitigation: symlink agents → .claude/agents (Linux-friendly, but Windows/WSL complicates this).

2. **The marketplace submission process is blocked.** GitHub's plugin marketplace submission may have requirements not yet known (review process, manifest fields, etc.). If submission requires >2 weeks of external dependency, defer launch date.

3. **First-run failure (#10997) cannot be mitigated by documentation alone AND no workaround exists.** If >50% of first-time users report "it didn't work," the user experience problem outweighs the feature value.

Kill criteria (abandon P7.1 entirely): None identified. The plugin has real production value demonstrated by Bulwark dev use. External distribution is a sound strategy. The risks are execution risks, not strategic risks.

---

## Verdict

**MODIFY** (Confidence: high)

Proceed with P7.1, but with one mandatory scope adjustment and three immediate correctness fixes before design work begins:

**Immediate correctness fixes (no design decisions needed):**
1. Create `agents/` at repository root, populate with production agents (exclude code-analyzer.md, file-counter.md, test-validator.md)
2. Fix timeout values in hooks/hooks.json (60000→60, 30000→30, 5000→5)
3. Remove code-analyzer.md, file-counter.md, test-validator.md from .claude/agents/

**Scope adjustment — simplify CN conditional inclusion:**
Remove conditional inclusion from init.sh design. Include CN1/CN2 in base lib/templates/rules.md. The rules are preference-based and degrade gracefully without LSP. Conditional inclusion adds 4-6 hours of complexity for zero governance benefit (a user without LSP who reads CN1/CN2 will simply skip them).

**Open questions requiring brainstorm consensus:**
1. agents/ root directory vs plugin.json pointing to .claude/agents/ — needs verification of which path Claude Code resolves for plugin-installed agents
2. init.sh as bash script vs /bulwark:init as slash command — determines whether optional steps (setup-lsp delegation) are even possible
3. lib/templates/claudemd-injection.md audit — needed before launch but not in current proposals

---

## Debate Influence

After reviewing both peer summaries, the following corrections and updates apply:

### Correction: agents/ directory gap was wrong

My highest-risk assumption identification was incorrect. Root `agents/` DOES exist at the repository root with 10 agents. The TA's analysis was right on this point. Correcting the record:

- `agents/` (plugin ships): 10 agents — 4 bulwark-*, 4 plan-creation-*, statusline-setup, standards-reviewer
- `.claude/agents/` (dev copy): 19 agents — adds 5 product-ideation-*, markdown-reviewer, code-analyzer, file-counter, test-validator

However, this reveals NEW gaps that no role identified:

1. **product-ideation agents missing from shipped set**: 5 product-ideation agents exist in `.claude/agents/` but NOT in root `agents/`. If these should ship (they are skill-specific sub-agents used by the product-ideation skill), they're absent from distribution.

2. **standards-reviewer.md naming inconsistency**: `agents/standards-reviewer.md` and `.claude/agents/bulwark-standards-reviewer.md` are the same agent (identical content, confirmed) with different filenames. Shipped version lacks the `bulwark-` prefix.

3. **test-validator.md correctly excluded**: Not in root agents/ — confirmed safe. But SME's count of "2 test agents" remains wrong (test-validator.md is a third).

### Position maintained: CN conditional inclusion is over-engineering

Both TA and PDL initially advocated for the two-file split (rules-core.md + rules-cn.md). After challenge, PDL now agrees with unconditional inclusion. TA challenge still open. CN1/CN2 rules state preferences ("prefer LSP over Grep for semantic navigation"). Without LSP, this gracefully degrades — user reads CN1, has no LSP, uses Grep. No governance failure occurs. The split-file approach adds: init.sh LSP intent prompt before mandatory steps, two source template files to maintain, and a "re-run init to get cn-rules.md later" problem if user installs LSP after init. Challenge sent to both TA and PDL; PDL has conceded.

### Agree on AC17: TA's "accept double-fire" approach is architecturally correct

If AC17 is included, TA's insight that "T-10 day threshold IS the implicit session guard" is correct. No session marker files needed. If AC17 is deferred (PDL's recommendation), that's also defensible. Either position is acceptable.

### Timeout units: Research synthesis already resolved this

Both TA and PDL flag the SME vs synthesis contradiction as "must verify." The synthesis explicitly states "confirmed by docs + lazyptc-mcp + clear-framework cross-reference — timeout is in seconds." The synthesis represents 5 research agents vs the SME's single reading. The SME made a factual error. Treating this as an open question adds delay for a decision that was already made. Challenge sent to TA.

---

## Post-Debate Update

### PDL challenge received — agents/ correction confirmed, new precision added

PDL confirmed my self-correction on agents/ directory. PDL adds:
- test agent removal is a **dev UX concern** (affects `.claude/agents/`), NOT a plugin distribution risk — test agents are already absent from root `agents/`
- standards-reviewer.md / bulwark-standards-reviewer.md are byte-identical duplicates (confirmed via diff) — one must be removed
- product-ideation-* and markdown-reviewer absence from root `agents/` is the real shipped-set gap

PDL agrees with CN unconditional inclusion after my challenge. Alignment reached.

### Verdict remains MODIFY

The agents/ structural gap was a factual error in my initial analysis, but the MODIFY verdict stands for the following reasons:

1. product-ideation agents missing from shipped root `agents/` — intentional or gap? Needs user decision.
2. standards-reviewer.md / bulwark-standards-reviewer.md duplicate — one must be removed before distribution.
3. CN conditional inclusion: PDL now agrees on unconditional. TA challenge still open.
4. lib/templates/claudemd-injection.md still unaudited — no role addressed this.
5. Timeout units are resolved by research synthesis — must not be re-opened as "unverified."
