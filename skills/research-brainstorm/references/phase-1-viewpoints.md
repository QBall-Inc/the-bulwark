# Phase 1: Research Viewpoints

Five parallel Sonnet sub-agents, each analyzing the topic from a distinct analytical lens. The goal is comprehensive understanding, not just risk assessment.

## Viewpoint Definitions

### 1. Direct Investigation

**Core question**: What is this? How does it work? What is the current state of the art?

**Agent focus**:
- Define the concept precisely — what it is and what it is not
- How it works mechanically (architecture, data flow, lifecycle)
- Current state of the art — who uses it, what tooling exists
- Official documentation, specifications, or standards
- Key terminology and taxonomy

**Prompt framing**: "You are a technical researcher. Investigate [topic] thoroughly. Define it precisely, explain how it works, document the current state of the art, and identify the key concepts a team would need to understand before adopting it."

### 2. Practitioner Perspective

**Core question**: How do teams actually use this in production? What works and what doesn't?

**Agent focus**:
- Real-world adoption patterns — who uses this and how
- Common implementation approaches and their trade-offs
- Practical gotchas that documentation doesn't cover
- Operational concerns (debugging, monitoring, maintenance)
- Team skill requirements and learning curves

**Prompt framing**: "You are a senior engineer with 10+ years of experience who has implemented [topic] in multiple production systems. Describe how teams actually use this — what works well, what's harder than expected, what operational concerns arise, and what you wish you'd known before adopting it."

### 3. Contrarian Angle

**Core question**: What failure modes and risks do most people overlook?

**Agent focus**:
- Failure modes that advocates rarely mention
- Scenarios where this approach is the wrong choice
- Hidden costs (complexity, maintenance burden, cognitive load)
- Alternatives that might be simpler or more appropriate
- When NOT to use this

**Prompt framing**: "You are a critical reviewer who has seen [topic] both succeed and fail. What are the failure modes that advocates rarely mention? When is this the wrong approach? What hidden costs do teams discover only after committing? What simpler alternatives exist that people dismiss too quickly?"

### 4. First Principles

**Core question**: What core problem does this solve? What is the minimal viable version?

**Agent focus**:
- The fundamental problem being addressed (stripped of buzzwords)
- Why existing approaches are insufficient
- The minimal set of capabilities needed to solve the core problem
- What can be deferred vs. what is essential
- Decomposition into independent sub-problems

**Prompt framing**: "Break [topic] down from first principles. What is the fundamental problem it solves? Why can't simpler approaches work? What is the absolute minimum needed to get value? Decompose it into independent sub-problems and identify which are essential vs. nice-to-have."

### 5. Prior Art / Historical

**Core question**: What similar patterns have existed before? What can we learn from their trajectory?

**Agent focus**:
- Historical predecessors and analogous patterns
- How similar approaches evolved over time
- What succeeded and why; what failed and why
- Patterns that were hyped then abandoned vs. patterns that became foundational
- Lessons applicable to the current topic

**Prompt framing**: "Analyze [topic] through the lens of historical patterns. What predecessors or analogous approaches existed before? How did they evolve — which succeeded, which failed, and why? What lessons from those trajectories apply to how we should approach [topic] today?"

## Prompt Construction

Use the subagent-prompting 4-part template for each agent:

```
GOAL: Research [topic] from the [viewpoint name] perspective. Produce a comprehensive
analysis that covers [viewpoint focus areas].

CONSTRAINTS:
- Focus exclusively on the [viewpoint name] lens — other viewpoints are handled by parallel agents
- Be evidence-based: cite sources, examples, or reasoning for each claim
- Flag confidence levels: HIGH (verified/multiple sources), MEDIUM (single source/strong reasoning), LOW (inference/limited data)
- Do not pad findings — "I couldn't find evidence for X" is a valid and valuable finding
- Target 800-1200 words

CONTEXT:
[Topic description]
[User-provided resources/references if any]
[Scope boundaries — what is in/out of scope]

OUTPUT:
Write findings to: logs/research-brainstorm/{topic-slug}/phase-1/{NN}-{viewpoint-slug}.md
Use YAML header: viewpoint, topic, confidence_summary, key_findings (3-5 bullets)
Follow with detailed analysis organized by the focus areas above.
```

## Synthesis Guidelines

After all 5 agents complete, the orchestrator reads all 5 outputs and produces a synthesis:

1. **Identify convergence**: Where do multiple viewpoints agree? (High-confidence findings)
2. **Identify tension**: Where do viewpoints disagree? (Requires judgment or further research)
3. **Surface surprises**: What did one viewpoint find that others missed?
4. **Extract key decisions**: What choices does the team need to make?
5. **Flag unknowns**: What couldn't be determined and needs further investigation?

Write synthesis to: `logs/research-brainstorm/{topic-slug}/phase-1/synthesis.md`

Use AskUserQuestion after synthesis to clarify any ambiguities before the session closes.
