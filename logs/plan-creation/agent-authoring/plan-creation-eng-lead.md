# Authoring Log: plan-creation-eng-lead

**Agent file:** `.claude/agents/plan-creation-eng-lead.md`
**Author:** Engineering & Delivery Lead authoring session
**Date:** 2026-02-23
**Template used:** `skills/create-skill/references/agent-template.md`
**Reference pattern:** `.claude/agents/product-ideation-competitive-analyzer.md`

---

## Design Decisions

### 1. Combined Role Identity

The task brief specifies a combined "Engineering & Delivery Lead" role, collapsing what might otherwise be separate Engineering Lead and Delivery Lead agents. The identity paragraph establishes both concerns explicitly: "implementation planning, work breakdown, effort estimation" (engineering) and "delivery scheduling, dependency analysis, critical path identification, milestone definition, risk identification, and parallel execution planning" (delivery). This avoids any ambiguity about scope boundaries and explains the combination without burying it.

### 2. System-Prompt Register Throughout

Per agent-conventions.md, the body is the system prompt — WHO the agent IS. Every section is written in identity/behavioral register:
- "You produce structured delivery plans..." (not "Produce a structured delivery plan")
- "You apply this calibration..." (not "Apply this calibration")
- Protocol steps describe how the agent works, not imperative instructions for a single invocation

The one deviation: the Completion Checklist uses imperative checkboxes. This matches the reference pattern (competitive-analyzer) and is standard across all Bulwark agents. It is a structural convention, not a register violation.

### 3. Pre-Flight Gate — Four Obligations

The reference pattern (competitive-analyzer) uses four REQUIRED obligations. This agent follows the same structure. The four obligations were chosen to cover the most likely failure modes:
1. Reading prior output first (prevents scope drift from pipeline context)
2. Codebase assessment before estimating (prevents estimates disconnected from reality)
3. All eight sections required (prevents partial outputs that break synthesis)
4. Exact output path compliance (SA2 enforcement)

### 4. Dual-Mode Invocation (Pipeline + Standalone)

The task brief explicitly requires standalone usability. The Invocation section lists both "Pipeline stage" and "Direct standalone" rows in the method table. The Protocol's "Parse Input" step tells the agent to read the OUTPUT section of the prompt for the path — this works in both modes because the orchestrator always specifies a path in pipeline mode, and standalone callers can do the same. The Output section provides a fallback standalone path pattern for callers who do not specify one.

### 5. Effort Calibration Table in Protocol

The task brief does not specify a calibration table, but delivery planning without shared units is useless in a multi-agent pipeline (the QA/Critic and synthesis stage need comparable estimates from the Architect and Eng Lead). Adding an explicit session-based calibration (1 session ≈ 90-120 minutes) inside the Protocol ensures that estimates from this agent are comparable across invocations and interpretable by downstream stages. This is a behavioral constraint on the agent, not a task instruction.

### 6. Eight Output Sections Mandated

The task brief specifies eight output areas: WBS, sequencing, estimates, dependency graph, milestones, parallel opportunities, risk register, resource considerations. All eight appear in:
- The DO section (mission definition)
- The Pre-Flight Gate (obligation #3)
- The Completion Checklist (verification)
- The Output report template (format specification)

This triple-anchoring pattern is borrowed from the competitive-analyzer's treatment of Porter's Five Forces — the framework appears in Pre-Flight Gate, Protocol, and Output format.

### 7. YAML-Compatible Output Structure

The task brief notes that synthesis stage needs data that maps into a specific YAML schema with `phases`, `workpackages`, `milestones`, `dependency_graph`. The output report template uses prose tables and structured lists that directly correspond to those YAML fields:
- WBS section → `phases[].workpackages[]`
- Dependency graph section → `dependency_graph`
- Milestones section → `milestones[]`

The agent does not produce YAML directly (that belongs to synthesis), but the prose structure is deliberately designed to map cleanly. This was noted in the task brief CONTEXT and is implemented as a structural constraint on the output template.

### 8. Diagnostics Schema Calibrated to Delivery Planning

Standard diagnostic fields (steps_completed, findings, errors) are generic. For a delivery planner, the meaningful execution metrics are:
- `files_read`: assesses whether codebase exploration happened
- `workpackages_defined`, `phases_defined`: quantifies plan coverage
- `risks_identified`: quantifies risk register completeness
- `total_sessions_low/high`: captures estimate range for orchestrator comparison with Architect estimates
- `critical_path_length`: key output metric

These are more informative to the synthesis stage than generic counters.

---

## Template Deviations

| Deviation | Location | Rationale |
|-----------|----------|-----------|
| No `skills: subagent-output-templating` in frontmatter | Frontmatter | This skill is for pipeline agents that need structured templating. The eng lead writes freeform prose plans, not templated structured data. The output format is defined in the agent body, not delegated to a templating skill. |
| Effort calibration table added to Protocol | Protocol Step 4 | Not in the template but essential for comparable estimates across pipeline invocations. |
| Eight mandatory output sections (not generic "findings") | Output template | Domain-specific to delivery planning; generic template uses generic "findings" format. |
| Diagnostics fields customized | Diagnostics | Domain-specific fields replace generic `findings: 0, errors: 0` counters. |
| Parallel Opportunities as a named output section | Output template | Not explicit in base template but required by task brief and important for synthesis stage. |

---

## Line Count

Final agent file: approximately 220 lines. Within the 150-250 line target.

---

## Validation Notes

- Description field is single-line (YAML frontmatter silent failure prevention, GitHub #9817)
- Model specified as `sonnet` with no version suffix (alias picks up latest per constraint)
- All output paths use `$PROJECT_DIR` prefix (not relative paths, not `/tmp/`)
- No `context: fork` in frontmatter — this is a Task tool agent, not a fork-context skill
- Permissions Setup section included (tool permissions manual setup per GitHub #10093)
- Completion Checklist covers all eight output sections
