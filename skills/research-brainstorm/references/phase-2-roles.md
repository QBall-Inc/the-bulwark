# Phase 2: Brainstorm Roles

Five Opus sub-agents in a sequenced pipeline. Input: Phase 1 research synthesis + project context. The goal is to evaluate applicability and define specific implementation approach.

## Execution Order

```
Step 1:  [Project SME]           ← runs first, alone
              |
              v
Step 2:  [Product Manager]  [Technical Architect]  [Development Lead]   ← run in parallel
              |                     |                      |
              v                     v                      v
Step 3:  [Critical Analyst]  ← runs last, reads all prior outputs
```

The SME establishes the project baseline. The three role agents work independently with both research and SME output. The Critical Analyst synthesizes everything with a contrarian lens.

## Role Definitions

### 1. Project SME (Sequential — First)

**Purpose**: Establish what exists, what has been built, and where the topic fits in the current architecture.

**Input**: Phase 1 research synthesis + project documents (architecture.md, tasks.yaml, relevant existing skills/agents)

**Agent focus**:
- Current project architecture relevant to the topic
- Existing assets that relate to or would be affected by adoption
- Integration points — where does this connect to what we already have?
- Constraints imposed by current design decisions
- What the project already does well that should not be disrupted

**Prompt framing**: "You are a subject matter expert on this project. You have deep knowledge of its architecture, existing skills, agents, hooks, and design decisions. Given the research on [topic], analyze how it relates to the current project state. Document what exists, where the integration points are, what constraints apply, and what must not be disrupted."

**Key documents to provide**:
- `docs/architecture.md`
- `plans/tasks.yaml` (slim version with stubs)
- 2-3 most relevant existing skill SKILL.md files as reference implementations
- Any relevant task briefs

### 2. Senior Product Manager (Parallel — Second)

**Purpose**: Evaluate user value, prioritization, and scope boundaries.

**Input**: Phase 1 research synthesis + SME output

**Agent focus**:
- User value proposition — who benefits and how?
- Prioritization — what aspects deliver the most value soonest?
- Scope boundaries — what is v1 vs. deferred?
- Success criteria — how do we know this works?
- Risk to user experience if implemented poorly

**Prompt framing**: "You are a senior product manager evaluating whether and how to adopt [topic] in a development workflow tool. Using the research findings and SME analysis, assess: What user value does this deliver? What should be prioritized for v1? What are clear scope boundaries? How would we measure success? What risks exist to user experience?"

### 3. Senior Technical Architect (Parallel — Second)

**Purpose**: Define system design, patterns, and technical trade-offs.

**Input**: Phase 1 research synthesis + SME output

**Agent focus**:
- Architectural approach — how should this be structured?
- Design patterns that apply (and which to avoid)
- Technical trade-offs and their implications
- Integration architecture — how it connects to existing systems
- Extensibility and future-proofing considerations

**Prompt framing**: "You are a senior technical architect designing the implementation of [topic] within an existing system. Using the research findings and SME analysis, propose: What architectural approach should we use? What design patterns apply? What are the key technical trade-offs? How does this integrate with existing components? What extensibility considerations matter?"

### 4. Senior Development Lead (Parallel — Second)

**Purpose**: Assess implementation feasibility, effort, and practical risks.

**Input**: Phase 1 research synthesis + SME output

**Agent focus**:
- Implementation feasibility — can this be built with available tools?
- Effort estimation — complexity and session count
- Implementation risks — what could go wrong during building?
- Testing strategy — how do we verify this works?
- Dependencies and ordering — what must be built first?

**Prompt framing**: "You are a senior development lead responsible for building [topic]. Using the research findings and SME analysis, assess: Is this feasible with our current tooling? What is the effort estimate? What implementation risks exist? How should we test and verify? What is the build order and what are the dependencies?"

### 5. Critical Analyst (Sequential — Last)

**Purpose**: Perform cost-benefit analysis, challenge assumptions, poke holes.

**Input**: Phase 1 research synthesis + ALL prior Phase 2 outputs (SME + PM + Architect + Dev Lead)

**Agent focus**:
- Cost-benefit analysis — is the investment justified?
- Assumption challenges — what are the team assuming that might be wrong?
- Gaps in the proposals — what has been overlooked?
- Simpler alternatives — could a less ambitious approach work?
- Kill criteria — under what conditions should this be abandoned?
- Final recommendation: proceed / modify / defer / kill

**Prompt framing**: "You are a critical analyst reviewing proposals for adopting [topic]. You have the original research, the SME analysis, and three role-based evaluations (PM, Architect, Dev Lead). Your job is to challenge everything: Is the investment justified? What assumptions might be wrong? What has been overlooked? Is there a simpler alternative? Under what conditions should this be abandoned? Provide a clear recommendation: proceed as proposed, modify (with specifics), defer, or kill."

## Prompt Construction

Use the subagent-prompting 4-part template for each agent:

```
GOAL: Evaluate [topic] from the [role name] perspective for implementation in
The Bulwark project. Produce actionable analysis with specific recommendations.

CONSTRAINTS:
- Focus on your role's perspective — other roles are handled by separate agents
- Ground all recommendations in the Phase 1 research findings (do not re-research)
- Reference specific project assets by path when discussing integration points
- Be prescriptive: "Do X" not "Consider X or Y"
- Target 1000-1500 words

CONTEXT:
[Phase 1 research synthesis]
[SME output — for agents #2-5]
[PM/Architect/Dev Lead outputs — for agent #5 only]
[Relevant project documents]

OUTPUT:
Write findings to: logs/research-brainstorm/{topic-slug}/phase-2/{NN}-{role-slug}.md
Use YAML header: role, topic, recommendation (proceed/modify/defer/kill), key_findings (3-5 bullets)
Follow with detailed analysis organized by the focus areas above.
```

## Synthesis Guidelines

After all 5 agents complete, the orchestrator reads all 5 outputs and produces a synthesis:

1. **Consensus areas**: Where do all roles agree? (Foundation for implementation)
2. **Divergence areas**: Where do roles disagree? (Requires decision)
3. **Critical Analyst verdict**: What is the overall recommendation and what conditions apply?
4. **Implementation outline**: High-level approach combining Architect's design, Dev Lead's plan, PM's priorities
5. **Risks and mitigations**: Consolidated from all roles
6. **Open questions**: What needs user decision before proceeding?

Write synthesis to: `logs/research-brainstorm/{topic-slug}/phase-2/synthesis.md`

Use AskUserQuestion after synthesis to resolve open questions with the user.
