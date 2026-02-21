# Manual Test Protocol: P5.5 — Create-Subagent Skill

## Test Environment

- **Test project**: PM-Essentials (`/mnt/c/projects/PM-Essentials`)
- **Existing skills**: product-idea-research (4 Opus sub-agents), git-worktrees (Haiku + 2 Sonnet sub-agents)
- **Prerequisite**: Copy `skills/create-subagent/` to PM-Essentials `.claude/skills/create-subagent/` (or symlink)
- **Prerequisite**: Ensure `anthropic-validator` skill is available in PM-Essentials

---

## TC1: Dedicated Agent for Existing Sub-Agent Role

**Purpose**: Validate that create-subagent generates a proper single-purpose agent with system-prompt register for a role currently performed by an inline sub-agent.

**Invocation**:
```
/create-subagent a market analyst agent that evaluates market size, competitive landscape, and go-to-market feasibility for product ideas
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
| 12 | Post-generation summary | Architectural decisions explained |

**PASS criteria**: All 12 checks pass. Agent reads as identity/expertise, not task steps.

---

## TC2: Standalone Agent (Not Tied to Existing Skill)

**Purpose**: Validate that create-subagent generates an independent agent with proper conventions for a role not derived from an existing skill.

**Invocation**:
```
/create-subagent a documentation quality reviewer that checks markdown docs for completeness, consistency, and broken links
```

**Suggested Answers**:
- Q1: "Documentation reviewer that audits .md files for missing sections, inconsistent formatting, dead links, and orphaned references. Invoked after doc updates or before releases."
- Q2: "Read, Glob, Grep, Bash (for link checking), Write (for reports)"
- Q3: "Single focused task — reads docs and produces a quality report"
- Q4: "Yes — Markdown report with findings + YAML diagnostics"
- Q5: "Restricted — read tools + Bash (read-only link checking) + Write for reports"

**Expected Classification (Stage 1)**:
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

## TC3: Pipeline Routing (Redirect to create-skill)

**Purpose**: Validate that create-subagent detects pipeline/orchestration requests and redirects to create-skill instead of generating an infeasible agent.

**Invocation**:
```
/create-subagent a release readiness checker that orchestrates dependency audit, changelog verification, and test coverage analysis before a release
```

**Suggested Answers**:
- Q1: "Release readiness agent that runs 3 checks before a release: dependency audit (outdated/vulnerable packages), changelog completeness, and test coverage. Reports go/no-go verdict."
- Q2: "Read, Glob, Grep, Bash, Write, Task (for sub-agents)"
- Q3: "Multiple stages — dependency audit, then changelog check, then test coverage. Each depends on prior stage for scope."
- Q4: "Yes — comprehensive YAML report with per-stage findings and overall verdict"
- Q5: "Full access for orchestration — sub-agents are restricted individually"
- Q6 (follow-up): "Dependent — changelog scope depends on dependency changes, coverage analysis depends on changed areas"

**Expected Behavior**:
- After Q3 follow-ups reveal dependent stages (Q6), routing check triggers
- Pipeline STOPS — does NOT proceed to Stage 1
- User receives redirect message mentioning `/create-skill`

**Validation Criteria**:

| # | Check | Expected |
|---|-------|----------|
| 1 | Pipeline stops | Does NOT proceed to classification (Stage 1) |
| 2 | Redirect message | User sees message about using `/create-skill` |
| 3 | Message explains why | Mentions sub-agents can't spawn sub-agents |
| 4 | Message explains alternative | Mentions create-skill generates orchestrating skill + sub-agent files |
| 5 | Diagnostic written | `logs/diagnostics/create-subagent-*.yaml` with `outcome: redirected` |
| 6 | No agent file generated | No file at `.claude/agents/release-readiness-checker.md` |

**PASS criteria**: All 6 checks pass. Pipeline/teams requests are cleanly redirected.

---

## TC4 (Optional): Pipeline Skill with Sub-Agents via create-skill

**Purpose**: Validate that create-skill generates an orchestrating skill + dedicated sub-agent files when the pipeline template is selected.

**Invocation**:
```
/create-skill a release readiness checker that orchestrates dependency audit, changelog verification, and test coverage analysis before a release
```

**Expected Classification**:
- Context: fork (isolated multi-step work)
- Sub-agents: sequential Task tool (dependent stages)
- Supporting files: references/, templates/
- Template: `template-pipeline.md`

**Validation Criteria**:

| # | Check | Expected |
|---|-------|----------|
| 1 | SKILL.md generated | `skills/release-readiness/SKILL.md` (or similar) |
| 2 | Sub-agent files generated | `.claude/agents/release-readiness-{stage}.md` per stage |
| 3 | Orchestrating skill references sub-agents | `Task(subagent_type="release-readiness-{stage}")` |
| 4 | Sub-agents use system-prompt register | Each opens with identity statement |
| 5 | anthropic-validator passes on skill | 0 critical, 0 high |
| 6 | anthropic-validator passes on each agent | 0 critical, 0 high |
| 7 | Post-generation summary | Lists both skill and agent files |
| 8 | Permissions documented | Sub-agent tool permissions listed |

**PASS criteria**: All 8 checks pass. Pipeline skill and sub-agents generated as a cohesive unit.

---

## Cross-Validation

| # | Check | How to Verify |
|---|-------|---------------|
| 1 | Skill appears in `/` menu | Type `/create-subagent` in Claude Code |
| 2 | Diagnostic YAML written | Check `logs/diagnostics/create-subagent-*.yaml` exists after each TC |
| 3 | Sub-agent was spawned | Verify in session output that a Sonnet sub-agent was spawned for generation (not done inline) |
| 4 | Classification confirmed | User was asked to confirm classification before generation |
| 5 | Scaffold disclaimer | "Next steps" section presented with customize guidance |

---

## Notes

- TC1, TC2, and TC3 are required. TC4 is optional (validates create-skill pipeline enhancement).
- Run TC1 first — it validates the core system-prompt register distinction.
- TC3 validates the routing logic — if it fails, the user could create infeasible agents.
- TC1 was previously validated as PASS in Session 71 (12/12 checks). Re-run to confirm rename didn't break anything.
- If TC1 passes but TC2 fails, the issue is likely in the content-guidance rather than the template.
- All TCs can be run in PM-Essentials. Generated agents go to PM-Essentials `.claude/agents/`.
