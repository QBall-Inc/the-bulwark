---
role: technical-architect
topic: "P5.15 — Add --exploratory mode to bulwark-brainstorm using Agent Teams peer debate"
recommendation: proceed
key_findings:
  - "Adopt P5.13's sandwich architecture verbatim: shared Pre-Flight/SME/Synthesis/Diagnostics stages, mode-specific Stage 3A (--scoped, Task tool) and Stage 3B (--exploratory, Agent Teams). This is the proven dual-mode pattern."
  - "Consolidate 5 roles to 4 for --exploratory: SME solo (Task tool) + 3 AT teammates (Product & Delivery Lead, Technical Architect, Critical Analyst). The combined role absorbs PM's value/scope focus and Dev Lead's feasibility/effort focus."
  - "The Critical Analyst's role transformation is the architectural differentiator: from sequential-last gatekeeper (--scoped) to active adversarial participant throughout (--exploratory). This is the primary quality advantage Agent Teams provide."
  - "AT failure recovery must be explicit in SKILL.md: if Agent Teams fails mid-execution (lead context compaction, teammate crash), fall back to --scoped for remaining unfinished roles. Partial AT output feeds into the fallback as additional context."
  - "No structural changes to synthesis-output.md or critic-output.md templates. Mode awareness is a metadata annotation (mode field in synthesis YAML header), not a template restructure."
---

# P5.15 — Add --exploratory Mode to bulwark-brainstorm — Senior Technical Architect

## Summary

The --exploratory mode should be implemented as a Stage 3B branch within the existing 6-stage pipeline, following P5.13's sandwich architecture pattern exactly. The core architectural insight is that only the team collaboration stage (Stage 3) changes between modes — Pre-Flight, SME, Synthesis, and Diagnostics remain shared. Role consolidation from 5 to 4 (merging PM + Dev Lead into Product & Delivery Lead) satisfies the 3-4 agent AT coordination cap while preserving the Critical Analyst's transformation from sequential gatekeeper to active adversarial participant throughout the debate.

## Detailed Analysis

### 1. Architectural Approach — Sandwich Structure with Stage 3 Fork

Implement the dual-mode architecture as a conditional branch at Stage 3, with all other stages shared. The existing SKILL.md (391 lines at `/mnt/c/projects/the-bulwark/skills/bulwark-brainstorm/SKILL.md`) restructures as follows:

```
Stage 1: Pre-Flight (SHARED)
  |-- existing logic unchanged
  |-- ADD: mode detection (env var check + user choice)
  |-- ADD: --scoped / --exploratory argument parsing

Stage 2: Project SME (SHARED — Task tool, solo)
  |-- identical in both modes
  |-- uses references/role-project-sme.md (unchanged)

Stage 3A: Role Analysis — Task Tool Mode (--scoped)
  |-- existing Stage 3 + Stage 4 logic, unchanged
  |-- PM + Architect + Dev Lead parallel, then Critic sequential

Stage 3B: Role Analysis — Agent Teams Mode (--exploratory)
  |-- Lead enters delegate mode
  |-- Spawn 3 teammates: Product & Delivery Lead, Architect, Critic
  |-- Dual-output contract: logs/ artifact + mailbox summary
  |-- Critic participates throughout (active adversarial)
  |-- AT failure recovery: fall back to Stage 3A for unfinished roles

Stage 4: Critical Analyst (--scoped ONLY)
  |-- Absorbed into Stage 3B for --exploratory (Critic is a teammate)

Stage 5: Synthesis (SHARED, mode-aware)
  |-- Reads all log files regardless of mode
  |-- mode field in synthesis YAML header
  |-- Critical Evaluation Gate unchanged (uses Task tool for follow-ups)

Stage 6: Diagnostics (SHARED, extended)
  |-- existing fields unchanged
  |-- ADD: AT-specific metrics block
```

This structure means the existing --scoped flow (Stages 1-6) requires zero behavioral changes. The --exploratory additions are purely additive: a new Stage 3B block, mode detection in Stage 1, and AT metrics in Stage 6. The current Stage 4 (Critical Analyst solo) only executes in --scoped mode; in --exploratory mode, the Critic is a Stage 3B teammate.

The mode detection logic replicates P5.13's pattern from `/mnt/c/projects/the-bulwark/plans/task-briefs/P5.13-plan-creation.md` (lines 229-239): check `$CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` env var, offer choice if set, graceful degradation if not set but user requested --exploratory.

### 2. Design Patterns That Apply

**Sandwich Pattern (from P5.13).** Shared outer stages wrapping mode-specific inner stages. This is the correct pattern because Pre-Flight setup (directory creation, skill loading, token checks) and Synthesis (reading logs, writing output) are mode-independent operations. Apply it directly.

**Dual-Output Contract (from P5.13 FR4).** Every AT teammate prompt includes two output requirements: (1) full analysis written to `logs/brainstorm/{topic-slug}/{NN}-{role}.md` using the existing `templates/role-output.md` format, and (2) a 3-5 sentence coordination summary sent to teammates via mailbox. The log artifact is the SA2 compliance mechanism; the mailbox summary is the debate substrate. Enforce this in the teammate prompt template, not in SKILL.md prose — the prompt is where the agent actually reads it.

**Delegate Mode.** The lead (orchestrator executing SKILL.md) enters delegate mode (Shift+Tab equivalent in prompt instructions) to prevent it from performing brainstorm analysis itself. The lead's role in --exploratory is strictly coordination: spawn teammates, monitor for completion, collect log artifacts. This mirrors P5.13's approach.

**Peer Deliberation Mode.** Each teammate prompt includes an explicit instruction to read and challenge other teammates' mailbox summaries. The prompt template should include: "After writing your analysis to the log file, read other teammates' mailbox messages. If you disagree with any finding, send a targeted challenge via mailbox explaining your disagreement and the evidence behind it." This is the primary differentiator from --scoped mode.

**Patterns to avoid:**

- **Full mesh communication**: Do not instruct all 3 teammates to message all others. This creates O(n^2) message volume. Instead, instruct teammates to broadcast their summary once and respond only to messages they disagree with. Selective challenge, not universal response.
- **Nested Agent Teams**: AT does not support nested teams. The Critical Evaluation Gate's follow-up agents (SKILL.md lines 206-219) must continue using Task tool, not AT. This is correct by design — follow-up validation is a focused verification task.
- **Role-specific AT configuration**: Do not create separate AT configurations per role. All 3 teammates share the same AT instance with different system prompts. The differentiation is in the prompt, not the infrastructure.

### 3. Technical Trade-offs and Their Implications

**Trade-off 1: Role Consolidation (5 roles to 4)**

Merge PM (user value, scope, prioritization) and Dev Lead (feasibility, effort, build order) into "Product & Delivery Lead" for --exploratory mode. The existing separate role references at `/mnt/c/projects/the-bulwark/skills/bulwark-brainstorm/references/role-product-manager.md` and `references/role-development-lead.md` remain unchanged for --scoped mode. Create a new `references/role-product-delivery-lead.md` that combines both focus areas for --exploratory mode.

Implication: The combined role loses the natural tension between "what users want" (PM) and "what is buildable" (Dev Lead). This tension is partially recovered by the Critic's active participation throughout — the Critic challenges both value assumptions and feasibility claims in real time. The net quality impact is: lower role-specific depth, higher cross-role challenge quality. For exploratory brainstorming (where problem framing is uncertain), this is the correct trade-off. For focused implementation brainstorming, --scoped with 5 distinct roles remains superior.

**Trade-off 2: Token Cost (~2x)**

AT mode runs 3 independent Claude instances plus the lead. Each teammate has its own full context window. The research synthesis confirms ~1.8-2x token cost vs Task tool. Mitigations:
- Warn user at Pre-Flight: "Exploratory mode consumes approximately 2x tokens. Proceed?"
- Adjust token checkpoints: warn at 25% pre-spawn (not 30%), checkpoint at 45% post-SME (not 55%)
- If token budget insufficient, recommend --scoped instead of proceeding with truncated AT debate

**Trade-off 3: Critic Timing**

In --scoped mode, the Critic runs last with all 4 prior outputs — maximum information, but zero influence on the analysis process. In --exploratory mode, the Critic participates throughout — maximum influence, but may anchor early on incomplete information. The mitigation is in the Critic's AT prompt: "Do not form a final verdict until all teammates have shared their summaries. Challenge early findings, but reserve your formal verdict for your log artifact."

**Trade-off 4: Lead Context Compaction Risk**

If the lead's context compacts during AT mode, all teammate processes are orphaned (research finding: "most severe underdiscussed failure mode"). No code-level mitigation exists — this is an AT platform limitation. Document it in SKILL.md error handling and in diagnostics. The structural mitigation is that SME runs via Task tool before AT begins, so codebase exploration (the longest phase) does not contribute to lead context pressure.

### 4. Integration Architecture

**File system integration.** Both modes write to the same output directory: `logs/brainstorm/{topic-slug}/`. File naming convention:

| Mode | Files |
|------|-------|
| --scoped | `01-project-sme.md`, `02-product-manager.md`, `03-technical-architect.md`, `04-development-lead.md`, `05-critical-analyst.md`, `synthesis.md` |
| --exploratory | `01-project-sme.md`, `02-product-delivery-lead.md`, `03-technical-architect.md`, `04-critical-analyst.md`, `synthesis.md` |

The numbering reflects execution order, not role importance. --exploratory has 4 files (not 5) because PM and Dev Lead are merged. The synthesis stage reads all `*.md` files in the directory (excluding `synthesis.md` itself), making it naturally mode-agnostic.

**Template compatibility.** AT teammates use the same `templates/role-output.md` format (YAML header with role/topic/recommendation/key_findings + Markdown body). The Critic teammate uses `templates/critic-output.md`. No new templates needed. The synthesis template (`templates/synthesis-output.md`) adds a `mode: scoped | exploratory` field to the YAML header but otherwise remains identical.

**Diagnostic extension.** The diagnostic template at `/mnt/c/projects/the-bulwark/skills/bulwark-brainstorm/templates/diagnostic-output.yaml` adds an AT-specific block when mode is --exploratory:

```yaml
agent_teams:  # only present in --exploratory mode
  display_mode: in-process
  delegate_mode: true
  teammate_count: 3
  peer_challenges_observed: "{count}"
  at_failure_recovery: false | "{description}"
```

**Sync script compatibility.** The rsync script at `scripts/sync-essential-skills.sh` maps `bulwark-brainstorm:brainstorm` for the Essential Skills repo. New files (the combined role reference) sync automatically since rsync copies the entire directory. No script modification needed unless the new file has a name that conflicts with existing rename transforms — it will not, since it follows the `role-*.md` naming convention.

**Dogfood copy.** The `.claude/skills/bulwark-brainstorm/` directory must be updated in lockstep with `skills/bulwark-brainstorm/`. This is an existing manual process, not an architectural concern.

**Frontmatter.** The existing frontmatter in SKILL.md needs one change: update `argument-hint` to include `--scoped` and `--exploratory` flags:

```yaml
argument-hint: "<topic, filepath, or directory> [--research <synthesis-file>] [--scoped | --exploratory]"
```

The `description` field should also mention the dual-mode capability, but must remain a single line (per MEMORY.md: "Multi-line descriptions silently break skill discovery").

### 5. Extensibility and Future-Proofing

**AT API stability.** Agent Teams are experimental (Feb 2026). The sandwich architecture isolates AT-specific code to Stage 3B only. If the AT API changes or the feature is removed, only Stage 3B needs modification — all other stages and the --scoped mode are unaffected. This is the primary architectural hedge.

**Additional AT modes.** If future brainstorm use cases emerge (e.g., --adversarial with 2 teams debating), the Stage 3 fork point supports additional branches (3C, 3D) without restructuring. The mode detection logic in Pre-Flight is a simple switch, not a complex conditional tree.

**Role count flexibility.** The 4-role structure (SME solo + 3 AT teammates) works at the current 3-4 agent cap. If AT scales to support more teammates in the future, the combined Product & Delivery Lead could be split back into separate PM and Dev Lead roles within AT mode. The role reference files already exist for the split versions — this is a prompt swap, not an architectural change.

**CLEAR Framework compatibility.** The mode field in synthesis output (`mode: scoped | exploratory`) gives CLEAR's future plan-management integration a signal for how the brainstorm was conducted. No CLEAR-specific logic should be added to the skill.

## Recommendation

**Proceed.** The architecture is straightforward: P5.13's sandwich pattern applied to an existing 6-stage pipeline with a Stage 3 fork point. The --scoped mode requires zero changes. The --exploratory mode adds one new Stage 3B block, one new combined role reference file, mode detection in Pre-Flight, and AT metrics in Diagnostics. The primary risk (lead context compaction) is a platform limitation with no code mitigation, but the structural mitigation (SME runs before AT, keeping the AT phase shorter) reduces exposure. Build --scoped-preserving changes first, then layer AT on top — the same session ordering P5.13 uses.
