---
role: project-sme
topic: "P5.15 — Add --exploratory mode to bulwark-brainstorm using Agent Teams peer debate"
recommendation: proceed
key_findings:
  - "bulwark-brainstorm is a 6-stage, 5-agent sequential pipeline (SME solo -> 3 parallel -> Critic solo -> synthesis) using Task tool. The --exploratory mode must coexist without disrupting this flow."
  - "P5.13 plan-creation task brief provides the exact integration pattern: sandwich architecture with shared Pre-Flight/Synthesis/Diagnostics stages and mode-specific Stage 3A (Task tool) / Stage 3B (Agent Teams). Reuse this split directly."
  - "Three file locations must stay synchronized: skills/bulwark-brainstorm/ (source), .claude/skills/bulwark-brainstorm/ (dogfood), and Essential Skills standalone repo (via sync-essential-skills.sh rsync with bulwark-brainstorm:brainstorm rename)."
  - "The Critical Evaluation Gate (Stage 5, lines 186-227 of SKILL.md) spawns follow-up Opus agents. In --exploratory mode, this gate must still function but may need adaptation since the preceding agent outputs will have different structure (debate-driven vs sequential)."
  - "Agent count cap of 3-4 from research means --exploratory cannot simply replicate all 5 current roles as Agent Teams teammates. Role consolidation is required — P5.13's 4-role model (PO + 3 AT teammates) is the proven pattern."
---

# P5.15 — Add --exploratory Mode to bulwark-brainstorm — Project SME Analysis

## Summary

The bulwark-brainstorm skill is a mature, well-structured 6-stage pipeline with 5 Opus sub-agents, custom templates, a Critical Evaluation Gate, and comprehensive diagnostics. Adding --exploratory mode is architecturally feasible because P5.13 plan-creation has already designed the exact dual-mode sandwich pattern this task needs. The primary risk is not technical but structural: the current skill has 5 roles while Agent Teams caps at 3-4 teammates, requiring role consolidation that must not dilute the quality of the --scoped mode.

## Detailed Analysis

### 1. Current bulwark-brainstorm Architecture (What Exists, What Must Not Be Disrupted)

The skill lives at `/mnt/c/projects/the-bulwark/skills/bulwark-brainstorm/SKILL.md` (391 lines) with a dogfood copy at `.claude/skills/bulwark-brainstorm/`. It consists of:

**6 Stages:**
- Stage 1: Pre-Flight (parse input, slugify, create output dir, load skills, token check, AskUserQuestion if ambiguous)
- Stage 2: Project SME (Opus, solo first — autonomous codebase exploration)
- Stage 3: Role Analysis (PM + Architect + Dev Lead, 3 Opus in parallel via Task tool)
- Stage 4: Critical Analyst (Opus, solo last — receives ALL prior outputs)
- Stage 5: Synthesis (orchestrator reads all 5 outputs, writes synthesis, AskUserQuestion, Critical Evaluation Gate)
- Stage 6: Diagnostics (YAML to logs/diagnostics/)

**5 Role Reference Files** in `references/`:
- `role-project-sme.md` — autonomous codebase explorer
- `role-product-manager.md` — user value and scope
- `role-technical-architect.md` — system design and patterns
- `role-development-lead.md` — feasibility and effort
- `role-critical-analyst.md` — cost-benefit, assumptions, kill criteria (includes "Highest-Risk Assumption Focus" reasoning depth)

**4 Templates** in `templates/`:
- `role-output.md` — YAML header (role, topic, recommendation, key_findings) + Markdown body
- `critic-output.md` — YAML header (verdict, conditions, key_challenges) + Markdown body
- `synthesis-output.md` — consensus, divergence, verdict, implementation outline, risks
- `diagnostic-output.yaml` — invocation metadata, per-agent status, token checkpoints

**Critical invariants that must not change:**
- The --scoped sequential flow (SME first, Critic last) is the core design — Critic needs ALL prior outputs
- SME autonomy: no hardcoded document paths, agent discovers relevant files
- 4-part prompt template (GOAL/CONSTRAINTS/CONTEXT/OUTPUT) via subagent-prompting dependency
- Critical Evaluation Gate classifies user responses (Preference/Technical Claim/Architectural Suggestion) and spawns targeted follow-up agents
- SA2 compliance: all output to `logs/brainstorm/{topic-slug}/`
- Completion checklist (16 items) enforced before returning to user

### 2. Existing Assets That Relate To or Would Be Affected

**Directly modified:**
- `skills/bulwark-brainstorm/SKILL.md` — must add mode argument parsing, pre-flight env var detection, and Stage 3B (AT mode) alongside existing Stage 3A (Task tool mode). The --scoped flow becomes Stage 3A; --exploratory becomes Stage 3B.
- `.claude/skills/bulwark-brainstorm/SKILL.md` — dogfood copy, must stay in sync
- `templates/diagnostic-output.yaml` — must add AT-specific metrics (display_mode, delegate_mode, peer_challenges_observed, teammate_count)

**Potentially modified:**
- Role reference files — if roles are consolidated for --exploratory (e.g., merging PM + Dev Lead), either create new combined references or add mode-specific sections to existing ones. Do NOT modify the existing role definitions for --scoped mode.
- `templates/synthesis-output.md` — may need a mode-aware section (debate insights vs sequential analysis)

**Affected but not modified:**
- `scripts/sync-essential-skills.sh` — line 88 maps `bulwark-brainstorm:brainstorm` for the standalone repo. The rsync already handles the full directory, so new files (e.g., a combined role reference) will sync automatically. No script change needed unless new file naming breaks the rename transform.
- `plans/tasks.yaml` — P5.15 task entry already exists (lines 217-247) with correct acceptance criteria

**Upstream dependency:**
- P5.13 plan-creation is NOT a code dependency but IS the architectural pattern source. P5.13's sandwich structure (shared Pre-Flight/Synthesis/Diagnostics, mode-specific team stage) should be built first so that --exploratory can reuse validated patterns. Per tasks.yaml execution order, P5.13 implementation precedes P5.15 implementation (Session 67+).

### 3. Integration Points — Where Does --exploratory Connect?

**Mode detection (Pre-Flight, Stage 1):**
The pattern is established in P5.13's task brief (lines 229-239): check `$CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` env var. If set, offer user choice between --scoped and --exploratory. If not set, use --scoped and notify if user explicitly requested --exploratory. This is identical logic — reuse directly.

**Argument parsing:**
Current arguments: `<topic-or-prompt> [--research <file>] [--doc <path>]`
New arguments: add `--scoped` (default) and `--exploratory` as mutually exclusive mode flags. If neither specified, default to --scoped (preserving backward compatibility for existing users).

**Output directory:**
Both modes write to `logs/brainstorm/{topic-slug}/`. File naming within the directory may differ: --scoped uses `01-project-sme.md` through `05-critical-analyst.md`; --exploratory could use `01-sme.md` (solo, pre-AT) + `02-debate-log.md` + per-teammate outputs. The synthesis file (`synthesis.md`) must exist in both modes.

**subagent-prompting dependency:**
The `subagent-prompting` skill declared in frontmatter provides the 4-part prompt template. This applies to both modes — Agent Teams teammates still need structured prompts. No change to frontmatter needed.

**Critical Evaluation Gate:**
The gate (SKILL.md lines 186-227) runs after synthesis in both modes. It spawns follow-up Opus agents via Task tool (not Agent Teams). This is correct: follow-up validation is a focused verification task, not a debate. No change needed.

### 4. Constraints Imposed by Current Design Decisions

**Agent count cap (3-4):** From the Agent Teams research synthesis, coordination overhead dominates beyond 3-4 teammates. The current --scoped mode has 5 roles. --exploratory cannot use all 5 as AT teammates. P5.13's solution: run one role solo via Task tool first (PO in plan-creation, SME in brainstorm), then spawn 3 AT teammates. This is the correct pattern for --exploratory: SME solo first (same as --scoped), then 3 AT teammates debate, plus the lead in delegate mode.

**SA2 dual-output contract:** Per P5.13 FR4 and the research synthesis post-synthesis decisions, AT teammates must write full analysis to `logs/brainstorm/{topic-slug}/{NN}-{role}.md` AND send 3-5 sentence coordination summaries to the mailbox. This is a prompt engineering requirement, not an architectural one.

**In-process display mode:** WSL2 safe default. No tmux dependency. Hardcode this in the skill.

**Delegate mode for lead:** The lead (orchestrator) enters delegate mode and does not implement — it only coordinates. This prevents the lead from doing the brainstorm analysis itself.

**Token cost ~2x:** Agent Teams mode consumes approximately twice the tokens of Task tool mode. The existing token budget thresholds (30% pre-spawn, 55% checkpoint, 65% post-synthesis) may need adjustment for --exploratory, or the skill should warn users that --exploratory consumes more context.

**Backward compatibility:** `--scoped` must be the default. Invoking `/bulwark-brainstorm <topic>` without a mode flag must produce identical behavior to today. This is non-negotiable.

### 5. What the Project Already Does Well That Must Not Be Disrupted

**Proven pipeline structure:** The 6-stage architecture with pre-flight interview, sequenced agents, synthesis, Critical Evaluation Gate, and diagnostics has been validated across 6+ brainstorm sessions (Sessions 59, 60, 63, 64, 65, and the current session). Do not restructure this — extend it.

**SME autonomy pattern:** The SME agent explores the codebase independently using Glob/Grep/Read with no hardcoded paths. This makes the skill portable. The --exploratory mode must preserve this: SME runs solo first (identical to --scoped), then feeds output to AT teammates.

**Critical Evaluation Gate:** The classification-based post-synthesis gate (Preference/Technical Claim/Architectural Suggestion) with optional follow-up validation agents is a unique quality mechanism. It prevents blind incorporation of unvalidated user input. Both modes must use it.

**Template-driven output:** All agents use standardized templates (role-output.md, critic-output.md, synthesis-output.md). AT teammates should use compatible templates so the synthesis stage can process outputs uniformly regardless of mode.

**Diagnostic completeness:** The diagnostic YAML captures per-agent status, retry counts, token checkpoints, and interview metadata. AT mode must extend (not replace) this schema.

## Files Explored

| File | Relevance |
|------|-----------|
| `/mnt/c/projects/the-bulwark/.claude/skills/bulwark-brainstorm/SKILL.md` | Primary artifact being extended — full skill definition (391 lines) |
| `/mnt/c/projects/the-bulwark/.claude/skills/bulwark-brainstorm/references/role-project-sme.md` | SME role definition and prompt template — must stay unchanged for --scoped |
| `/mnt/c/projects/the-bulwark/.claude/skills/bulwark-brainstorm/references/role-critical-analyst.md` | Critic role with reasoning depth instructions — key quality mechanism |
| `/mnt/c/projects/the-bulwark/.claude/skills/bulwark-brainstorm/templates/role-output.md` | Standard output template — AT teammates should produce compatible output |
| `/mnt/c/projects/the-bulwark/.claude/skills/bulwark-brainstorm/templates/synthesis-output.md` | Synthesis template — must work for both sequential and debate-driven inputs |
| `/mnt/c/projects/the-bulwark/.claude/skills/bulwark-brainstorm/templates/diagnostic-output.yaml` | Diagnostic schema — must be extended for AT metrics |
| `/mnt/c/projects/the-bulwark/plans/task-briefs/P5.13-plan-creation.md` | Architectural pattern source — sandwich structure, mode detection, dual-output contract |
| `/mnt/c/projects/the-bulwark/logs/research/agent-teams/synthesis.md` | Agent Teams research — constraints, decisions, applicability matrix |
| `/mnt/c/projects/the-bulwark/plans/tasks.yaml` | P5.15 task definition, execution order, acceptance criteria |
| `/mnt/c/projects/the-bulwark/plans/task-briefs/P5.14-research-brainstorm.md` | Original design decisions for bulwark-brainstorm (Session 59) |
| `/mnt/c/projects/the-bulwark/scripts/sync-essential-skills.sh` | Sync script — confirms brainstorm:bulwark-brainstorm rename mapping |
| `/mnt/c/projects/the-bulwark/skills/bulwark-brainstorm/SKILL.md` | Source copy — confirmed identical to .claude/skills/ dogfood copy |
