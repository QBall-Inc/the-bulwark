# Template: Pipeline Skill

Use this template when the skill orchestrates multiple distinct operations using sub-agents. Typical for review pipelines, audit workflows, and multi-stage analysis.

**When to use**: Decision B = sequential or parallel Task tool sub-agents.

---

## File Structure

Pipeline skills generate both an orchestrating skill AND dedicated sub-agent files:

```
skills/{skill-name}/
├── SKILL.md                              (orchestrating skill)
├── references/
│   ├── {stage-specific-reference-1}.md
│   └── {stage-specific-reference-N}.md
└── templates/
    ├── {output-template}.md
    └── diagnostic-output.yaml

.claude/agents/
├── {skill-name}-{stage1-name}.md         (sub-agent for stage 1)
├── {skill-name}-{stage2-name}.md         (sub-agent for stage 2)
└── {skill-name}-{stageN-name}.md         (sub-agent for stage N)
```

**Why dedicated sub-agent files**: Sub-agents defined in `.claude/agents/*.md` have deterministic behavior locked into their system prompts — consistent across invocations. Inline sub-agent definitions in skill references produce variable behavior because the orchestrator interprets the reference content differently per run.

**Naming convention**: Sub-agent files are prefixed with the skill name to avoid collisions (e.g., `code-review-security-reviewer.md`, `code-review-type-safety-reviewer.md`).

## Generated SKILL.md Structure

```markdown
---
name: {skill-name}
description: {single-line, trigger-specific, "Use when..." framing}
user-invocable: true
skills:
  - subagent-prompting
version: 1.0.0
author: "Ashay Kubal @ Qball Inc."
---

# {Skill Title}

{One-paragraph summary describing the pipeline and its purpose.}

---

## When to Use This Skill

{Trigger pattern table + DO NOT use for section.}

---

## Dependencies

| Category | Files | Requirement | When to Load |
|----------|-------|-------------|--------------|
| **Stage references** | `references/{name}.md` | **REQUIRED** | Load before spawning stage agent |
| **Output templates** | `templates/{name}.md` | **REQUIRED** | Include in sub-agent prompt |
| **Diagnostics** | `templates/diagnostic-output.yaml` | **REQUIRED** | Write at pipeline completion |
| **Prompting** | `subagent-prompting` skill | **REQUIRED** | Load before spawning any sub-agent |
| **Sub-agents** | `.claude/agents/{skill-name}-{stage}.md` | **REQUIRED** | Invoked via Task tool per stage |

---

## Usage

```
/{skill-name} {arguments} [flags]
```

---

## Mandatory Execution Checklist (BINDING)

**Every item below is mandatory. No deviations. No substitutions. No skipping. Skipping items violates SC1-SC3 (Skill Compliance Rules in Rules.md).**

This skill uses a multi-stage pipeline with dedicated sub-agents. You are the orchestrator, NOT the executor. Follow every item in order. Do NOT return to the user until all applicable items are checked.

- [ ] **Stage 0 — Pre-Flight**: All required dependencies loaded (references, templates, subagent-prompting skill)
- [ ] **Stage 0 — Pre-Flight**: Arguments parsed and validated
- [ ] **Stage 1..N — Sub-Agents**: Dedicated sub-agents spawned via Task tool — you MUST NOT perform their work yourself
- [ ] **Stage 1..N — Sub-Agents**: Sub-agents NOT spawned with `run_in_background: true` (SA5)
- [ ] **Stages executed in order** (or parallel where the pipeline specifies)
- [ ] **Intermediate outputs** written to `$PROJECT_DIR/logs/{skill-name}/`
- [ ] **Final deliverables** written to `$PROJECT_DIR/artifacts/{skill-name}/{slug}/`
- [ ] **Diagnostics**: Diagnostic YAML written to `$PROJECT_DIR/logs/diagnostics/`
- [ ] **Results presented to user**

---

## Pipeline

```fsharp
// {skill-name} pipeline
Stage0_PreFlight(args)
|> Stage1_{Name}(input)        // {skill-name}-{stage1} sub-agent — {purpose}
|> Stage2_{Name}(stage1_output) // {skill-name}-{stage2} sub-agent — {purpose}
|> Stage3_{Name}(stage2_output) // {skill-name}-{stage3} sub-agent — {purpose}
|> Diagnostics(all_outputs)
```

---

## Stage Definitions

### Stage 0: Pre-Flight (Orchestrator)

```
Stage 0: Pre-Flight
├── Parse arguments
├── Load dependencies
├── Validate inputs exist
└── Token budget check
```

### Stage 1: {Name} (Dedicated sub-agent)

```
Construct prompt using 4-part template:
├── GOAL: {what this stage achieves}
├── CONSTRAINTS: {boundaries}
├── CONTEXT: {input data, reference files to read}
└── OUTPUT: Write to $PROJECT_DIR/logs/{skill-name}/{stage1-name}-{timestamp}.{ext}

Spawn: Task(subagent_type="{skill-name}-{stage1-name}", prompt=...)
Read output from $PROJECT_DIR/logs/{skill-name}/
```

### Stage 2: {Name} (Dedicated sub-agent)

{Same structure as Stage 1, reading Stage 1 output as input.}

### Stage N: Diagnostics (REQUIRED)

Write to `$PROJECT_DIR/logs/diagnostics/{skill-name}-{YYYYMMDD-HHMMSS}.yaml`

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Sub-agent returns empty output | Re-spawn once. If still empty, STOP with error. |
| Stage fails validation | {retry/abort/skip with warning} |
| Token budget exceeded | Stop, present partial output with explanation. |
```

## Generated Sub-Agent Structure

Each pipeline stage gets a dedicated agent file at `.claude/agents/{skill-name}-{stage-name}.md`. Use the `references/agent-template.md` structure and follow `references/agent-conventions.md` conventions.

Key requirements for generated sub-agents:

- **System-prompt register**: The agent body defines WHO the agent IS, not step-by-step instructions
- **Identity reflects stage role**: "You are a security reviewer" not "You are Stage 2"
- **Single-purpose**: Each sub-agent does one thing well
- **SA2 compliant**: All intermediate output goes to `$PROJECT_DIR/logs/`, deliverables to `$PROJECT_DIR/artifacts/`
- **Permissions Setup section**: Documents required tool permissions
- **150-250 lines each**: Keep sub-agents focused

### Sub-Agent Naming

```
{skill-name}-{stage-role}.md
```

Examples:
- `code-review-security-reviewer.md`
- `code-review-type-safety-reviewer.md`
- `test-audit-classifier.md`
- `test-audit-deep-analyzer.md`

### Sub-Agent Model Selection

| Stage Purpose | Model | Rationale |
|---------------|-------|-----------|
| Quick lookups, classification | haiku | Fast, low-cost |
| Analysis, review, research | sonnet | Balanced capability |
| Implementation, architecture | opus | Highest quality |

Default to **Sonnet** for most pipeline stages.

## Common Sub-Patterns

Pipeline skills exhibit several recurring sub-patterns based on the SHAPE of their constituent stages. Sub-patterns are additive — pick those that apply.

### `reviewer-orchestrating`

**Definition**: Pipeline whose constituent stages are predominantly Reviewer-shaped (read-only analysis producing severity-classified findings).

**When to use**: The pipeline's purpose is multi-dimensional audit (security + type-safety + standards), or audit + classify + synthesize.

**Bulwark example**: `code-review` (security → type-safety → standards reviewers); `test-audit` (classifier → deep-analyzer reviewers); `fix-bug` (issue-analyzer + fix-validator reviewers + implementer).

**How it shapes the skill**:
- Each stage is a Reviewer agent — see `template-reviewer.md` (especially the `pipeline-stage` sub-pattern).
- Final stage typically synthesizes findings + computes overall verdict.
- Output deliverable: aggregated findings + verdict at `$PROJECT_DIR/artifacts/{skill-name}/{slug}/`.

### `research-orchestrating`

**Definition**: Pipeline whose stages are predominantly Research-shaped (multi-source investigation + synthesis), often run in parallel.

**When to use**: The pipeline's purpose is multi-viewpoint exploration with structured synthesis. Distinct from the Research archetype itself by having pipeline-style stage gating, conditional branching, or sequential dependencies between research phases.

**Bulwark example**: `product-ideation` (validator → market-researcher → competitive-analyzer → segment-analyzer → strategist); `plan-creation` (PO → Architect + Eng Lead → QA/Critic); `bulwark-brainstorm --exploratory` (SME + role analysis + critic + synthesis with stage gating).

**How it shapes the skill**:
- Multiple Research-shaped stages chained or run in parallel (sub-agents per viewpoint or role).
- Synthesis stage at the end is mandatory — pipeline output is NOT just N agent outputs.
- Final deliverable goes to `$PROJECT_DIR/artifacts/{skill-name}/{slug}/synthesis.md`.

### `generator-orchestrating`

**Definition**: Pipeline that includes Generator stages emitting artifacts from prior-stage findings.

**When to use**: The pipeline's purpose is "investigate, then produce" — a research/review phase followed by an artifact-emission phase that consumes the prior findings.

**Bulwark example**: `continuous-feedback` (Collector → Analyzers → Proposer (generates skill modification proposals)); `bulwark-verify` (Resolve → Detect → Analyze → Generate (emits verification scripts)).

**How it shapes the skill**:
- Final stages are Generator-shaped — see `template-generator.md`.
- Generator stages consume structured prior-stage output as input (not free text).
- Validation gate before write applies (Generator's Stage 3 validate-before-write pattern).

---

## Guidance for Generator

- Generate BOTH the orchestrating SKILL.md AND the sub-agent `.md` files
- The orchestrating skill references sub-agents by `Task(subagent_type="{name}")`, not inline definitions
- Every sub-agent stage needs a 4-part prompt (GOAL/CONSTRAINTS/CONTEXT/OUTPUT) in the orchestrating skill
- Include the `subagent-prompting` skill in the orchestrating skill's frontmatter `skills:` dependency
- Use the **Mandatory Execution Checklist (BINDING)** pattern at the top of SKILL.md — without it, Claude skips sub-agent spawning (DEF-P4-005; bottom-of-file checklists are advisory and ignored)
- Model selection per stage: Haiku for lookups, Sonnet for analysis, Opus for writing
- Each stage writes to `$PROJECT_DIR/logs/{skill-name}/` — the next stage reads from there (SA2/SA4 compliance)
- Final deliverables (synthesis, reports) go to `$PROJECT_DIR/artifacts/{skill-name}/{slug}/` — NOT to `logs/`
- **IMPORTANT**: `$PROJECT_DIR` is the project root (where `.claude/` lives). All paths MUST use this prefix. Do NOT write to the skill directory, CWD, or `.claude/skills/`.
- Include F# pipeline notation for visual workflow documentation
- Orchestrating skill is typically 200-400 lines
- Each sub-agent is typically 150-250 lines
- Read `references/agent-template.md` for the sub-agent file structure
- Read `references/agent-conventions.md` for system-prompt register and frontmatter conventions
