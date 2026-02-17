---
role: development-lead
topic: P5.3 continuous-feedback skill
recommendation: proceed
key_findings:
  - Skill is buildable in 1 session using established patterns — the directory layout, sub-agent orchestration, diagnostic output, and validation infrastructure all exist and require no new tooling
  - The Collect stage is straightforward (structured markdown parsing with known templates); the Analyze stage is the engineering risk due to per-skill-type specialization requiring 4 reference documents that encode domain expertise
  - The Act stage (proposal document generation) is the highest-value and highest-difficulty component — the Proposer agent must produce concrete, applicable diffs rather than vague recommendations, and no existing skill demonstrates this pattern
---

# P5.3 Continuous-Feedback Skill — Development Lead

## Summary

The continuous-feedback skill is feasible with existing project infrastructure and follows proven multi-stage skill patterns. The primary implementation risk is not structural (the pipeline shape is well-understood) but content-quality: ensuring the Analyze and Act stages produce actionable, specific improvements rather than generic observations. Build order is straightforward with no blocking external dependencies.

## Detailed Analysis

### Implementation Feasibility

**Available and requires no creation:**

1. **Skill directory structure**: `SKILL.md` + `references/` + `templates/` — proven in `/mnt/c/projects/the-bulwark/.claude/skills/bulwark-brainstorm/` and `/mnt/c/projects/the-bulwark/.claude/skills/bulwark-research/`. Copy this layout exactly.

2. **Sub-agent orchestration**: The `subagent-prompting` skill at `/mnt/c/projects/the-bulwark/.claude/skills/subagent-prompting/SKILL.md` provides the 4-part prompt template (GOAL/CONSTRAINTS/CONTEXT/OUTPUT). All sub-agents use `Task(subagent_type="general-purpose", model="sonnet")`. No Opus agents needed — this is analysis and proposal generation, not code writing.

3. **Validation infrastructure**: `/anthropic-validator` exists and is callable from the orchestrator. Quality gates (`just typecheck`, `just lint`, `just test`) are available via Justfile. The Validate stage requires zero new tooling.

4. **Input data format**: Session handoffs follow a rigid template defined in `/mnt/c/projects/the-bulwark/.claude/skills/session-handoff/SKILL.md` — YAML header, Learnings, Technical Decisions, Blockers sections. MEMORY.md has structured sections (Defects, Lessons Learned, Architecture Decisions, Framework Observations). Both are machine-parseable by a Sonnet agent without AST scripts.

5. **Output conventions**: `logs/continuous-feedback/{run-slug}/` with numbered files (`01-collect.md`, `02-analyze-{type}.md`, `03-proposal.md`). Diagnostic YAML to `logs/diagnostics/`. All conventions established.

**Requires creation (new content, not new patterns):**

1. **SKILL.md**: ~300-400 lines. Stages, Pre-Flight Gate, error handling, completion checklist. Template from bulwark-brainstorm SKILL.md (391 lines) — adapt, do not reinvent.

2. **4 specialization reference files** in `references/`:
   - `specialize-code-review.md` — instructs Analyzer on what to extract for code-review skill improvements (new security patterns, framework pattern gaps, review lens updates)
   - `specialize-test-audit.md` — instructs Analyzer on test-audit improvements (mock detection gaps, assertion pattern additions, AST script coverage)
   - `specialize-bug-magnet-data.md` — instructs Analyzer on edge case data improvements (new categories from bugs encountered)
   - `specialize-general.md` — instructs Analyzer on general skill improvements (pattern extraction, instruction hardening based on observed failures like DEF-P4-005)

3. **3 output template files** in `templates/`:
   - `collect-output.md` — normalized learning item format (source, category, content, relevance score)
   - `proposal-output.md` — change proposal format with target file, change type, before/after, rationale
   - `diagnostic-output.yaml` — standard diagnostic schema (copy from bulwark-research, adapt fields)

4. **Collector agent prompt content**: Instructions for parsing session handoff sections and MEMORY.md sections. This is the simplest agent — it reads files and normalizes.

5. **Proposer agent prompt content**: Instructions for turning analysis findings into concrete change proposals. This is the hardest agent — it must produce specific, applicable modifications.

### Effort Estimation

**Total: 1 session (estimated 35-50K tokens)**

| Deliverable | Complexity | Estimated Effort |
|-------------|-----------|------------------|
| SKILL.md (stages, gates, checklist) | Medium | 30% — adapt from bulwark-brainstorm, most structure is boilerplate |
| 4 specialization references | Medium | 25% — requires domain knowledge encoding, but scope is bounded |
| 3 output templates | Low | 10% — structural templates with field definitions |
| Collector agent prompt | Low | 5% — straightforward file parsing instructions |
| Analyzer agent prompts | Medium | 15% — per-type specialization instructions |
| Proposer agent prompt | High | 15% — must produce concrete, diff-level proposals |

**Why 1 session is realistic**: The bulwark-brainstorm skill (391 lines of SKILL.md, 5 reference files, 4 templates) was implemented in Session 59 alongside bulwark-research. Continuous-feedback is structurally simpler (4 agents vs 5, Sonnet vs Opus, no Critical Evaluation Gate needed). The reference files are shorter — each specialization doc is ~50-80 lines of focused instructions, not the ~60-line role definitions used in brainstorm.

**Risk to estimate**: The Proposer agent's prompt is the variable. If the proposal output format is too ambitious (full diffs with line numbers), prompt engineering will consume time. Keep the proposal format at the "target file + section + change description + example" level, not literal diffs.

### Implementation Risks

**Risk 1 (High): Proposal quality is too vague to be actionable**

The Act stage must produce proposals that a developer can actually apply. "Improve the security patterns in code-review" is useless. "Add SSRF detection pattern to `references/security-patterns.md` with the following content: [specific content]" is useful. The Proposer agent must receive enough context from the Analyze stage to generate specific content, not just categories.

*Mitigation*: The `proposal-output.md` template must enforce specificity. Include mandatory fields: `target_file`, `change_type` (add/modify/remove), `location` (section or line range), `proposed_content` (the actual text to add/change), `rationale` (which learning item drives this). The Proposer agent prompt must include examples of good vs. bad proposals.

**Risk 2 (Medium): Collector agent token overflow on 62+ session files**

Reading all 62 session handoffs in a single Sonnet agent context will consume significant tokens. Each session handoff is ~100-200 lines. 62 files = 6,200-12,400 lines of input.

*Mitigation*: The Collector agent does NOT read all sessions. It uses Glob to find session files, then reads only the Learnings, Technical Decisions, and Blockers sections from each (not full files). Instruct the agent to use Grep to find section headers and Read with line offsets. Alternatively, accept a `--since <session_number>` argument to limit scope. Default to last 10 sessions.

**Risk 3 (Medium): Per-skill-type detection is fragile**

The Analyze stage must determine which skill types are relevant based on collected learnings. If a learning mentions "mock detection pattern," it routes to the test-audit Analyzer. This routing logic lives in the orchestrator, not a sub-agent.

*Mitigation*: Use keyword-based routing in the orchestrator: if collected learnings mention test-audit/mock/assertion/AST patterns, spawn test-audit Analyzer. If they mention security/review/lint patterns, spawn code-review Analyzer. If they mention edge case/boundary/bug-magnet patterns, spawn bug-magnet Analyzer. Always spawn the general Analyzer. This is deterministic routing, not LLM classification — reducing variance.

**Risk 4 (Low): General-purpose portability assumption is untested**

The skill is designed for "any Claude Code project," but the specialization references are Bulwark-specific (code-review, test-audit, bug-magnet-data). Other projects will not have these skills.

*Mitigation*: The general Analyzer handles any project. The specialized Analyzers are conditional — only spawned when the target project contains the corresponding skills (detected via Glob for `.claude/skills/code-review/`, etc.). If no specialized skills are found, only the general Analyzer runs. Document this in SKILL.md.

### Testing Strategy

**Manual testing is the only viable strategy for this skill.** LLM-based pipeline skills cannot be meaningfully unit-tested — the output depends on sub-agent behavior, which is stochastic. This is consistent with how bulwark-research and bulwark-brainstorm are tested (manual protocol, user-reported results).

**Test Protocol (to be executed in a dedicated test session):**

1. **Collect stage verification**: Run continuous-feedback on Bulwark's own sessions. Verify the Collector agent produces a normalized learning list with source attribution. Check that it extracts from both session handoffs and MEMORY.md. Verify it respects `--since` filtering.

2. **Analyze stage verification**: Verify that per-skill-type Analyzers are spawned only when relevant skills exist in the target project. Verify the general Analyzer always runs. Check that analysis findings reference specific learning items by source.

3. **Act stage verification**: Verify the Proposer agent produces proposals with all mandatory fields (target_file, change_type, location, proposed_content, rationale). Verify proposals are specific enough to apply without interpretation. Verify the proposal document format matches the template.

4. **Validate stage verification**: Run `/anthropic-validator` on the continuous-feedback skill itself. Verify it passes with 0 critical, 0 high.

5. **Portability test**: Run on a non-Bulwark project (e.g., smart-todo test project used in Session 60). Verify only the general Analyzer runs. Verify no Bulwark-specific assumptions cause failures.

**Test fixtures needed**: None beyond existing session handoffs and MEMORY.md. The 62 existing session files are the fixture.

### Build Order and Dependencies

**Critical path**: SKILL.md depends on templates (referenced in stage definitions). Templates depend on understanding the proposal format (which drives the Proposer prompt). Build bottom-up.

**Step 1: Templates (10 minutes)**
- Create `templates/collect-output.md` — normalized learning item schema
- Create `templates/proposal-output.md` — change proposal schema with mandatory fields
- Create `templates/diagnostic-output.yaml` — copy from bulwark-research, adapt field names

**Step 2: Specialization References (20 minutes)**
- Create `references/specialize-code-review.md`
- Create `references/specialize-test-audit.md`
- Create `references/specialize-bug-magnet-data.md`
- Create `references/specialize-general.md`
- Each file: 50-80 lines defining what the Analyzer should look for and how to categorize findings

**Step 3: SKILL.md (30 minutes)**
- Pre-Flight Gate (from test-audit pattern)
- Stage 1: Collect — Sonnet agent, reads sessions + MEMORY.md + custom paths
- Stage 2: Analyze — 1-4 Sonnet agents in parallel (conditional on detected skill types)
- Stage 3: Act — Sonnet agent, produces proposal document from analysis
- Stage 4: Validate — Orchestrator runs anthropic-validator + quality gates (no sub-agent)
- Stage 5: Diagnostics — YAML output
- Error handling table, token budget management, completion checklist
- Frontmatter: `name: continuous-feedback`, `user-invocable: true`, `skills: [subagent-prompting]`

**Step 4: Sync and Validate (10 minutes)**
- Copy to `.claude/skills/continuous-feedback/` (dogfood)
- Run `/anthropic-validator` on the skill
- Rsync to standalone repo

**Dependencies:**
- `subagent-prompting` skill: EXISTS, no changes needed
- `anthropic-validator` skill: EXISTS, no changes needed
- Session handoffs: EXISTS (62 files), no changes needed
- MEMORY.md: EXISTS, no changes needed
- No blocking dependencies on other incomplete tasks

## Recommendation

**Proceed.** The continuous-feedback skill is implementable in 1 session with no new infrastructure. The pipeline shape (Collect -> parallel Analyze -> Act -> Validate) maps directly onto the proven bulwark-brainstorm pattern. All dependencies exist. The primary risk is Act stage proposal quality — mitigate by enforcing a specific proposal template with mandatory fields and examples of good/bad proposals. Do not attempt literal diff generation; keep proposals at the "target file + section + proposed content" level. Start with templates (Step 1), then references (Step 2), then SKILL.md (Step 3), then validate (Step 4). The `--since` argument for session filtering is essential for token management and should be in the v1 scope, not deferred.
