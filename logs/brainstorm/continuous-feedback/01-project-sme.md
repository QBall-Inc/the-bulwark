---
role: project-sme
topic: P5.3 continuous-feedback skill
recommendation: proceed
key_findings:
  - The project has a mature multi-stage skill pattern (Pre-Flight → Parallel/Sequential Agents → Synthesis) with proven conventions for sub-agent prompting, output templates, diagnostics, and validation — continuous-feedback should follow this exact structure
  - Session handoffs (62 files) use a consistent template with structured sections (Learnings, Technical Decisions, Blockers) that are machine-parseable, and MEMORY.md provides a curated summary — both are well-suited as Collect stage inputs
  - The anthropic-validator and quality gates (typecheck/lint/test) provide ready-made Validate stage infrastructure requiring no new tooling
---

# P5.3 Continuous-Feedback Skill — Project SME

## Summary

The Bulwark codebase has a well-established pattern for multi-stage skills using Task tool sub-agents, with 62 session handoffs and a structured MEMORY.md providing rich input data for the Collect stage. The existing validation infrastructure (anthropic-validator, quality gates) covers the Validate stage entirely. The primary engineering challenge is the Analyze stage — specifically, building per-skill-type specialization that extracts actionable improvement targets from heterogeneous input sources.

## Detailed Analysis

### Existing Multi-Stage Skill Patterns

The codebase contains three distinct multi-stage skill archetypes that continuous-feedback should draw from:

**1. bulwark-research (5 parallel Sonnet agents)** — `/mnt/c/projects/the-bulwark/skills/bulwark-research/SKILL.md`
- Structure: Pre-Flight → 5 Parallel Viewpoint Agents → Synthesis → Critical Evaluation Gate
- Key patterns: AskUserQuestion interview loop, slugified output directories (`logs/research/{topic-slug}/`), numbered output files (`01-direct-investigation.md`, etc.), diagnostic YAML, token budget checks at each stage
- Directory layout: `SKILL.md` + `references/viewpoint-*.md` (5 files) + `templates/` (3 files)

**2. bulwark-brainstorm (5 sequenced Opus agents)** — `/mnt/c/projects/the-bulwark/skills/bulwark-brainstorm/SKILL.md`
- Structure: Pre-Flight → SME (sequential first) → 3 Roles (parallel) → Critic (sequential last) → Synthesis → Critical Evaluation Gate
- Key patterns: SME explores codebase autonomously (no hardcoded paths), role-specific reference files, synthesis template with enforcement language, post-synthesis user Q&A
- This is the closest analog to continuous-feedback's pipeline shape (collect data first, then analyze in parallel, then synthesize)

**3. test-audit (AST + Haiku + Sonnet pipeline)** — `/mnt/c/projects/the-bulwark/skills/test-audit/SKILL.md`
- Structure: Stage 0 (AST scripts, deterministic) → Stage 1 (Classification, Haiku) → Stage 2 (Mock Detection, Sonnet) → Stage 3 (Synthesis, Sonnet)
- Key patterns: Pre-Flight Gate with explicit MUST/MUST NOT sections, mode selection based on input size, skill dependencies in frontmatter (`skills: [test-classification, mock-detection, ...]`)

**Prescription for continuous-feedback**: Follow the bulwark-brainstorm directory layout pattern — `SKILL.md` + `references/` (per-skill-type specialization docs) + `templates/` (stage output templates, diagnostic YAML). Use the Pre-Flight Gate blocking pattern from test-audit. Use the numbered output file convention from bulwark-research (`logs/continuous-feedback/{run-slug}/01-collect.md`, `02-analyze.md`, etc.).

### Session Handoff and Memory Structure

**Session handoffs** — `/mnt/c/projects/the-bulwark/sessions/session_{N}_{YYYYMMDD}.md` (62 files)

The session-handoff skill (`/mnt/c/projects/the-bulwark/skills/session-handoff/SKILL.md`) defines a rigid template with these machine-parseable sections:
- **YAML header**: session number, date, phase, task, status, tokens consumed
- **Session Summary**: 2-3 sentence outcome description
- **What Was Accomplished**: Checkbox list with file paths
- **Files Created/Modified**: Table with file, action, lines, purpose
- **Verification Status**: Table with check type, pass/fail, notes
- **Technical Decisions**: Structured as Decision/Rationale/Impact blocks
- **What's Next**: Numbered actionable steps
- **Blockers / Issues**: Structured blockers
- **Learnings**: Free-text patterns discovered, lessons learned

The Learnings and Technical Decisions sections are the highest-value inputs for the Analyze stage. Learnings contain patterns like "CRLF vigilance on WSL", "Pipeline suggestion fabrication", "TestAudit gap pattern" — each representing a concrete improvement opportunity.

**MEMORY.md** — `/home/ashay/.claude/projects/-mnt-c-projects-the-bulwark/memory/MEMORY.md`

This is the curated project memory with these sections:
- **Project Context**: High-level state, completed phases
- **Key Patterns**: Operational patterns (orchestrator role, test workflow)
- **Defects & Lessons Learned**: Cataloged defects (DEF-P4-005 through DEF-P4-007) and enhancements (ENH-P4-003) with precise descriptions
- **Architecture Decisions**: Documented decisions with rationale
- **Framework Observations**: FW-OBS-001 through FW-OBS-005

**Prescription for Collect stage**: Parse session handoffs by extracting YAML header, Learnings section, Technical Decisions section, and Blockers section. Parse MEMORY.md by extracting Defects, Lessons Learned, and Framework Observations. For user-specified custom paths, read files and extract any structured learning content. The Collect agent should output a normalized intermediate format (list of learning items with source, category, and content) that the Analyze stage can process uniformly.

### Validation Tools and Quality Gates

**anthropic-validator** — `/mnt/c/projects/the-bulwark/skills/anthropic-validator/SKILL.md`

Uses Main Context Orchestration pattern: spawns claude-code-guide agent to fetch latest standards, then spawns bulwark-standards-reviewer to analyze the asset. Produces reports in `logs/validations/`. This is the primary validation tool for any proposed skill modifications.

**Quality gates** — defined in `Rules.md` (V2-V4) and the Justfile:
- `just typecheck` — TypeScript type checking
- `just lint` — Linting
- `just test` — Test execution

**Prescription for Validate stage**: Run `/anthropic-validator` on any proposed skill/agent modifications. If proposals include code changes, run `just typecheck && just lint && just test`. The Validate stage does NOT need a sub-agent — the orchestrator can run these tools directly, matching the existing pattern where validation is deterministic and tool-based.

### Per-Skill Specialization Opportunities

The tasks.yaml acceptance criteria list four specialization types. Here is what exists in the codebase for each:

**1. code-review specialization** — `/mnt/c/projects/the-bulwark/skills/code-review/`
- Has `references/{section}-patterns.md` files (security, type-safety, linting, standards)
- Has `frameworks/{name}.md` for framework-specific patterns
- Improvement targets: new security patterns from sessions, new framework patterns, review lens updates based on recurring findings

**2. test-audit specialization** — `/mnt/c/projects/the-bulwark/skills/test-audit/`
- Has 4 AST scripts (verify-count, skip-detect, ast-analyze, and scale classification)
- Has `skills/mock-detection/`, `skills/test-classification/`, `skills/assertion-patterns/`, `skills/component-patterns/` as sub-skills
- Improvement targets: new detection patterns for mock-detection, new assertion pattern categories, AST script gap analysis from sessions where violations were missed

**3. bug-magnet-data specialization** — `/mnt/c/projects/the-bulwark/skills/bug-magnet-data/`
- Edge case data sets for testing
- Improvement targets: new edge case categories from bugs found in sessions, external edge case sources

**4. General skills** — All other skills
- Pattern extraction from session learnings, incremental updates to skill instructions based on observed failures (e.g., DEF-P4-005 led to SC1-SC3 binding language, DEF-P4-006 led to SA2 closed-loop language)

**Prescription for Analyze stage**: Create per-skill-type reference files (`references/specialize-code-review.md`, `references/specialize-test-audit.md`, etc.) that instruct the Analyze sub-agent on what to look for in collected learnings for each skill type. The Analyze agent receives the normalized learning items from Collect and the relevant specialization reference, then produces targeted improvement recommendations.

### Integration Points and Constraints

**Integration points:**
1. **Input**: `sessions/*.md` (62 files, growing), MEMORY.md (project + agent memory paths), user-specified paths
2. **Output**: Proposal document in `logs/continuous-feedback/{run-slug}/` — NOT direct file modifications
3. **Validation**: anthropic-validator skill, quality gates via Justfile
4. **Skill dependencies**: `subagent-prompting` (4-part template), potentially `subagent-output-templating`
5. **Sync targets**: Must sync to `.claude/skills/` (dogfood copy) and standalone repo (essential-agents-skills) per project convention

**Constraints — what must not be disrupted:**
1. **No direct file modifications**: The Act stage produces a proposal document only. The user reviews and applies. This is a firm design decision from the user.
2. **Task tool sub-agents only**: Agent Teams are NOT applicable (Session 62 decision). Use `Task(subagent_type="general-purpose", model=...)` pattern.
3. **SA2 compliance**: All sub-agent outputs written to `logs/`. Orchestrator reads logs, not raw output.
4. **General-purpose**: Must work on any Claude Code project, not just Bulwark. Assumes `.claude/` skills/agents and `sessions/` handoffs exist, but input paths must be configurable.
5. **Frontmatter**: `user-invocable: true`, `skills: [subagent-prompting]`
6. **No disruption to existing skills**: continuous-feedback reads existing skills but does not modify them. Modifications are proposal-only.

## Recommendation

**Proceed.** The codebase provides all necessary infrastructure for continuous-feedback. The multi-stage skill pattern is mature (3+ proven implementations), the input data (sessions, MEMORY.md) is well-structured for parsing, and the validation tools exist. The primary engineering work is in the Analyze stage's per-skill specialization and the Act stage's proposal document format. Follow the bulwark-brainstorm pipeline shape (Collect first → parallel Analyze agents per skill type → synthesize proposals → validate). Target 4 sub-agents: 1 Collector (Sonnet, parses inputs), 2-3 Analyzers (Sonnet, parallel, per skill type detected), 1 Proposer (Sonnet, generates change proposals from analysis). Orchestrator handles Validate stage directly.

## Files Explored

| File | Relevance |
|------|-----------|
| `/mnt/c/projects/the-bulwark/Rules.md` | Immutable contract — CS, T, V, SC, SR rules that constrain skill design |
| `/mnt/c/projects/the-bulwark/plans/tasks.yaml` | Current task state, P5.3 acceptance criteria, dependencies, design decisions |
| `/mnt/c/projects/the-bulwark/CLAUDE.md` | Project rules (OR, SA), sub-agent conventions, validation requirements |
| `/mnt/c/projects/the-bulwark/.claude/skills/bulwark-brainstorm/SKILL.md` | Closest analog skill — sequential+parallel pipeline, SME autonomy, synthesis pattern |
| `/mnt/c/projects/the-bulwark/.claude/skills/bulwark-research/SKILL.md` | Parallel Sonnet agent pattern, viewpoint references, output templates |
| `/mnt/c/projects/the-bulwark/.claude/skills/code-review/SKILL.md` | Multi-section review pattern, framework detection, reference file structure |
| `/mnt/c/projects/the-bulwark/.claude/skills/test-audit/SKILL.md` | Pre-Flight Gate pattern, mode selection, AST+LLM pipeline, sub-skill dependencies |
| `/mnt/c/projects/the-bulwark/.claude/skills/fix-bug/SKILL.md` | F# pipeline syntax, conditional stage execution, loop pattern |
| `/mnt/c/projects/the-bulwark/.claude/skills/pipeline-templates/SKILL.md` | Pipeline selection guide, model selection rubric, available pipeline types |
| `/mnt/c/projects/the-bulwark/.claude/skills/session-handoff/SKILL.md` | Session handoff template — defines the structure Collect stage must parse |
| `/mnt/c/projects/the-bulwark/.claude/skills/anthropic-validator/SKILL.md` | Validation infrastructure — Main Context Orchestration, dynamic doc fetching |
| `/mnt/c/projects/the-bulwark/.claude/skills/subagent-prompting/SKILL.md` | 4-part template (GOAL/CONSTRAINTS/CONTEXT/OUTPUT) required for all sub-agents |
| `/mnt/c/projects/the-bulwark/sessions/session_62_20260216.md` | Latest session — Agent Teams decisions, schedule, P5.3 scope |
| `/mnt/c/projects/the-bulwark/sessions/session_60_20260216.md` | P5.14 completion — reasoning depth, Critical Evaluation Gates |
| `/mnt/c/projects/the-bulwark/sessions/session_45_20260208.md` | Learnings section example — CRLF, pipeline fabrication, TestAudit gaps |
| `/mnt/c/projects/the-bulwark/docs/architecture.md` | Problem statement, core premises, pipeline orchestration patterns |
| `/home/ashay/.claude/projects/-mnt-c-projects-the-bulwark/memory/MEMORY.md` | Project memory — defects, lessons, architecture decisions, framework observations |
