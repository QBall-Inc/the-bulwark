# Template: Research / Multi-Agent Skill

Use this template when the skill spawns multiple agents for parallel or sequential analysis on a topic. Typical for research workflows, brainstorming, and multi-perspective analysis.

**When to use**: Decision B = parallel or sequential multi-agent, AND the skill's purpose is research, exploration, or multi-viewpoint analysis.

---

## File Structure

```
skills/{skill-name}/
├── SKILL.md
├── references/
│   ├── {viewpoint-or-role-1}.md
│   ├── {viewpoint-or-role-2}.md
│   └── {viewpoint-or-role-N}.md
└── templates/
    ├── {agent-output-template}.md
    ├── {synthesis-output-template}.md
    └── diagnostic-output.yaml
```

## Generated SKILL.md Structure

```markdown
---
name: {skill-name}
description: {single-line, trigger-specific, "Use when..." framing}
user-invocable: true
argument-hint: "<topic, filepath, or directory>"
skills:
  - subagent-prompting
version: 1.0.0
author: "Ashay Kubal @ Qball Inc."
---

# {Skill Title}

{One-paragraph summary: what the skill researches/analyzes, how many agents, parallel vs sequential, what the output is.}

---

## When to Use This Skill

{Trigger pattern table + DO NOT use for section.}

---

## Dependencies

| Category | Files | Requirement | When to Load |
|----------|-------|-------------|--------------|
| **Viewpoint/Role definitions** | `references/{name}.md` | **REQUIRED** | Load all before spawning agents |
| **Agent output template** | `templates/{name}.md` | **REQUIRED** | Include in every agent prompt |
| **Synthesis template** | `templates/{name}.md` | **REQUIRED** | Use when writing synthesis |
| **Diagnostics** | `templates/diagnostic-output.yaml` | **REQUIRED** | Write at completion |
| **Prompting** | `subagent-prompting` skill | **REQUIRED** | Load for 4-part prompt template |

---

## Usage

```
/{skill-name} <topic> [flags]
```

---

## Mandatory Execution Checklist (BINDING)

**Every item below is mandatory. No deviations. No substitutions. No skipping. Skipping items violates SC1-SC3 (Skill Compliance Rules in Rules.md).**

This skill spawns multiple sub-agents for research/analysis. You are the orchestrator, NOT the analyst. Follow every item in order. Do NOT return to the user until all applicable items are checked.

- [ ] **Stage 0 — Interview**: AskUserQuestion conducted (1-2 rounds to clarify research topic)
- [ ] **Stage 0 — Pre-Flight**: All viewpoint/role reference files loaded
- [ ] **Stage 0 — Pre-Flight**: Output templates loaded
- [ ] **Stage 1 — Agents**: All agents spawned per pipeline (parallel or sequential) — you MUST NOT analyze the topic yourself
- [ ] **Stage 1 — Agents**: Sub-agents NOT spawned with `run_in_background: true` (SA5)
- [ ] **Stage 1 — Agent outputs** written to `$PROJECT_DIR/logs/{skill-name}/`
- [ ] **Stage 2 — Synthesis**: ALL agent outputs read, convergent + divergent findings identified
- [ ] **Stage 2 — Synthesis**: Synthesis written to `$PROJECT_DIR/artifacts/{skill-name}/{slug}/synthesis.md` (NOT to `logs/`)
- [ ] **Stage 3 — Diagnostics**: Diagnostic YAML written to `$PROJECT_DIR/logs/diagnostics/`
- [ ] **Key findings presented to user**

---

## Pipeline

```fsharp
// {skill-name} pipeline — {parallel/sequential}
Interview(topic)
|> LoadViewpoints(references/)
|> SpawnAgents([Agent1, Agent2, ..., AgentN])  // {parallel/sequential}
|> Synthesize(all_agent_outputs)
|> Present(synthesis)
|> Diagnostics()
```

---

## Stage Definitions

### Stage 0: Interview (Orchestrator)

```
Stage 0: Interview
├── AskUserQuestion: Clarify topic scope and focus areas
│   ├── Round 1: 2-3 scoping questions
│   └── Round 2 (if needed): 1-2 follow-ups for ambiguous answers
├── Load all viewpoint/role references from references/
├── Load output templates from templates/
└── Token budget check
```

### Stage 1: Agent Spawning ({Parallel/Sequential})

For each viewpoint/role:

```
Construct prompt using 4-part template:
├── GOAL: Analyze {topic} from the {viewpoint/role} perspective
├── CONSTRAINTS: Focus on {viewpoint-specific scope}, read-only analysis
├── CONTEXT: Topic description, relevant files/codebase areas,
│   viewpoint definition from references/{name}.md
└── OUTPUT: Write to $PROJECT_DIR/logs/{skill-name}/{agent-name}.md
            using templates/{agent-output-template}.md format

Spawn: Task(subagent_type="general-purpose", model="{model}", prompt=...)
```

**IMPORTANT — output paths**: `$PROJECT_DIR` is the project root directory (where `.claude/` lives). All paths MUST be project-root-relative using this prefix. Do NOT write to the skill directory or CWD.

**Parallel**: Spawn all agents without waiting for each other.
**Sequential**: Each agent reads previous agent's output before running.

### Stage 2: Synthesis (Orchestrator)

```
Stage 2: Synthesis
├── Read all agent outputs from $PROJECT_DIR/logs/{skill-name}/
├── Identify convergent findings (multiple agents agree)
├── Identify divergent findings (agents disagree — flag for user)
├── Write synthesis to $PROJECT_DIR/artifacts/{skill-name}/{topic-slug}/synthesis.md
│   using templates/{synthesis-output-template}.md format
└── Present key findings to user
```

**Note**: Synthesis is a deliverable — it goes to `artifacts/`, not `logs/`. Agent intermediate output stays in `logs/`.

### Stage 3: Diagnostics (REQUIRED)

Write to `$PROJECT_DIR/logs/diagnostics/{skill-name}-{YYYYMMDD-HHMMSS}.yaml`

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Agent returns empty output | Re-spawn once. If still empty, note in synthesis and continue with remaining agents. |
| Agent produces off-topic analysis | Note in synthesis. Do not re-spawn — off-topic output often reveals unexpected angles. |
| Token budget exceeded mid-pipeline | Complete current agent, skip remaining, synthesize from available outputs. |
```

## Generated Viewpoint/Role File Structure

Each file in `references/` defines one agent's perspective:

```markdown
# {Viewpoint/Role Name}

## Identity

You are a {role description}. Your analytical focus is {scope}.

## Analytical Lens

When analyzing a topic, you prioritize:
1. {Priority 1}
2. {Priority 2}
3. {Priority 3}

## Output Expectations

- {What findings from this viewpoint typically look like}
- {Level of specificity expected}
- {How this viewpoint differs from others in the pipeline}
```

## Common Sub-Patterns

Research skills exhibit several recurring sub-patterns. Sub-patterns are additive — pick those that apply.

### `reviewer-validated`

**Definition**: Research skill embeds a Reviewer-shaped validation gate (often called a "Critical Evaluation Gate") that challenges or grounds findings before synthesis. Without this sub-pattern, multi-viewpoint research can synthesize speculative claims as fact.

**When to use**: Default ON for any Research skill whose findings will drive downstream decisions. Per Anthropic faithfulness research (April 2025), unchallenged multi-agent output is unreliable ground truth.

**Bulwark example**: `bulwark-research` includes a Critical Evaluation Gate that classifies findings (Factual / Opinion / Speculative) and triggers targeted follow-up agents for unvalidated claims; `plan-creation-architect` / `plan-creation-eng-lead` / `plan-creation-po` SHOULD adopt this pattern (currently missing — see `existing-skills-archetype-mapping.md`).

**How it shapes the skill**:
- Add an explicit "Critical Evaluation Gate" stage between agent spawning and synthesis.
- Gate classifies findings and routes high-uncertainty claims to a Reviewer-shaped follow-up agent.
- Synthesis incorporates ONLY claims that passed the gate (or explicitly flags un-validated claims).
- Reference Reviewer template's `multi-source` sub-pattern when authoring the gate's logic.

### `source-tier-disciplined`

**Definition**: Research skill enforces explicit source-tier classification (T1 = primary/canonical, T2 = secondary/expert, T3 = community/unverified) on cited sources.

**When to use**: Web-search-heavy research where source quality varies wildly. Without source tiers, synthesis treats reddit posts and academic papers equivalently.

**Bulwark example**: `bulwark-research` (~52 T1 / ~30 T2 / ~22 T3 in the S105 effort); `product-ideation-market-researcher` and `product-ideation-competitive-analyzer` apply tier discipline implicitly.

**How it shapes the skill**:
- Each agent's output schema includes a `source_tiers` field summarizing T1/T2/T3 counts.
- Synthesis stage cross-validates T3 claims against T1/T2 evidence (do NOT promote T3-only HIGH-confidence findings).
- Document the tier definitions in `references/source-tiers.md`.

---

## Guidance for Generator

- Research/brainstorm skills are the most token-intensive — warn about budget
- Parallel agents save time but cost more tokens; sequential agents build on each other
- The synthesis is the deliverable — agent outputs are intermediate artifacts
- Model selection: Sonnet for research/analysis, Opus for brainstorming/creative
- 3-5 agents is the sweet spot — fewer lacks diversity, more exceeds token budgets
- Include `argument-hint` in frontmatter for better UX in the `/` menu
- Viewpoint/role reference files should be 40-80 lines each
- **Default the `reviewer-validated` sub-pattern ON** for new Research skills — multi-viewpoint output without challenge is unreliable per Anthropic faithfulness research
