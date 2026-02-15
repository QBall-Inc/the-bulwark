# Synthesis Protocol

Guidelines for synthesizing agent outputs — both within a topic (per-session) and across topics (cross-topic synthesis sessions).

## Per-Topic Synthesis (Within Session)

Performed by the orchestrator after all agents in a phase complete. Produces a single document from 5 agent outputs.

### Steps

1. **Read all agent outputs** from `logs/research-brainstorm/{topic}/phase-{N}/`
2. **Extract key findings** from each agent's YAML header
3. **Map convergence**: Findings that appear in 2+ agent outputs (high confidence)
4. **Map tension**: Findings where agents disagree or contradict (requires judgment)
5. **Surface unique insights**: Findings from only one agent that others missed
6. **Consolidate**: Write a structured synthesis

### Synthesis Document Structure

```markdown
# {Topic} — Phase {N} Synthesis

## Key Findings (Convergent)
{Findings where multiple agents agree — these are high confidence}

## Tensions and Trade-offs
{Where agents disagree — present both sides, flag for decision}

## Unique Insights
{Findings from a single agent that add important nuance}

## Confidence Map
| Finding | Supporting Viewpoints/Roles | Confidence |
|---------|---------------------------|------------|
| ... | Viewpoints 1, 3, 5 | HIGH |
| ... | Viewpoint 2 only | MEDIUM |

## Open Questions
{What couldn't be resolved — needs user input or further research}

## Implications for Next Phase
{What this means for Phase 2 (if Phase 1) or task brief (if Phase 2)}
```

### Quality Checks

- Every agent's output must be referenced at least once
- Tensions must present both sides, not resolve prematurely
- "Open Questions" must be non-empty if any LOW confidence findings exist
- Use AskUserQuestion to resolve ambiguities before closing the session

## Cross-Topic Synthesis (Dedicated Session)

Performed when multiple topics have completed a phase. Combines per-topic syntheses into a unified document.

### When to Use

- After Phase 1: When all topics have per-topic research syntheses
- After Phase 2: When all topics have per-topic brainstorm syntheses

### Steps

1. **Read all per-topic syntheses** for the phase
2. **Identify cross-topic patterns**:
   - **Interactions**: Topic A's findings affect how we should approach Topic B
   - **Redundancies**: Topics A and B cover overlapping ground
   - **Subsumptions**: Topic A makes Topic B partially or fully irrelevant
   - **Conflicts**: Topics A and B lead to contradictory recommendations
3. **Present gate decision to user** (Phase 1 only): Which topics proceed to Phase 2?
4. **Write cross-topic synthesis**

### Cross-Topic Document Structure

```markdown
# Cross-Topic {Phase Name} Synthesis

## Topics Covered
{List of topics with one-line summary of each per-topic synthesis}

## Cross-Topic Patterns

### Interactions
{How findings from one topic affect another}

### Redundancies
{Where topics overlap — what can be consolidated}

### Subsumptions
{Where one topic makes another partially/fully irrelevant}

### Conflicts
{Where topics lead to contradictory recommendations}

## Unified Findings
{Consolidated findings that account for cross-topic patterns}

## Gate Decision (Phase 1 only)
{Which topics proceed to Phase 2 and why. Which are modified, merged, or dropped.}

## Input for Next Phase
{What the next phase (Phase 2 or task brief) should use as its starting point}
```

### Gate Decision Protocol (Phase 1 Cross-Topic Only)

The Phase 1 cross-topic synthesis session serves as a checkpoint before committing Phase 2 sessions. Present the following to the user via AskUserQuestion:

1. For each topic: **Proceed / Modify / Merge / Drop**
2. Rationale for any modifications
3. Whether topic ordering for Phase 2 matters
4. Any new topics surfaced by cross-topic analysis

Do NOT proceed to Phase 2 without explicit user approval on the gate decision.

## Final Authoritative Document (Phase 2 Cross-Topic Only)

The Phase 2 cross-topic synthesis produces the authoritative document that serves as the sole input for task brief creation.

### Authoritative Document Structure

```markdown
# Authoritative Research & Brainstorm Document

## Executive Summary
{2-3 paragraphs: what we researched, what we found, what we recommend}

## Topic Summaries
{Per topic: research findings + brainstorm conclusions in 1-2 paragraphs}

## Implementation Recommendations
{Consolidated from all Technical Architect outputs, filtered through Critical Analyst}

## Scope Definition
{From Product Manager outputs: what is v1, what is deferred}

## Architecture
{From Technical Architect: how it fits together}

## Build Plan
{From Development Lead: ordering, dependencies, effort}

## Risks and Mitigations
{Consolidated from all roles, prioritized by Critical Analyst}

## Decisions Required
{Any remaining choices that must be made during task brief creation}

## Appendix: Agent Output Index
{Paths to all agent outputs for reference}
```

This document is the ONLY input needed to create the task brief. All reasoning and evidence is preserved in the agent log files for traceability.
