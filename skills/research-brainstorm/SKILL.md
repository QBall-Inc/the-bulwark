---
name: research-brainstorm
description: Structured multi-viewpoint research and role-based brainstorming methodology
user-invocable: true
skills:
  - subagent-prompting
  - subagent-output-templating
---

# Research & Brainstorm

Structured methodology for deep research and brainstorming on complex topics. Uses parallel sub-agents with distinct analytical viewpoints (Phase 1) and professional roles (Phase 2) to produce comprehensive, bias-free analysis.

## Usage

```
/research-brainstorm research <topic> [--context <file>]
/research-brainstorm brainstorm <topic> [--research <file>]
/research-brainstorm synthesize research [--topics <t1,t2,...>]
/research-brainstorm synthesize brainstorm [--topics <t1,t2,...>]
```

## Methodology Overview

| Phase | Purpose | Agents | Model | Sessions |
|-------|---------|--------|-------|----------|
| 1: Research | Understand the topic from 5 analytical viewpoints | 5 parallel | Sonnet | 1 per topic |
| 1-Final | Cross-topic synthesis, gate decision | Orchestrator | - | 1 (multi-topic only) |
| 2: Brainstorm | Evaluate applicability via 5 professional roles | 5 sequenced | Opus | 1 per topic |
| 2-Final | Cross-topic synthesis, authoritative document | Orchestrator | - | 1 (multi-topic only) |

**Session budget**: Single topic = 3 sessions (research + brainstorm + task brief). N topics = (N + 1) x 2 + 1 sessions.

## Phase 1: Research

Spawn 5 Sonnet sub-agents **in parallel**. Each analyzes the topic from a distinct viewpoint.

| # | Viewpoint | Core Question |
|---|-----------|---------------|
| 1 | Direct Investigation | What is this? How does it work? State of the art? |
| 2 | Practitioner Perspective | How do teams use this in production? What actually works? |
| 3 | Contrarian Angle | What failure modes do most people overlook? |
| 4 | First Principles | What core problem does this solve? Minimal viable version? |
| 5 | Prior Art / Historical | What similar patterns exist? Lessons from predecessors? |

After all 5 complete, synthesize into a single per-topic research document.

**Detailed viewpoint definitions and prompt templates**: [references/phase-1-viewpoints.md](references/phase-1-viewpoints.md)

## Phase 2: Brainstorm

Spawn 5 Opus sub-agents in a **sequenced pipeline**. Input: Phase 1 research synthesis + project context.

| # | Role | Execution | Focus |
|---|------|-----------|-------|
| 1 | Project SME | First (solo) | Current architecture, existing assets, integration points |
| 2 | Senior Product Manager | Second (parallel with 3,4) | User value, prioritization, scope boundaries |
| 3 | Senior Technical Architect | Second (parallel with 2,4) | System design, patterns, technical trade-offs |
| 4 | Senior Development Lead | Second (parallel with 2,3) | Implementation feasibility, effort estimation, risks |
| 5 | Critical Analyst | Last (solo) | Cost-benefit analysis, contrarian assessment, should we even do this? |

After all 5 complete, synthesize into a single per-topic brainstorm document.

**Detailed role definitions and prompt templates**: [references/phase-2-roles.md](references/phase-2-roles.md)

## Cross-Topic Synthesis

When researching multiple topics, dedicated synthesis sessions combine per-topic documents:

- **Phase 1 synthesis**: Identify interactions, redundancies, subsumptions between topics. Gate decision with user on which topics proceed to Phase 2.
- **Phase 2 synthesis**: Combine into authoritative document for task brief creation.

**Synthesis protocol**: [references/synthesis-protocol.md](references/synthesis-protocol.md)

## Output Convention

All agent outputs and syntheses written to `logs/research-brainstorm/`:

```
logs/research-brainstorm/
  {topic-slug}/
    phase-1/
      01-direct-investigation.md
      02-practitioner.md
      03-contrarian.md
      04-first-principles.md
      05-prior-art.md
      synthesis.md
    phase-2/
      01-project-sme.md
      02-product-manager.md
      03-technical-architect.md
      04-development-lead.md
      05-critical-analyst.md
      synthesis.md
  phase-1-cross-topic-synthesis.md   (multi-topic only)
  phase-2-cross-topic-synthesis.md   (multi-topic only)
  authoritative-document.md          (final deliverable)
```

## Orchestration Protocol

### Per-Topic Session

1. **Pre-flight**: Verify topic defined, context loaded, output directory created, dependent skills loaded
2. **Construct prompts**: Use subagent-prompting 4-part template (GOAL / CONSTRAINTS / CONTEXT / OUTPUT)
3. **Spawn agents**: Phase 1 all parallel; Phase 2 SME first, then PM/Architect/Dev parallel, then Critic
4. **Read all agent outputs** from log files
5. **Synthesize**: Write per-topic synthesis document
6. **Checkpoint**: Use AskUserQuestion for clarifying questions with user

### Cross-Topic Session

1. Read all per-topic synthesis documents
2. Identify: interactions, redundancies, subsumptions, conflicts
3. **Gate decision**: Present findings to user, determine which topics proceed (Phase 1) or shape the authoritative document (Phase 2)
4. Write cross-topic synthesis document

### Pre-Flight Gate

Before spawning any agent, verify:

- [ ] Topic clearly defined with scope boundaries
- [ ] User-provided context/resources loaded (if any)
- [ ] Output directory exists: `logs/research-brainstorm/{topic-slug}/phase-{N}/`
- [ ] subagent-prompting and subagent-output-templating skills loaded
- [ ] Each prompt uses 4-part template with explicit output path
