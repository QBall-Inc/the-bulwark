---
role: technical-architect
topic: "P5.13 Plan-Creation Skill — Agent Teams Dual-Mode"
recommendation: proceed
key_findings:
  - "Dual-mode requires two distinct orchestration paths in SKILL.md — shared Pre-Flight and Synthesis stages bookend mode-specific Stage 3 (agent spawning). Not a simple if/else; the agent interaction model, coordination mechanism, and synthesis input differ fundamentally between modes."
  - "Plan output format: YAML with Markdown preamble (hybrid). YAML for the structured plan body (phases, workpackages, dependencies, milestones) because it is token-efficient and machine-parseable. Markdown preamble for the executive summary and rationale sections that benefit from prose. This aligns with CLEAR's master-plan.yaml schema without depending on it."
  - "SA2 compliance in Agent Teams mode requires a dual-output contract in every teammate prompt: full analysis to logs/ (SA2 artifact), coordination summary to mailbox (Agent Teams pattern). The skill must verify log output exists before synthesis — mailbox content alone is not SA2-compliant."
  - "The skill MUST detect Agent Teams availability during Pre-Flight via environment variable check ($CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS), not at spawn time. Graceful degradation to Task tool mode with a user notification, not a silent fallback."
---

# P5.13 Plan-Creation Skill — Senior Technical Architect

## Summary

The plan-creation skill requires a sandwich architecture: shared pre-flight and synthesis stages wrapping a mode-specific orchestration core. The dual-mode design is not a runtime toggle on a single execution path — Agent Teams and Task tool have structurally different agent interaction models that demand separate Stage 3 implementations. The plan output format should be YAML with a Markdown preamble, aligning with CLEAR's `MasterPlan` type interface without creating a hard dependency on it.

## Detailed Analysis

### Architectural Approach

Structure the SKILL.md as five stages with mode bifurcation at Stage 3:

```
Stage 1: Pre-Flight (SHARED)
  - Parse input, slugify topic, create logs/plan-creation/{slug}/
  - Detect mode: check $CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS
  - If Agent Teams requested but env var absent: notify user, fall back to Task tool
  - AskUserQuestion for scope boundaries (project name, tech stack, constraints)
  - Load subagent-prompting skill

Stage 2: Context Gathering (SHARED)
  - Spawn Product Owner agent (Opus, Task tool in both modes)
  - PO explores codebase autonomously (same pattern as brainstorm's Project SME)
  - PO output: logs/plan-creation/{slug}/01-product-owner.md
  - This stage is identical in both modes — PO runs first, alone

Stage 3A: Scrum Team — Task Tool Mode
  - Spawn [Architect, Engineering Lead, Delivery Lead] in parallel via 3 Task tool calls
  - Each reads PO output + problem statement
  - Each writes to logs/plan-creation/{slug}/{NN}-{role}.md
  - Then spawn QA/Critic sequentially with all prior outputs

Stage 3B: Scrum Team — Agent Teams Mode
  - Lead enters delegate mode (coordination only, no implementation)
  - Spawn 4 teammates: Architect, Engineering Lead, Delivery Lead, QA/Critic
  - Each teammate prompt includes dual-output contract:
    "Write full analysis to logs/plan-creation/{slug}/{NN}-{role}.md
     Send 3-5 sentence summary to peers via mailbox"
  - Peer debate phase: explicit challenge prompts
    ("Challenge the Architect's dependency assumptions",
     "Verify Engineering Lead's effort estimates against codebase")
  - QA/Critic participates throughout (not gated until end)
  - In-process display mode (WSL2 safe)

Stage 4: Synthesis (SHARED, mode-aware input)
  - Task tool mode: Read all 5 log files sequentially
  - Agent Teams mode: Read all 5 log files + lead's coordination notes
  - Write plan artifact using plan output template
  - AskUserQuestion for approval gate (explore-then-commit)
  - Critical Evaluation Gate on user responses

Stage 5: Diagnostics (SHARED)
  - Write diagnostic YAML to logs/diagnostics/
```

The PO runs first in both modes via Task tool because the PO's codebase exploration output anchors all subsequent agents — there is no benefit to starting the PO as a teammate in Agent Teams mode. This matches brainstorm's SME-first pattern from `/mnt/c/projects/the-bulwark/skills/bulwark-brainstorm/SKILL.md` (Stage 2).

The key structural difference in Agent Teams mode is that the QA/Critic participates throughout the debate rather than running last. In Task tool mode, the Critic must run last (sequential constraint). In Agent Teams mode, the Critic challenges in real-time via mailbox — this is the primary quality advantage Agent Teams provide for plan creation.

### Design Patterns

**Follow directly from bulwark-brainstorm:**
- Directory structure: `skills/plan-creation/SKILL.md` + `references/role-{product-owner,technical-architect,engineering-lead,delivery-lead,qa-critic}.md` + `templates/{role-output,plan-output,critic-output,synthesis-output,diagnostic-output}.md`
- Frontmatter: `name: plan-creation`, `description:` (single line), `user-invocable: true`, `skills: [subagent-prompting]`
- 4-part prompt template (GOAL/CONSTRAINTS/CONTEXT/OUTPUT) per SA1
- F# pipe syntax for both modes documented in SKILL.md
- Error handling: single retry on agent failure, SME/PO failure is fatal

**New patterns for plan-creation:**
- Mode detection in Pre-Flight (not at spawn time) — fail fast per CS3
- Dual-output contract in Agent Teams prompts (logs/ + mailbox)
- Plan output template (new, not reused from brainstorm)
- Approval gate before finalizing plan (explore-then-commit workflow)

**Patterns to avoid:**
- Do NOT create a shared base class or abstraction layer for the two modes. They are two separate execution paths within one SKILL.md. Premature abstraction adds complexity with no reuse benefit — P5.15 (brainstorm exploratory) will have its own Agent Teams integration, not share plan-creation's.
- Do NOT use `context: fork` for the skill. Plan-creation is orchestrator-driven (same as brainstorm), not a forked agent.
- Do NOT default to Agent Teams mode. Task tool is the default because it is production-stable and SA2-compliant by construction. Agent Teams is opt-in via explicit env var.

### Plan Output Format

**Use YAML with Markdown preamble.** The analysis:

| Format | Token Efficiency | Machine Parseability | LLM Readability | Verdict |
|--------|-----------------|---------------------|-----------------|---------|
| Pure Markdown | Low (verbose headers, no structure) | Poor (regex parsing) | High | Reject — downstream tools cannot reliably parse |
| Pure YAML | High (compact, structured) | Excellent | Medium (deep nesting hurts) | Reject — executive summary and rationale need prose |
| **Hybrid (Markdown preamble + YAML body)** | **High for structure, good for prose** | **YAML body parseable, preamble human-readable** | **High** | **Accept** |

The plan output template should be:

```markdown
# {Project Name} — Implementation Plan

## Executive Summary
{2-3 paragraphs of prose — goal, approach, key risks}

## Plan
```yaml
version: "1.0"
project_name: "{name}"
created: "{ISO date}"
created_by: "plan-creation skill"

phases:
  - id: "phase_1"
    name: "{Phase 1 Name}"
    status: "not_started"
    workpackages:
      - id: "WP1"
        name: "{Workpackage name}"
        description: "{What this delivers}"
        estimated_sessions: {N}
        dependencies: []
      - id: "WP2"
        name: "{Workpackage name}"
        dependencies: ["WP1"]

milestones:
  - id: "m1"
    name: "{Milestone name}"
    phase: "phase_1"
    type: "major"
    requires: ["WP1", "WP2"]

dependency_graph:
  critical_path: ["WP1", "WP2", "WP5"]
  parallel_opportunities:
    - ["WP3", "WP4"]
```
```

This format aligns with CLEAR's `MasterPlan` interface (`/mnt/c/projects/clear-framework/src/infrastructure/plan/types.ts`) — same `phases[].id`, `phases[].status`, `milestones[].type`, `milestones[].requires` fields — without importing or depending on CLEAR's types. If CLEAR's `parseMasterPlanContent()` function (`/mnt/c/projects/clear-framework/src/infrastructure/plan/parser.ts`) needs to consume this output in the future, the YAML body is structurally compatible. The `workpackages` field uses inline objects rather than string IDs (CLEAR uses string IDs referencing a separate workpackage registry), but the mapping is straightforward.

Token efficiency: The YAML body for a 3-phase, 12-workpackage plan is approximately 400-600 tokens. The equivalent Markdown table or prose description would be 800-1200 tokens. For LLM consumption in downstream tools (task brief generation, dependency analysis), YAML is 40-50% more token-efficient.

### Integration Architecture

**1. Bulwark skills (primary context):**
- Skill lives at `skills/plan-creation/` following the same structure as `skills/bulwark-brainstorm/` (`/mnt/c/projects/the-bulwark/skills/bulwark-brainstorm/`)
- Dogfood copy at `.claude/skills/plan-creation/`
- Depends on `subagent-prompting` skill (declared in frontmatter)
- Output goes to `logs/plan-creation/{slug}/` (SA2 compliant)
- Pipeline template reference added to `skills/pipeline-templates/references/plan-creation.md`

**2. Essential Skills repo (P2 context):**
- Self-contained: no cross-skill dependencies beyond subagent-prompting
- No hardcoded paths — PO agent discovers project structure autonomously
- `scripts/sync-essential-skills.sh` updated to include plan-creation directory
- `just` commands in references transformed to `npx tsx` during rsync (existing pattern)

**3. CLEAR Framework (P1 context):**
- Plan output format is compatible with CLEAR's `MasterPlan` type but does not import it
- CLEAR's plan-management skill (`/cf-plan create`) would call plan-creation as a dependency or consume its output file
- The plan-creation skill does NOT implement plan management (progress tracking, timeline adjustment, blocker detection) — those are CLEAR's responsibility per the SME analysis boundary
- If CLEAR needs tighter integration later, the YAML body can be parsed by CLEAR's existing `parseMasterPlanContent()` with minor field mapping

**4. Agent Teams coordination files:**
- `~/.claude/teams/` and `~/.claude/tasks/` — Linux-native FS, fast on WSL2
- These are managed by Claude Code's Agent Teams infrastructure, not by the skill
- The skill only needs to: (a) set delegate mode for the lead, (b) define teammate prompts with the dual-output contract, (c) specify in-process display mode

### Technical Trade-offs

**Trade-off 1: PO always via Task tool vs. PO as Agent Teams teammate**

Decision: PO always via Task tool. The PO's job is codebase exploration — a solo activity that does not benefit from peer messaging. Running PO via Task tool keeps both modes identical through Stage 2, reducing divergence surface area. The PO output is the foundation for all subsequent agents in both modes. Making PO a teammate would delay the other teammates (they need PO output before they can meaningfully contribute), wasting Agent Teams' token budget on idle teammates.

**Trade-off 2: QA/Critic as active participant vs. final reviewer in Agent Teams mode**

Decision: Active participant in Agent Teams mode, final reviewer in Task tool mode. This is the core architectural difference between modes. In Task tool mode, the Critic MUST run last because it needs all prior outputs (sequential constraint). In Agent Teams mode, the Critic can challenge proposals in real-time via mailbox. This enables the peer debate that justifies Agent Teams' ~2x token cost. If the Critic only ran last in both modes, Agent Teams would provide no quality advantage over Task tool.

**Trade-off 3: Single plan template vs. mode-specific templates**

Decision: Single plan template. The plan output should be identical regardless of which mode produced it. The mode affects the process (how agents collaborate), not the product (what the plan looks like). Using different templates would create a comparison problem — how do you evaluate whether Agent Teams produces better plans if the format differs?

**Trade-off 4: YAML-only vs. hybrid plan format**

Decision: Hybrid (Markdown preamble + YAML body). Pure YAML is more token-efficient but executive summaries and rationale sections are unreadable as nested YAML strings. The preamble is for humans; the YAML body is for machines and LLMs. The cost is approximately 100-150 additional tokens for the preamble — negligible relative to the plan body.

**Trade-off 5: 5 agents vs. 3 agents (reduced team)**

Decision: 5 agents. Research synthesis caps effective team size at 3-4 before coordination overhead dominates. However, the 5-role scrum team maps to distinct concerns (product scope, architecture, implementation feasibility, delivery scheduling, quality assurance) that cannot be meaningfully collapsed. The risk is coordination overhead in Agent Teams mode. Mitigation: the PO runs via Task tool (reducing active Agent Teams teammates to 4), and explicit challenge prompts structure the debate rather than allowing free-form messaging.

## Recommendation

**Proceed.** The architecture is grounded in validated codebase patterns (bulwark-brainstorm's 5-stage structure, role references, output templates, SA2 compliance), compatible with CLEAR's plan infrastructure without coupling to it, and addresses the dual-mode challenge through stage-level bifurcation rather than premature abstraction. The primary risk — SA2 compliance in Agent Teams mode — is mitigated by the dual-output contract pattern (logs/ for artifacts, mailbox for coordination) validated in the pre-brainstorm alignment. Token overhead (~2x for Agent Teams) is acceptable because plan-creation is a low-frequency, high-value activity where output quality justifies the cost.

## Files Explored

| File | Relevance |
|------|-----------|
| `/mnt/c/projects/the-bulwark/skills/bulwark-brainstorm/SKILL.md` | Direct structural template — 5-stage pipeline, role references, SA2 compliance |
| `/mnt/c/projects/the-bulwark/skills/bulwark-brainstorm/references/role-technical-architect.md` | Role reference pattern — prompt template structure, reasoning depth instructions |
| `/mnt/c/projects/the-bulwark/skills/bulwark-brainstorm/references/role-project-sme.md` | SME autonomy pattern — no hardcoded paths, codebase exploration |
| `/mnt/c/projects/the-bulwark/skills/bulwark-brainstorm/templates/role-output.md` | Output template pattern for role agents |
| `/mnt/c/projects/the-bulwark/skills/pipeline-templates/SKILL.md` | F# pipe syntax, model selection rubric, existing Research & Planning pipeline |
| `/mnt/c/projects/clear-framework/src/infrastructure/plan/types.ts` | CLEAR's MasterPlan interface — Phase, Milestone, PhaseStatus types for format compatibility |
| `/mnt/c/projects/clear-framework/src/infrastructure/plan/parser.ts` | CLEAR's YAML parser — validates that hybrid format is consumable |
| `/mnt/c/projects/clear-framework/src/infrastructure/plan/writer.ts` | CLEAR's plan writer — confirms .clear/plans/master-plan.yaml output path |
| `/mnt/c/projects/clear-framework/briefs/core/plan-management-feature-brief.md` | CLEAR's plan-management scope — confirms plan-creation produces plans, CLEAR manages them |
| `/mnt/c/projects/the-bulwark/plans/tasks.yaml` | P5.13 acceptance criteria, dependencies, verification requirements |
| `/mnt/c/projects/the-bulwark/logs/research/agent-teams/synthesis.md` | Agent Teams research — 5 viewpoints, SA2 compliance approach, WSL2 constraints |
| `/mnt/c/projects/the-bulwark/logs/brainstorm/plan-creation/01-project-sme.md` | SME output — existing plan infrastructure, skill patterns, integration points |
| `/mnt/c/projects/the-bulwark/Rules.md` | Immutable contract — CS1-CS3, SA rules, SC1-SC3 |
| `/mnt/c/projects/the-bulwark/CLAUDE.md` | Project rules — OR1-OR4, SA1-SA6, task conventions |
