# Manual Test Protocol: P5.5 — Create-Agent Skill

## Test Environment

- **Test project**: PM-Essentials (`/mnt/c/projects/PM-Essentials`)
- **Existing skills**: product-idea-research (4 Opus sub-agents), git-worktrees (Haiku + 2 Sonnet sub-agents)
- **Prerequisite**: Copy `skills/create-agent/` to PM-Essentials `.claude/skills/create-agent/` (or symlink)
- **Prerequisite**: Ensure `anthropic-validator` skill is available in PM-Essentials

---

## TC1: Dedicated Agent for Existing Sub-Agent Role

**Purpose**: Validate that create-agent generates a proper single-purpose agent with system-prompt register for a role currently performed by an inline sub-agent.

**Invocation**:
```
/create-agent a market analyst agent that evaluates market size, competitive landscape, and go-to-market feasibility for product ideas
```

**Expected Interview (Stage 0)**:
- Q1-Q5 presented in a single AskUserQuestion round
- Agent identity should be clear from description

**Suggested Answers**:
- Q1: "Market analyst that evaluates TAM/SAM/SOM, competitive landscape, and go-to-market feasibility. Invoked as a sub-agent of product-idea-research, or standalone for quick market assessments."
- Q2: "Read, Glob, Grep, WebSearch, Write (for reports)"
- Q3: "Single focused task — analyzes market data and produces a structured report"
- Q4: "Yes — YAML diagnostic output with market sizing and competitive analysis findings"
- Q5: "Restricted — only needs read tools + WebSearch + Write for reports"

**Expected Classification (Stage 1)**:
- Architecture: **single** (not pipeline or teams)
- Tool permissions: **restricted** — `[Read, Glob, Grep, WebSearch, Write]`
- Configuration: diagnostic output section
- Template: `template-single-agent.md`

**Validation Criteria**:

| # | Check | Expected |
|---|-------|----------|
| 1 | Agent file location | `.claude/agents/market-analyst.md` |
| 2 | System-prompt register | Opens with "You are a..." identity statement |
| 3 | NOT task-instruction register | Body describes WHO the agent IS, not step-by-step WHAT to do |
| 4 | Pre-Flight Gate present | MUST/MUST NOT binding language |
| 5 | DO/DO NOT mission section | Concrete actions and prohibitions |
| 6 | Tool Usage Constraints | Allowed/Forbidden for each tool |
| 7 | Permissions Setup section | Documents what to add to settings.json |
| 8 | Diagnostic output section | YAML schema with path convention |
| 9 | Invocation section | Task tool invocation example |
| 10 | Description single-line | No multi-line YAML |
| 11 | anthropic-validator | 0 critical, 0 high findings |
| 12 | Post-generation summary | Architecture decision explained |

**PASS criteria**: All 12 checks pass. Agent reads as identity/expertise, not task steps.

---

## TC2: Standalone Agent (Not Tied to Existing Skill)

**Purpose**: Validate that create-agent generates an independent agent with proper conventions for a role not derived from an existing skill.

**Invocation**:
```
/create-agent a documentation quality reviewer that checks markdown docs for completeness, consistency, and broken links
```

**Suggested Answers**:
- Q1: "Documentation reviewer that audits .md files for missing sections, inconsistent formatting, dead links, and orphaned references. Invoked after doc updates or before releases."
- Q2: "Read, Glob, Grep, Bash (for link checking), Write (for reports)"
- Q3: "Single focused task — reads docs and produces a quality report"
- Q4: "Yes — Markdown report with findings + YAML diagnostics"
- Q5: "Restricted — read tools + Bash (read-only link checking) + Write for reports"

**Expected Classification (Stage 1)**:
- Architecture: **single**
- Tool permissions: **restricted** — `[Read, Glob, Grep, Bash, Write]`
- Configuration: diagnostic output, Bash constraints
- Template: `template-single-agent.md`

**Validation Criteria**:

| # | Check | Expected |
|---|-------|----------|
| 1 | Agent file location | `.claude/agents/doc-quality-reviewer.md` (or similar) |
| 2 | System-prompt register | Identity-first, expertise-anchored |
| 3 | Bash constraints | Allowed/Forbidden commands documented |
| 4 | Pre-Flight Gate | Binding language present |
| 5 | Diagnostic output | YAML schema included |
| 6 | Permissions Setup | settings.json config documented |
| 7 | anthropic-validator | 0 critical, 0 high findings |
| 8 | Post-generation summary | Permissions setup steps listed |
| 9 | Completion checklist | Present in generated agent |
| 10 | No unnecessary files | Only .claude/agents/{name}.md created |

**PASS criteria**: All 10 checks pass. Agent is self-contained, independent, properly constrained.

---

## TC3 (Optional): Pipeline Orchestrator Agent

**Purpose**: Validate that create-agent generates a multi-stage agent with F# pipeline notation and SA1 compliance.

**Invocation**:
```
/create-agent a release readiness checker that orchestrates dependency audit, changelog verification, and test coverage analysis before a release
```

**Suggested Answers**:
- Q1: "Release readiness agent that runs 3 checks before a release: dependency audit (outdated/vulnerable packages), changelog completeness, and test coverage. Reports go/no-go verdict."
- Q2: "Read, Glob, Grep, Bash, Write, Task (for sub-agents)"
- Q3: "Multiple stages — dependency audit, then changelog check, then test coverage. Each depends on prior stage for scope."
- Q4: "Yes — comprehensive YAML report with per-stage findings and overall verdict"
- Q5: "Full access for orchestration — sub-agents are restricted individually"
- Q6 (follow-up): "Dependent — changelog scope depends on dependency changes, coverage analysis depends on changed areas"

**Expected Classification (Stage 1)**:
- Architecture: **pipeline** (3 dependent stages)
- Tool permissions: **full** (orchestrator needs Task tool)
- Configuration: SA1 4-part template, subagent-prompting dependency, diagnostic output
- Template: `template-pipeline-agent.md`

**Validation Criteria**:

| # | Check | Expected |
|---|-------|----------|
| 1 | F# pipeline notation | Present with 3+ stages |
| 2 | 4-part template | GOAL/CONSTRAINTS/CONTEXT/OUTPUT for each sub-agent stage |
| 3 | subagent-prompting in skills: | Frontmatter dependency present |
| 4 | Task in tools: | Listed in frontmatter tools |
| 5 | Stage log paths | Each stage writes to logs/ |
| 6 | System-prompt register | "You are an orchestrator..." identity |
| 7 | Anti-thought traps | "Do NOT perform sub-agent work yourself" |
| 8 | anthropic-validator | 0 critical, 0 high findings |

**PASS criteria**: All 8 checks pass. Pipeline structure is correct and well-documented.

---

## Cross-Validation

| # | Check | How to Verify |
|---|-------|---------------|
| 1 | Skill appears in `/` menu | Type `/create-agent` in Claude Code |
| 2 | Diagnostic YAML written | Check `logs/diagnostics/create-agent-*.yaml` exists after each TC |
| 3 | Sub-agent was spawned | Verify in session output that a Sonnet sub-agent was spawned for generation (not done inline) |
| 4 | Classification confirmed | User was asked to confirm classification before generation |
| 5 | Scaffold disclaimer | "Next steps" section presented with customize guidance |

---

## Notes

- TC1 and TC2 are required. TC3 is optional (pipeline agents are less common).
- Run TC1 first — it validates the core system-prompt register distinction.
- If TC1 passes but TC2 fails, the issue is likely in the content-guidance rather than the template.
- All TCs can be run in PM-Essentials. Generated agents go to PM-Essentials `.claude/agents/`.
