---
role: project-sme
topic: "P5.13 Plan-Creation Skill — Agent Teams Dual-Mode"
recommendation: proceed
key_findings:
  - CLEAR Framework plan-management brief defines a comprehensive plan infrastructure (master-plan.yaml, change-log, DAG dependencies, multi-signal progress, blocker detection) that the plan-creation skill must be AWARE OF but NOT COUPLED TO — the skill creates plans, CLEAR manages them
  - Bulwark's bulwark-brainstorm skill is the exact structural template for plan-creation — same 5-role sequential pattern (SME-first, 3 parallel, Critic-last), same 4-part prompting, same SA2 compliance, same diagnostics — but plan-creation replaces roles with a scrum team and adds Agent Teams as primary mode
  - Three-context portability (CLEAR P1, Essential Skills P2, Bulwark P3) is achievable because the skill follows the same self-contained pattern as existing portable skills — SKILL.md + references/ + templates/ with no project-specific hardcoded paths — but Agent Teams env var gating needs graceful degradation to Task tool
  - Agent Teams mode requires fundamentally different orchestration architecture from Task tool mode — peer-to-peer mailbox messaging with delegate-mode lead vs hub-and-spoke sequential spawning — making this a dual-implementation, not a simple if/else branch
  - SA2 compliance in Agent Teams mode is the primary technical risk — teammates must write artifacts to logs/ (SA2 requirement) AND coordinate via mailbox (Agent Teams pattern), requiring explicit dual-output instructions in every teammate prompt
---

# P5.13 Plan-Creation Skill — Project SME

## Summary

The plan-creation skill fits into a well-established multi-agent skill pattern in Bulwark, with bulwark-brainstorm as its direct structural ancestor. The CLEAR Framework provides a comprehensive plan-management infrastructure that defines what plans look like and how they are tracked, but the plan-creation skill's job is strictly to PRODUCE plans, not manage them. The primary architectural challenge is the dual-mode implementation — Agent Teams and Task tool require fundamentally different orchestration patterns, not just a runtime switch.

## Detailed Analysis

### Existing Plan Infrastructure (CLEAR Framework)

The CLEAR Framework at `/mnt/c/projects/clear-framework` has a detailed plan-management feature brief (`/mnt/c/projects/clear-framework/briefs/core/plan-management-feature-brief.md`) that defines:

1. **Master plan structure**: Hierarchical YAML format at `.clear/plans/master-plan.yaml` with phases, workpackages, milestones, and a dual-ID architecture (phase IDs like `phase_1` and workpackage IDs like `TD3`).

2. **Multi-signal progress tracking**: Weighted aggregation — workpackages (0.4), commits (0.2), tests (0.2), documentation (0.1), integration (0.1) — with confidence scoring.

3. **Dependency graph**: DAG with hard/soft/optional dependency types, critical path analysis, cycle detection, and parallelization opportunity identification.

4. **CLI commands**: `/cf-plan create`, `addPhase`, `status`, `next`, `blockers`, `adjust`, `milestone`, `timeline`.

5. **Change tracking**: Lightweight change-log approach (deltas only, ~50-100 tokens per change) rather than full snapshots.

6. **Blocker management**: Detection, classification (dependency/technical/resource/decision), severity assessment, escalation workflows.

The CLEAR Framework is currently on hiatus (no `.clear/` data directory exists, no skills implemented beyond a basic skill-creator and test-writing-discipline). The plan infrastructure is fully designed but not yet built.

**What plan-creation should adopt**: The master plan YAML schema (phases with workpackage identifiers, milestone definitions, dependency types). The plan-creation skill's output format should be compatible with — but not dependent on — this schema so that CLEAR's plan-management skill can eventually consume it.

**What plan-creation must NOT do**: It must not implement plan management (progress tracking, timeline adjustment, blocker detection, next-step recommendations). Those are CLEAR's plan-management skill's responsibilities. The plan-creation skill produces the initial plan artifact; CLEAR manages it over time. This boundary is critical for portability — in contexts P2 (Essential Skills) and P3 (Bulwark), there is no CLEAR infrastructure to depend on.

### Existing Skill Patterns (Bulwark)

Bulwark has 22 skills (`/mnt/c/projects/the-bulwark/skills/`) and 8 agents (`/mnt/c/projects/the-bulwark/.claude/agents/`). The multi-agent skills most relevant to plan-creation:

**bulwark-brainstorm** (`/mnt/c/projects/the-bulwark/.claude/skills/bulwark-brainstorm/SKILL.md`):
- 5 Opus sub-agents in sequenced pipeline: SME (solo, first) -> PM + Architect + Dev Lead (parallel) -> Critical Analyst (solo, last) -> Synthesis (orchestrator)
- Uses Task tool for all spawning (SA2 compliant)
- Self-contained: SKILL.md + `references/role-*.md` (5 files) + `templates/` (role-output, critic-output, synthesis-output, diagnostic-output)
- AskUserQuestion for pre-flight clarification and post-synthesis review
- Critical Evaluation Gate for user responses (Preference/Technical Claim/Architectural Suggestion classification)
- F# pipe syntax: `ProjectSME |> [PM, Architect, DevLead] |> CriticalAnalyst |> Synthesis`
- Token budget management with defined thresholds (30%, 55%, 65%)
- Error handling with single-retry for failed agents
- Diagnostic YAML output (mandatory)

**bulwark-research** (`/mnt/c/projects/the-bulwark/.claude/skills/bulwark-research/SKILL.md`):
- 5 Sonnet sub-agents, all parallel (different viewpoints, same topic)
- Same structural patterns: SKILL.md + references/ + templates/, 4-part prompting, SA2, diagnostics
- Critical Evaluation Gate with different classification (Factual/Opinion/Speculative)

**pipeline-templates** (`/mnt/c/projects/the-bulwark/.claude/skills/pipeline-templates/SKILL.md`):
- Defines F# pipe syntax conventions: `|>` for sequential, `[]` for parallel, `LOOP(max=N)` for iteration
- Model selection rubric: Haiku (lookups), Sonnet (review/analyze), Opus (write/fix)
- Already has a Research & Planning pipeline: `Researcher |> PlanDraft |> PlanReviewer |> LOOP(min=3)`

**subagent-prompting** (`/mnt/c/projects/the-bulwark/.claude/skills/subagent-prompting/SKILL.md`):
- 4-part template: GOAL/CONSTRAINTS/CONTEXT/OUTPUT
- Required dependency for all multi-agent skills

**Patterns to follow for plan-creation**:
- Directory structure: `skills/plan-creation/SKILL.md` + `references/` + `templates/`
- Frontmatter: `name`, `description` (single line — multi-line breaks discovery per GitHub #9817), `user-invocable: true`, `skills: [subagent-prompting]`
- Stages: Pre-Flight -> Role Agents -> Synthesis -> Diagnostics
- SA2: All agent output to `logs/brainstorm/{topic-slug}/` (or equivalent path)
- Diagnostic YAML to `logs/diagnostics/`
- SME agent explores codebase autonomously (no hardcoded paths) — same pattern as brainstorm

### Integration Points

1. **Task tool (existing)**: The plan-creation skill's fallback mode uses the same Task tool spawning pattern as bulwark-brainstorm. No new infrastructure needed.

2. **Agent Teams (new)**: The primary mode requires the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` environment variable. This is the FIRST Bulwark skill to use Agent Teams — it is the proving ground. Integration points:
   - `~/.claude/teams/` and `~/.claude/tasks/` for coordination files (Linux-native FS, fast on WSL2)
   - Delegate mode to prevent lead from implementing
   - In-process display mode (WSL2 safe default, no tmux dependency)
   - Mailbox system for peer-to-peer messaging between scrum team members

3. **Plan output format**: Must be compatible with Bulwark's `plans/task-briefs/` convention (Markdown with structured sections). For CLEAR context, should also be mappable to the master-plan YAML schema (phases, workpackage IDs, milestones, dependencies).

4. **Rsync to Essential Skills**: The existing `scripts/sync-essential-skills.sh` handles syncing skills to the standalone repo. Plan-creation must be self-contained (no cross-skill dependencies beyond `subagent-prompting`) to survive rsync.

5. **Anthropic validator**: Must pass `/anthropic-validator` with 0 critical, 0 high findings. All skills are validated against Anthropic's official patterns.

### Constraints

1. **Dual-mode is not a simple if/else**: Agent Teams mode uses peer-to-peer messaging with shared task lists; Task tool mode uses hub-and-spoke orchestration. The SKILL.md must define BOTH execution flows clearly. The synthesis stage will differ — in Agent Teams mode, the lead synthesizes from logs + mailbox coordination; in Task tool mode, the orchestrator reads sequential/parallel log outputs.

2. **SA2 compliance in Agent Teams mode**: Per pre-brainstorm alignment, artifacts go to `logs/`, mailbox is for coordination/summaries only. Every teammate prompt must include explicit dual-output instructions: "Write your full analysis to `logs/plan-creation/{slug}/{NN}-{role}.md` AND send a 3-5 sentence summary to peers via mailbox."

3. **5-role scrum team**: Product Owner, Technical Architect, Engineering Lead, Delivery Lead, QA/Critic. This is different from brainstorm's 5 roles (SME, PM, Architect, Dev Lead, Critical Analyst). The plan-creation skill needs its own `references/role-*.md` files defining each scrum team member.

4. **Output is implementation plan, not task brief**: The skill produces a master plan (phases, workpackages, milestones, dependencies) — NOT the detailed per-task briefs that live in `plans/task-briefs/`. Workpackage decomposition is downstream tooling's job.

5. **Portability**: No Bulwark-specific hardcoded paths. No CLEAR-specific schema requirements. The skill must work in any project context. The SME agent (or equivalent first-mover) explores the codebase autonomously.

6. **Token budget**: Agent Teams mode will consume ~2x tokens compared to Task tool mode (per research synthesis). The skill must warn users about this trade-off and enforce budget checkpoints.

7. **Experimental flag gating**: Agent Teams mode must gracefully degrade to Task tool mode when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is not set. This should be detected in pre-flight, not at agent-spawn time.

### What Must Not Be Disrupted

1. **bulwark-brainstorm**: The plan-creation skill must NOT modify the existing brainstorm skill. It is a separate skill with its own directory, roles, and templates. The `--scoped` / `--exploratory` mode additions are P5.15's scope, not P5.13's.

2. **Existing pipeline-templates**: The plan-creation skill should ADD a pipeline reference (`references/plan-creation.md`) to pipeline-templates, not modify existing pipeline definitions.

3. **Task tool sub-agent patterns**: All existing skills use Task tool. Plan-creation's Agent Teams mode must not set a precedent that other skills should migrate. The research synthesis is explicit: "No migration needed for current modes."

4. **SA2 rule**: The sub-agent output rule must not be amended. Agent Teams mode must comply with the existing SA2 rule through prompt engineering, not rule changes.

5. **Standalone repo sync**: The `scripts/sync-essential-skills.sh` script must be updated to include plan-creation, but existing skill syncing must not break.

## Recommendation

**Proceed.** The plan-creation skill has a clear structural template (bulwark-brainstorm), well-defined integration points, explicit constraints from both the Agent Teams research and CLEAR Framework design, and a bounded scope (produce plans, not manage them). The dual-mode architecture is the primary implementation challenge, but the pre-brainstorm alignment decisions (SA2 compliance approach, env var gating, in-process display mode) de-risk the key technical unknowns. This is the right time to build it — the research is complete, the patterns are established, and P5.13 is explicitly the next item in the execution schedule.

## Files Explored

| File | Relevance |
|------|-----------|
| `/mnt/c/projects/the-bulwark/logs/research/agent-teams/synthesis.md` | Agent Teams research — all 5 viewpoints' findings on applicability, P5.13 configuration, SA2 compliance approach |
| `/mnt/c/projects/the-bulwark/Rules.md` | Immutable contract — SC1-SC3 (skill compliance), SA rules referenced in CLAUDE.md |
| `/mnt/c/projects/clear-framework/briefs/core/plan-management-feature-brief.md` | CLEAR's plan infrastructure — master-plan schema, progress tracking, dependency graph, CLI commands |
| `/mnt/c/projects/clear-framework/plans/clear-framework-development-plan.md` | CLEAR's development plan — plugin architecture, MCP orchestration, current state (hiatus) |
| `/mnt/c/projects/the-bulwark/.claude/skills/bulwark-brainstorm/SKILL.md` | Direct structural template — 5-role sequenced pipeline, Task tool, SA2 compliance, diagnostics |
| `/mnt/c/projects/the-bulwark/.claude/skills/bulwark-research/SKILL.md` | Parallel agent pattern — 5 Sonnet viewpoints, Critical Evaluation Gate |
| `/mnt/c/projects/the-bulwark/.claude/skills/pipeline-templates/SKILL.md` | F# pipe syntax, model selection rubric, existing Research & Planning pipeline |
| `/mnt/c/projects/the-bulwark/.claude/skills/subagent-prompting/SKILL.md` | 4-part template (GOAL/CONSTRAINTS/CONTEXT/OUTPUT) — required dependency |
| `/mnt/c/projects/the-bulwark/.claude/skills/bulwark-brainstorm/references/role-project-sme.md` | SME role definition — autonomous codebase exploration pattern |
| `/mnt/c/projects/the-bulwark/plans/tasks.yaml` | Task status — P5.13 acceptance criteria, dependencies, verification requirements |
| `/mnt/c/projects/the-bulwark/plans/references.md` | External references — Agent Teams resources, ZoranSpirkovski skill |
| `/mnt/c/projects/the-bulwark/CLAUDE.md` | Project rules — OR1-OR4, SA1-SA6, task conventions, grounding clause |
