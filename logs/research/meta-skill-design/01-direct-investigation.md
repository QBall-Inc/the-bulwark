---
viewpoint: direct-investigation
topic: Meta-skill design patterns for skill-creator and agent-creator
confidence_summary:
  high: 9
  medium: 6
  low: 3
key_findings:
  - "Skill complexity classification uses a 3-axis decision: content volume (lines/words), determinism requirement (scripts vs prose), and reference breadth (single domain vs multi-domain). The Anthropic skill-creator uses degrees-of-freedom framing: high freedom (vanilla SKILL.md), medium (pseudocode/scripts with parameters), low (specific scripts, few parameters)."
  - "context:fork is warranted when a skill is noise-prone (multi-step, verbose output), has no need for conversation history, and acts as a task executor rather than a knowledge layer. A concrete threshold: content exceeding ~200 lines of reference material or commands justifies isolation. The anti-case: guideline-only skills with no actionable task produce meaningless fork output."
  - "Sub-agent architecture selection follows a communication-dependency matrix: no sub-agents for single-step or context-dependent work; sequential for dependency chains; parallel for independent domains; Agent Teams only when workers must communicate with each other directly. The deciding question for Agent Teams is inter-agent communication, not just parallelism."
  - "Agent files (.claude/agents/) differ structurally from skills with context:fork: the markdown body becomes the agent's system prompt, while context:fork injects skill content as the task. Generated agents must account for this inversion — the agent-creator produces a system-prompt document, not a task-instruction document."
  - "Stop hook in agent frontmatter is automatically converted to SubagentStop at runtime — this is the canonical mechanism for generated agents to emit diagnostic output. agent-creator should generate a Stop hook with a command that writes the diagnostic YAML."
  - "No published meta-skill uses Task tool sub-agents for generation iteration. The Anthropic skill-creator, FrancyJGLisboa agent-skill-creator, and Skill_Seekers enhance_skill.py all use single-pass LLM generation. The Bulwark multi-agent pattern (research → brainstorm → implement → validate) is more sophisticated than any external reference."
---

# Meta-skill Design Patterns — Direct Investigation

## Summary

The meta-skills skill-creator (P5.4) and agent-creator (P5.5) need to classify output complexity, make architectural decisions about context isolation and sub-agent topology, and execute a multi-pass generation workflow. Evidence from Anthropic's official skill-creator, community implementations (FrancyJGLisboa, Skill_Seekers, context-fence), and the Bulwark codebase establishes specific heuristics for each dimension. The most critical architectural distinction is that agent files produce system prompts while context:fork skills produce tasks — agent-creator must generate content in the system-prompt register, not the task-instruction register.

---

## Detailed Analysis

### 1. Skill Complexity Classification

#### The Anthropic Degrees-of-Freedom Framework

Anthropic's official skill-creator (from `https://github.com/anthropics/skills/tree/main/skills/skill-creator`) uses a three-tier degrees-of-freedom model:

| Tier | When to Use | Structural Implication |
|------|-------------|------------------------|
| High freedom | Multiple valid approaches, context-dependent heuristics | Vanilla SKILL.md body only |
| Medium freedom | Preferred patterns with variation, configuration-dependent behavior | Pseudocode or scripts with parameters in `scripts/` |
| Low freedom | Error-prone sequences, deterministic reliability required | Specific scripts in `scripts/`, few parameters |

The official skill-creator uses this as its primary classification lens: match specificity to task fragility.

**Confidence**: HIGH
**Evidence**: Direct content of Anthropic's skill-creator SKILL.md, confirmed by the claudeskills.org documentation, and corroborated by the leehanchung.github.io deep-dive.

#### Progressive Disclosure Decision

Beyond degrees of freedom, the decision to add supporting files follows a pattern from the official docs and the context-fence project:

- `scripts/`: When the same code is rewritten repeatedly across invocations OR when deterministic reliability is needed (the LLM cannot be trusted to produce the exact same sequence). Evidence: PDF rotation example — fragile, sequence matters.
- `references/`: When documentation is too verbose for SKILL.md body (practical threshold: >500 lines in SKILL.md body triggers extraction). When the reference domain is specialized enough that Claude does not have it natively (API schemas, organizational policies, domain-specific patterns).
- `assets/`: When files are needed as output artifacts rather than context inputs (templates to fill, images, boilerplate code).
- `templates/`: When output format must be precisely controlled and stable across invocations.

**Decision heuristic for skill-creator to evaluate the requested skill:**

```
1. Is the task linear and fully describable in <500 lines? → vanilla SKILL.md
2. Does the task involve repeated code patterns? → add scripts/
3. Does the task need domain reference not in Claude's base knowledge? → add references/
4. Does the task produce structured output that must match a schema? → add templates/
5. Does the task produce file artifacts Claude fills rather than generates? → add assets/
```

**Confidence**: HIGH
**Evidence**: Official skill-creator SKILL.md (progressive disclosure section, bundled resources guidance), context-fence pattern (200-line threshold for references), Bulwark codebase (all complex skills use this multi-directory pattern: bulwark-brainstorm, bulwark-research, continuous-feedback all have references/ and templates/).

#### Volume Threshold

The context-fence repository provides empirical grounding: forking and isolating reference material becomes token-efficient when references exceed ~200 lines. By extension, once SKILL.md references content that would push total context load over this threshold, extracting to `references/` is justified.

**Confidence**: MEDIUM
**Evidence**: context-fence README (87% average token savings, 200-line threshold claim). Single source — not independently validated.

---

### 2. Context Fork Decision Criteria

#### When context:fork Is Warranted

From the official Claude Code skills documentation (`https://code.claude.com/docs/en/skills`):

> "Add `context: fork` to your frontmatter when you want a skill to run in isolation. The skill content becomes the prompt that drives the subagent. It won't have access to your conversation history."

The official docs identify three conditions warranting `context: fork`:

1. **Task executor, not knowledge layer**: The skill has explicit step-by-step instructions rather than guidelines to apply to ongoing work. A skill with only "use these API conventions" without a task produces meaningless fork output.

2. **Noise isolation**: The skill is multi-step, produces verbose intermediate output, or explores broadly (research/analysis skills). The goal is to prevent the skill's execution details from polluting the main conversation context.

3. **No conversation history needed**: The skill can start fresh. If the skill requires awareness of prior conversation decisions (e.g., "refactor this class using the approach we discussed"), forking loses that context and produces wrong output.

**Concrete decision tree for skill-creator to generate:**

```
Does the skill need prior conversation context to operate? → NO fork
Does the skill produce >20 tool calls typically? → YES fork
Does the skill produce verbose intermediate output? → YES fork
Is the skill a knowledge/guideline layer? → NO fork
Is the skill a task executor with explicit steps? → YES fork
Does the user invoke it for isolated, self-contained work? → YES fork
```

**Confidence**: HIGH
**Evidence**: Official Claude Code skills docs (context:fork section, warning about guideline-only skills), claudelog.com context-fork FAQ, context-fence design rationale, official sub-agents docs (subagents have fresh context, summaries return to parent).

#### The Skill vs Agent Distinction

The official docs make a critical distinction that skill-creator and agent-creator must handle differently:

| Type | System Prompt | Task |
|------|--------------|------|
| Skill with `context: fork` | From `agent` frontmatter type (Explore, Plan, general-purpose) | SKILL.md content |
| Agent in `.claude/agents/` | Agent's markdown body | Claude's delegation message |

This means agent-creator generates content in the **system-prompt register** (identity, mission, what the agent IS and what it DOES) while skill-creator generates content in the **task-instruction register** (what to DO when invoked, step-by-step workflow). This is a fundamental structural difference that the meta-skills must encode.

**Confidence**: HIGH
**Evidence**: Official sub-agents docs ("Subagents receive only this system prompt... not the full Claude Code system prompt"), official skills docs ("the skill content becomes the prompt that drives the subagent" — meaning the task, not the system prompt).

---

### 3. Sub-Agent Architecture Selection

#### The Communication-Dependency Matrix

From claudefa.st and the official Claude Code docs, sub-agent architecture selection follows a two-axis decision:

**Axis 1: Dependency structure of the work**
- No dependencies → parallel candidates
- Sequential dependencies (B needs A's output) → sequential only
- Mixed → parallel where independent, sequential where dependent

**Axis 2: Communication requirements between workers**
- Workers only report back to orchestrator → Task tool sub-agents (no Agent Teams)
- Workers must share findings with each other, challenge each other, or coordinate directly → Agent Teams

**Architecture selection table:**

| Scenario | Architecture | Model Pattern |
|----------|-------------|---------------|
| Single focused task | No sub-agents; orchestrator directly | Orchestrator model |
| Single specialized task with defined behavior | Custom agent via Task tool | Agent's frontmatter model |
| Multiple independent analyses | Parallel Task tool sub-agents | Sonnet (analysis) |
| Multi-step workflow with dependencies | Sequential Task tool sub-agents | Haiku/Sonnet/Opus by task type |
| Workers needing inter-agent communication | Agent Teams | Opus (complex coordination) |
| Large-scale parallel work exceeding context limits | Agent Teams | Opus |

**Confidence**: HIGH
**Evidence**: claudefa.st Agent Teams guide, official sub-agents docs ("If you need multiple agents working in parallel and communicating with each other, see agent teams instead"), Bulwark pipeline-templates SKILL.md (exact model selection rubric: Haiku=lookup/execute, Sonnet=review/analyze, Opus=write/fix).

#### Parallel Sub-Agent Pre-conditions

From claudefa.st sub-agent best practices, all three conditions must hold for parallel spawning:

1. Three or more unrelated tasks spanning independent domains
2. No shared state between tasks
3. Clear file or domain boundaries with zero overlap

If any condition fails, sequential is correct. The Bulwark bulwark-research skill validates this: 5 parallel viewpoint agents work because each analyzes the same topic from a completely independent lens with no shared output dependency.

**Confidence**: HIGH
**Evidence**: claudefa.st sub-agent best practices, verified against bulwark-research design (parallel multi-viewpoint analysis), bulwark-brainstorm design (3 parallel role agents with SME sequential first because roles depend on SME output).

#### When to Use No Sub-Agents

The official sub-agents docs identify cases where the main conversation is preferable:
- Tasks needing frequent back-and-forth or iterative refinement
- Multiple phases sharing significant context (planning → implementation → testing)
- Quick targeted changes
- Latency-sensitive work (sub-agents start fresh and need time to gather context)

For skill-creator's classification, the generated skill uses no sub-agents when:
- Single-step execution (run a script, apply a template, generate a single file)
- The skill is a reference/knowledge layer (user-invocable: false; applied inline)
- Task is quick and targeted enough that sub-agent startup overhead dominates

**Confidence**: MEDIUM
**Evidence**: Official sub-agents docs (choose sub-agents vs main conversation section). Reasonable inference from latency consideration — not empirically measured.

---

### 4. Meta-Skill Generation Workflow

#### Existing Patterns (External)

Three external references provide prior art on how a meta-skill generates skills:

**Anthropic's skill-creator (6-step linear workflow):**
1. Understand (gather concrete examples)
2. Plan (identify reusable resources)
3. Initialize (run `init_skill.py`)
4. Edit (implement resources and write SKILL.md)
5. Package (validate and create .skill file)
6. Iterate (refine from real usage)

This is a single-pass, orchestrator-direct workflow with no sub-agents. The meta-skill asks questions then generates in one pass.

**Confidence**: HIGH
**Evidence**: Direct content of Anthropic's skill-creator SKILL.md from the anthropics/skills repository.

**FrancyJGLisboa agent-skill-creator (6-phase discovery workflow):**
1. Phase 1 (Discovery): Research APIs and data sources
2. Phase 2 (Design): Define use cases and capabilities
3. Phase 3 (Architecture): Determine folder structure
4. Phase 4 (Detection): Create activation patterns
5. Phase 5 (Implementation): Write production code
6. Phase 6 (Testing): Validate and test

Uses reference documents for each phase (`phase1-discovery.md` through `phase6-testing.md`) as recipe guides. Selects between simple skill (single SKILL.md) and complex skill suite (multiple component skills) based on: number of objectives, workflow branching depth, domain expertise requirements, code volume, maintenance scope.

**Confidence**: MEDIUM
**Evidence**: FrancyJGLisboa agent-skill-creator repository README and structure. Single source.

**Skill_Seekers enhance_skill.py (source-prioritized synthesis):**
- Source priority: codebase analysis > official documentation > GitHub issues > PDF documentation
- Multi-source synthesis with confidence ranking
- Detects conflicts when sources disagree
- No explicit complexity classification — generates enhancement based on available sources

**Confidence**: MEDIUM
**Evidence**: enhance_skill.py analysis. The tool does skill enhancement, not generation from scratch — analogous but not identical use case.

#### Gap Finding: No Iterative Refinement Pattern Exists

None of the external references use iterative sub-agent loops for skill generation. All use single-pass generation (possibly with user review). The Bulwark's proposed pattern of Task tool sub-agents for generation + validation is novel relative to published implementations.

**Confidence**: HIGH (that the gap exists)
**Evidence**: Exhaustive review of Anthropic skill-creator, FrancyJGLisboa agent-skill-creator, Skill_Seekers enhance_skill.py, Superpowers writing-skills meta-skill, context-fence. None use sub-agent loops for generation.

#### Recommended Generation Workflow for skill-creator

Based on the Bulwark's existing patterns (bulwark-research, bulwark-brainstorm) and the gap in external references, the optimal workflow is:

**Stage 0: Pre-Flight — Elicit Requirements**
- AskUserQuestion to determine: purpose, triggers, target audience, expected invocation pattern
- Determine complexity tier (vanilla, with scripts, with references, with both)
- Determine context isolation need (fork vs inline)
- Determine sub-agent topology need

**Stage 1: Generate — Task tool Sonnet sub-agent**
- Sub-agent receives requirements + complexity tier + relevant skill examples from the codebase
- Produces complete SKILL.md (and supporting files if needed)
- Model: Sonnet (analysis/generation, not Opus code-writing)

**Stage 2: Validate — anthropic-validator**
- Run `/anthropic-validator` on the generated skill
- If critical/high findings: Stage 1 retry with validator feedback in CONTEXT

**Stage 3: Refine (if needed)**
- Re-spawn Stage 1 sub-agent with validator findings in CONTEXT
- Max 2 retries

**Stage 4: Write Output**
- Write generated files to target location
- Report to user with usage instructions

This mirrors the Bulwark's established collect-then-validate cycle (as in fix-validation pipeline) applied to skill generation.

**Confidence**: MEDIUM (design inference from multiple patterns, not validated against real usage)
**Evidence**: Bulwark fix-validation pipeline (generate-validate-retry cycle), anthropic-validator skill (already exists for validation step), subagent-prompting SKILL.md (model selection rubric applied to generation stage).

---

### 5. Agent-Creator Specific Patterns

#### Stop Hook for Diagnostic Output

From the official sub-agents documentation (section "Define hooks for subagents"):

> "`Stop` hooks in frontmatter are automatically converted to `SubagentStop` events."

This is the canonical mechanism for generated agents to emit diagnostic output. The agent-creator should generate a `Stop` hook in the agent's frontmatter with a command that writes the diagnostic YAML. The hook fires at agent completion and executes before the parent orchestrator reads results.

Generated agent pattern:
```yaml
---
name: generated-agent-name
description: What this agent does and when to use it
model: sonnet
tools:
  - Read
  - Grep
  - Glob
  - Write
hooks:
  Stop:
    - hooks:
        - type: command
          command: "bash .claude/scripts/write-diagnostic.sh generated-agent-name"
skills:
  - subagent-prompting
---
```

**Confidence**: HIGH
**Evidence**: Official sub-agents docs (Stop hook conversion to SubagentStop, hooks in subagent frontmatter section).

#### Agent vs Skill-with-Fork Decision

The agent-creator must determine whether to produce a `.claude/agents/` file or a skill with `context: fork`. The key criterion:

**Use agent file (.claude/agents/) when:**
- The generated capability has a stable identity and role (code-reviewer, issue-analyzer, implementer)
- The capability should be discoverable by Claude for automatic delegation
- The capability needs custom tool restrictions or permission modes
- The capability should persist as a project or user asset
- The capability's behavior is defined by WHO IT IS (system prompt register)

**Use skill with context:fork when:**
- The capability is invoked by the user directly as a slash command
- The skill's instructions define WHAT TO DO (task-instruction register)
- The skill wraps a specific workflow rather than defining a specialized agent personality
- The capability is workflow-centric rather than identity-centric

In practice: agent-creator generates `.claude/agents/` files for long-lived specialist agents, while skill-creator with `context: fork` generates skills for isolated-execution workflows.

**Confidence**: MEDIUM
**Evidence**: Official sub-agents docs (system prompt distinction), official skills docs (context:fork as task injection), Bulwark codebase (bulwark-implementer.md is an agent file with system-prompt register content vs bulwark-research/SKILL.md which is task-instruction content). The distinction is real but the boundary can be ambiguous.

#### SA1 Template in Generated Agents

The P5.5 requirement specifies that generated agents must include 4-part template usage (GOAL/CONSTRAINTS/CONTEXT/OUTPUT). This maps to the Bulwark's `subagent-prompting` skill. Generated agents should:
1. List `subagent-prompting` in the `skills` frontmatter field (injected at startup per official docs)
2. Reference GOAL/CONSTRAINTS/CONTEXT/OUTPUT in their protocol/invocation sections

**Confidence**: HIGH
**Evidence**: Bulwark subagent-prompting/SKILL.md (complete 4-part template definition), bulwark-implementer.md (loads subagent-prompting via skills: field), official sub-agents docs (skills field injects full skill content at startup).

---

### 6. Key Terminology and Taxonomy

| Term | Definition |
|------|------------|
| **Meta-skill** | A skill that generates other skills or agents as its primary output |
| **Degrees of freedom** | Anthropic's framework for how prescriptively a skill constrains Claude's behavior (high=flexible, low=deterministic) |
| **Progressive disclosure** | Three-level loading: metadata always in context, SKILL.md body on invocation, supporting files on demand |
| **context:fork** | Frontmatter field that causes a skill to run in an isolated sub-agent context with fresh history; skill content becomes the task |
| **System prompt register** | Content that defines what an agent IS (identity, mission, constraints) — used in .claude/agents/ files |
| **Task-instruction register** | Content that defines what to DO when invoked — used in SKILL.md body |
| **Router/Recipe pattern** | Design pattern where a lightweight inline skill (router) delegates to a forked dense-reference skill (recipes) for token efficiency |
| **Agent Teams** | Multi-session parallel agents that can communicate with each other directly; distinct from Task tool sub-agents which only report to orchestrator |
| **Sub-agent topology** | The architecture of sub-agent usage: none, sequential, parallel, or Agent Teams |

**Confidence**: HIGH (terminology definitions)
**Evidence**: Official Claude Code docs, context-fence README, claudefa.st guides.

---

## Confidence Notes

**LOW confidence findings (3):**

1. **200-line threshold for context:fork decision**: Derived from the context-fence project (single source). No independent validation. Treat as indicative, not absolute.

2. **Meta-skill generation workflow design**: The proposed Stage 0-4 generation workflow is a design inference from multiple patterns (fix-validation pipeline, bulwark-brainstorm, anthropic-validator) applied to the skill-generation domain. No external source validates this specific pattern for meta-skill use. Confidence is MEDIUM (listed above) but the specific stage breakdown is LOW — it requires implementation to validate.

3. **Agent vs skill-with-fork boundary**: The distinction between "identity-centric" (agent) vs "workflow-centric" (skill) is real but the classification can be ambiguous for borderline cases. Real-world examples are clear at extremes but the middle ground requires judgment.

**Note on reconciliation between initial and deepened research:**

Two findings shifted materially during deepening:

1. **Stop hook mechanism**: Initial pass only had generic knowledge of hook types. Deepened research from official sub-agents docs revealed that `Stop` hooks in frontmatter automatically convert to SubagentStop — this is a specific implementation detail that agent-creator must generate correctly.

2. **System-prompt vs task-instruction register**: Initial pass treated agents and forked skills as roughly equivalent. Deepened reading of official docs clarified the structural inversion: agent body = system prompt; skill body + context:fork = task for the agent. This changes what agent-creator generates.
