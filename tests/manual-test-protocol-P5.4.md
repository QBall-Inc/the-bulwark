# Manual Test Protocol: P5.4 — Skill Creator

## Test Environment

- **Project**: PM-Essentials (`/mnt/c/projects/PM-Essentials`)
- **Skill location**: `.claude/skills/skill-creator/` (copied from Bulwark)
- **Why isolated**: skill-creator generates new skills — testing in Bulwark would pollute the project with test artifacts

## Prerequisites

1. PM-Essentials project exists at `/mnt/c/projects/PM-Essentials`
2. `.claude/skills/skill-creator/` populated with SKILL.md + references/ + templates/
3. `.claude/skills/subagent-prompting/` available (skill-creator depends on it)
4. Start a fresh Claude Code session in the PM-Essentials project

## Test Cases

---

### TC1: Complex Skill — Market & Competitive Research

**Purpose**: Validate the research/multi-agent template path. This is the most complex classification and generation path.

**Invocation**:
```
/skill-creator a skill that takes a product idea, does deep research on the market landscape, competitive analysis, and returns a structured assessment with market sizing, competitor profiles, and opportunity gaps
```

**Expected Classification**:
- Context: `fork` (isolated multi-step work)
- Sub-agents: `parallel Task tool sub-agents` (independent research viewpoints)
- Supporting files: `references/` + `templates/`
- Template: `template-research.md`

**Validation Checklist**:

| # | Check | Pass/Fail | Notes |
|---|-------|-----------|-------|
| 1 | Interview conducted (Q1-Q5 presented together) | | |
| 2 | Follow-up questions triggered (Q6-Q7 at minimum for multi-agent) | | |
| 3 | Classification presented with three decisions | | |
| 4 | User prompted to confirm classification before generation | | |
| 5 | Sonnet sub-agent spawned for generation (not done by orchestrator) | | |
| 6 | Generated SKILL.md has single-line description | | |
| 7 | Generated SKILL.md has "When to Use" trigger table | | |
| 8 | Generated SKILL.md has "DO NOT use for" section | | |
| 9 | Generated SKILL.md has Pre-Flight Gate with MUST/MUST NOT | | |
| 10 | Generated SKILL.md has F# pipeline notation | | |
| 11 | Generated SKILL.md includes `subagent-prompting` in skills: dependency | | |
| 12 | Generated references/ directory with viewpoint/role files | | |
| 13 | Generated templates/ directory with output template(s) | | |
| 14 | anthropic-validator run on generated output | | |
| 15 | Post-generation summary presented with architectural decisions | | |
| 16 | "Next steps" communicated (scaffold, not production-ready) | | |
| 17 | Diagnostic YAML written to logs/diagnostics/ | | |
| 18 | Generated skill structure matches template-research.md pattern | | |

**Kill Criteria** (any = FAIL):
- Orchestrator generates skill files itself instead of spawning sub-agent
- Interview skipped entirely
- Classification not presented for user confirmation
- Generated SKILL.md has multi-line description in frontmatter
- No references/ or templates/ generated for a research-type skill

---

### TC2: Simple Skill — Git Worktrees

**Purpose**: Validate the simple/vanilla template path. Tests the opposite end of the classification spectrum from TC1.

**Invocation**:
```
/skill-creator a skill that provides guidance and commands for effectively using git worktrees — creating, switching, cleaning up worktrees, and best practices for parallel development workflows
```

**Expected Classification**:
- Context: `inline` (needs conversation history to apply guidance contextually)
- Sub-agents: `none` (single-purpose knowledge/guideline skill)
- Supporting files: none (or minimal references/)
- Template: `template-simple.md` (or `template-reference-heavy.md` if extensive content detected)

**Validation Checklist**:

| # | Check | Pass/Fail | Notes |
|---|-------|-----------|-------|
| 1 | Interview conducted (Q1-Q5 presented together) | | |
| 2 | No follow-up questions (simple skill should not trigger Q6-Q10) | | |
| 3 | Classification presented with three decisions | | |
| 4 | Context classified as inline (not fork) | | |
| 5 | Sub-agents classified as none | | |
| 6 | User prompted to confirm classification before generation | | |
| 7 | Sonnet sub-agent spawned for generation | | |
| 8 | Generated SKILL.md has single-line description | | |
| 9 | Generated SKILL.md has "When to Use" trigger table | | |
| 10 | Generated SKILL.md has "DO NOT use for" section | | |
| 11 | Generated SKILL.md does NOT have Pre-Flight Gate (no sub-agents) | | |
| 12 | No references/ directory generated (or minimal if reference-heavy) | | |
| 13 | No templates/ directory generated | | |
| 14 | anthropic-validator run on generated output | | |
| 15 | Post-generation summary presented | | |
| 16 | Diagnostic YAML written to logs/diagnostics/ | | |
| 17 | Generated skill is concise (<150 lines) | | |
| 18 | Generated instructions are specific and actionable (not vague guidelines) | | |

**Kill Criteria** (any = FAIL):
- Classified as fork (worktrees guidance needs conversation context)
- Sub-agents generated for a simple knowledge skill
- Generated SKILL.md exceeds 200 lines (over-engineered for simple type)
- Interview skipped

---

### TC3: Mid-Complexity Skill — Dependency Audit Pipeline (Optional)

**Purpose**: Validate the pipeline template path. Tests sequential sub-agent orchestration. Run if TC1 and TC2 results warrant additional coverage.

**Invocation**:
```
/skill-creator a skill that audits project dependencies for security vulnerabilities, license compliance, and version staleness — runs three sequential checks and produces a consolidated report
```

**Expected Classification**:
- Context: `fork` (isolated multi-step work)
- Sub-agents: `sequential Task tool sub-agents` (dependent operations — each check builds on prior)
- Supporting files: `references/` + `templates/`
- Template: `template-pipeline.md`

**Validation Checklist**:

| # | Check | Pass/Fail | Notes |
|---|-------|-----------|-------|
| 1 | Interview conducted with follow-up questions (Q6 triggered for dependent ops) | | |
| 2 | Classification: sequential sub-agents (not parallel) | | |
| 3 | Template: template-pipeline.md selected | | |
| 4 | Sonnet sub-agent spawned for generation | | |
| 5 | Generated SKILL.md has Pre-Flight Gate with MUST/MUST NOT | | |
| 6 | Generated SKILL.md has F# pipeline notation showing sequential stages | | |
| 7 | Generated SKILL.md has stage definitions with 4-part prompt structure | | |
| 8 | Generated SKILL.md includes `subagent-prompting` in skills: dependency | | |
| 9 | Generated references/ with stage-specific reference files | | |
| 10 | Generated templates/ with output template + diagnostic YAML | | |
| 11 | Error handling table present | | |
| 12 | anthropic-validator passes (0 critical, 0 high) | | |
| 13 | Post-generation summary with pipeline architecture decisions | | |
| 14 | Diagnostic YAML written | | |

**Kill Criteria** (any = FAIL):
- Classified as parallel (dependency audit stages are dependent/sequential)
- No Pre-Flight Gate for a pipeline skill
- No F# pipeline notation
- Orchestrator generates files itself

---

## Overall Assessment

### Quality Dimensions

After completing TC1 and TC2 (minimum), assess:

| Dimension | Question | Rating (1-5) |
|-----------|----------|---------------|
| **Classification accuracy** | Did the three-decision framework produce correct classifications? | |
| **Interview quality** | Were questions relevant? Follow-ups appropriate? Not over-interviewing? | |
| **Generation quality** | Does generated output follow the template structure? | |
| **Content quality** | Are generated instructions specific and actionable (not vague)? | |
| **Activation potential** | Would the generated description reliably trigger skill loading? | |
| **Scaffold usability** | Could a user take the output and customize it into a production skill? | |

### Decision Gate

- If all kill criteria pass and average quality rating >= 3: **P5.4 PASS**
- If any kill criteria fail: **P5.4 FAIL** — document failures, fix in Session 69
- If quality ratings average < 3: **P5.4 CONDITIONAL** — document specific gaps for improvement

## Results

*To be filled during testing*

| TC | Status | Kill Criteria | Quality Avg | Notes |
|----|--------|---------------|-------------|-------|
| TC1 | | | | |
| TC2 | | | | |
| TC3 | | | | |
