# Agent Authoring Log — plan-creation-architect

**Agent file**: `.claude/agents/plan-creation-architect.md`
**Authored**: 2026-02-23
**Template source**: `skills/create-skill/references/agent-template.md`
**Reference agent**: `.claude/agents/product-ideation-competitive-analyzer.md`

---

## Design Decisions

### 1. System-Prompt Register vs. Task-Instruction Register

The agent body is written in system-prompt register throughout: identity statements ("You are a technical architect..."), behavioral patterns ("When a codebase is accessible, use Glob and Grep..."), and expertise descriptions. No step-by-step imperative task instructions appear at the top level.

The Protocol section uses numbered steps but each step describes HOW the agent reasons (e.g., "Work through each section of the output structure methodically"), not what to do for a specific one-time task. This is consistent with the conventions file's guidance that "Protocol section describes HOW the agent works, not WHAT to do for a specific task."

### 2. Dual-Mode Invocation (Pipeline vs. Standalone)

The CONTEXT section required independent standalone usability. Two output paths are defined:
- **Pipeline**: `$PROJECT_DIR/logs/plan-creation/{slug}/02-technical-architect.md` — used when the orchestrator provides an explicit OUTPUT path
- **Standalone**: `$PROJECT_DIR/logs/plan-creation-architect-{YYYYMMDD-HHMMSS}.md` — fallback when no output path is given

The Pre-Flight Gate makes this explicit: "Write output to the exact path specified in the OUTPUT section of your invocation prompt. If no output path is given (standalone invocation), write to `$PROJECT_DIR/logs/plan-creation-architect-{YYYYMMDD-HHMMSS}.md`"

This avoids requiring the standalone user to know the pipeline's slug convention.

### 3. Opus Model Selection

Model is `opus` per task requirements. Rationale aligns with the model selection table in agent-conventions.md: "Complex implementation, architecture, novel problems → opus (Highest quality reasoning)." Architectural analysis requires holding the entire system context in mind simultaneously and reasoning about second-order effects of design decisions — this is exactly the Opus use case.

### 4. Tool Scope — Read/Glob/Grep/Write Only

The agent does not include Bash or Edit. Architectural analysis is read-and-synthesize, not code-writing. Including Bash would widen the attack surface without benefit. The Write tool is included only for report output to `$PROJECT_DIR/logs/`.

### 5. Pre-Flight Gate Obligations

Four obligations, matching the competitive-analyzer pattern:
1. Read PO output before analysis (prevents designing in a vacuum)
2. Read research synthesis if provided (prevents ignoring validated findings)
3. Explore codebase before making integration claims (prevents fabricated architecture)
4. Write to exact output path (SA2 compliance)

Obligation 3 (codebase exploration) is added beyond the template's generic "write to exact path" obligation because architectural agents are uniquely prone to asserting integration facts without reading the codebase. The wording is reinforced in the DO NOT section: "Invent integration details about files or systems you have not read."

### 6. Output Structure — Eight Sections

The eight sections in the output template (Architectural Approach, Component Decomposition, Design Patterns, Integration Architecture, Technical Trade-offs, Technology Recommendations, Extensibility Considerations, Risks and Mitigations) map directly to the task brief's CONTEXT/Output Structure specification. No sections were added or removed.

The Component Decomposition uses a table (name, responsibility, type, depends-on) rather than a flat list — this makes new vs. extend status explicit, which is important for integration impact assessment.

The Technical Trade-offs section uses a structured three-part format (Option A / Option B / Recommendation) modeled on the research patterns in the brainstorm outputs. This is more useful than prose trade-off descriptions because it forces explicit comparison.

### 7. Diagnostics YAML Schema

Added fields specific to architectural analysis that the generic template does not include:
- `po_output_read`: boolean — confirms the Pre-Flight Gate obligation was honored
- `research_synthesis_read`: boolean — same
- `codebase_explored`: boolean — confirms integration claims are grounded
- `components_identified`: count of decomposed components
- `trade_offs_analyzed`: count of structured trade-offs
- `risks_identified`: count of named risks

These fields give the orchestrator a quick signal about analysis completeness without reading the full report.

### 8. Completion Checklist — 14 Items

Extended beyond the generic template's 4-item checklist to cover all output sections explicitly. This is consistent with the competitive-analyzer pattern (9 items) and reflects the higher complexity of the architectural analysis task. Key additions:
- "Architectural approach stated with rationale (not just decisions)" — prevents decision-only outputs
- "Integration contracts defined for each touchpoint" — prevents vague "connects to X" statements
- "Technology recommendations include alternatives comparison (or explicit 'no new dependencies')" — prevents single-option recommendations

---

## Template Deviations

| Section | Template Default | This Agent | Reason |
|---------|-----------------|------------|--------|
| Protocol steps | Generic 5-step (Parse, Read, Execute, Write, Return) | 5 steps with step 3 expanded into 4 sub-tasks | Architectural analysis has distinct phases (codebase exploration, then per-section reasoning) that benefit from explicit guidance |
| Output location | Single fallback path | Dual path (pipeline slug vs. standalone timestamp) | Required by standalone usability constraint |
| Diagnostics | Generic execution fields | Added 5 architecture-specific boolean/count fields | More useful signal for pipeline orchestrator |
| Summary token budget | 100-300 tokens | 100-200 tokens | Architectural summary has a predictable structure; 200 is sufficient |
| Completion checklist | 4 items | 14 items | Output has 8 sections; each needs an explicit check |

---

## Rationale Summary

The agent is designed for two distinct use cases with one definition:

1. **Pipeline**: Receives PO output and optional research, reads prior context, explores codebase, produces architectural analysis for the Eng Lead and QA/Critic to consume downstream. The Pre-Flight Gates ensure it never designs in a vacuum.

2. **Standalone**: Accepts a problem statement directly, applies the same analytical protocol, writes to a timestamped standalone path. No pipeline plumbing required from the caller.

The system-prompt register ensures consistent analytical behavior across invocations — the agent knows who it is (a technical architect) and how it works (reads context first, explores codebase before claiming, produces structured analysis), regardless of what specific topic it receives.
