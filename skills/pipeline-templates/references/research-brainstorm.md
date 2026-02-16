# Research & Brainstorm Pipeline

## Purpose

Deep multi-viewpoint research followed by role-based brainstorming to produce authoritative analysis for task brief creation. Uses two independent skills — `bulwark-research` and `bulwark-brainstorm` — across multiple sessions.

## When to Use

- Complex topics requiring structured research before implementation
- Multi-topic analysis with cross-topic synthesis
- Technology evaluations, architecture decisions, methodology design
- Any task where "should we build this?" precedes "how do we build this?"

## Pipeline Definition

```fsharp
// Research & Brainstorm Pipeline (multi-session)
// Each box is a separate session due to token budget constraints

// === Single Topic ===

BulwarkResearch(topic)              // Session N: 5 Sonnet parallel + synthesis
|> BulwarkBrainstorm(topic)         // Session N+1: 5 Opus sequenced + synthesis

// === Multi-Topic ===

// Phase 1: Research (one session per topic)
[BulwarkResearch(topic1),
 BulwarkResearch(topic2),
 BulwarkResearch(topic3)]           // N sessions (1 per topic)

// Phase 1 Gate: Cross-topic synthesis (orchestrator-only, no sub-agents)
|> CrossTopicResearchSynthesis      // 1 session: identify interactions, gate decision

// Phase 2: Brainstorm (one session per surviving topic)
|> [BulwarkBrainstorm(topic1'),
    BulwarkBrainstorm(topic2')]     // N' sessions (topics may be merged/dropped)

// Phase 2 Final: Authoritative document (orchestrator-only, no sub-agents)
|> CrossTopicBrainstormSynthesis    // 1 session: authoritative document

// Task brief creation from authoritative document
|> TaskBriefCreation                // 1 session
```

## Session Budget

| Scenario | Formula | Example (3 topics) |
|----------|---------|---------------------|
| Single topic | 2 sessions | 2 sessions |
| Multi-topic | (N + 1) x 2 + 1 | (3+1) x 2 + 1 = 9 sessions |

## Stage Details

### BulwarkResearch (Per-Topic)

**Skill**: `/bulwark-research`
**Model**: Orchestrator = Opus (main), Agents = 5 Sonnet (parallel)
**Input**: Topic description, optional context file
**Output**: `logs/research/{topic-slug}/synthesis.md`

Spawns 5 parallel Sonnet viewpoint agents:
1. Direct Investigation
2. Practitioner Perspective
3. Contrarian Angle
4. First Principles
5. Prior Art / Historical

### BulwarkBrainstorm (Per-Topic)

**Skill**: `/bulwark-brainstorm`
**Model**: Orchestrator = Opus (main), Agents = 5 Opus (sequenced)
**Input**: Topic description, research synthesis from Phase 1
**Output**: `logs/brainstorm/{topic-slug}/synthesis.md`

Spawns 5 sequenced Opus role agents:
1. Project SME (solo, first — autonomous codebase exploration)
2. Senior Product Manager (parallel with 3, 4)
3. Senior Technical Architect (parallel with 2, 4)
4. Senior Development Lead (parallel with 2, 3)
5. Critical Analyst (solo, last — reads all prior outputs)

### CrossTopicResearchSynthesis (Gate Session)

**Model**: Orchestrator only (no sub-agents)
**Input**: All per-topic research synthesis documents
**Output**: Cross-topic synthesis with gate decision

Orchestrator reads all per-topic syntheses and identifies:
- **Interactions**: How findings from one topic affect another
- **Redundancies**: Where topics overlap
- **Subsumptions**: Where one topic makes another irrelevant
- **Conflicts**: Where topics lead to contradictory recommendations

**Gate decision** (via AskUserQuestion): Which topics proceed to Phase 2?
Options per topic: Proceed / Modify / Merge / Drop

### CrossTopicBrainstormSynthesis (Final Session)

**Model**: Orchestrator only (no sub-agents)
**Input**: All per-topic brainstorm synthesis documents
**Output**: Authoritative document for task brief creation

Produces the definitive document with:
- Executive summary
- Per-topic summaries
- Implementation recommendations
- Scope definition (v1 vs. deferred)
- Architecture overview
- Build plan with ordering
- Risks and mitigations
- Decisions still required

### TaskBriefCreation

**Model**: Orchestrator only
**Input**: Authoritative document
**Output**: `plans/task-briefs/P{X}.{Y}-{name}.md`

Standard task brief creation from the authoritative document. No sub-agents needed — the research and brainstorming are complete.

## Output Structure

```
logs/
  research/
    {topic-slug}/
      01-direct-investigation.md
      02-practitioner.md
      03-contrarian.md
      04-first-principles.md
      05-prior-art.md
      synthesis.md
  brainstorm/
    {topic-slug}/
      01-project-sme.md
      02-product-manager.md
      03-technical-architect.md
      04-development-lead.md
      05-critical-analyst.md
      synthesis.md
  diagnostics/
    bulwark-research-{timestamp}.yaml
    bulwark-brainstorm-{timestamp}.yaml
```

## Success Criteria

- All viewpoint agents produced output (research phase)
- All role agents produced output in correct sequence (brainstorm phase)
- Synthesis documents follow templates
- AskUserQuestion used at each checkpoint
- Gate decision approved by user (multi-topic)
- Authoritative document produced (multi-topic)
- Task brief created from authoritative document

## Related Pipelines

- **Research & Planning**: Simpler research + iterative planning (no role-based brainstorming)
- **New Feature**: For implementation after task brief creation
- **Code Review**: For reviewing completed implementation
