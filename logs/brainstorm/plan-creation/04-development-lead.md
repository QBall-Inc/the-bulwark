---
role: development-lead
topic: "P5.13 Plan-Creation Skill — Agent Teams Dual-Mode"
recommendation: proceed
key_findings:
  - "3-session build: Session 1 (Task tool mode + scaffolding), Session 2 (Agent Teams mode + integration), Session 3 (manual testing + validation). The tasks.yaml estimate of 2 sessions is underestimated — dual-mode architecture and first-ever Agent Teams integration add a full session."
  - "80% of scaffolding is copy-adapt from bulwark-brainstorm — SKILL.md structure, references/, templates/, diagnostic YAML, SA2 compliance, error handling, token budget management, pre-flight interview, Critical Evaluation Gate. The remaining 20% is genuinely new: Agent Teams orchestration, env var gating, dual-mode synthesis, and scrum team role definitions."
  - "Agent Teams mode is the highest-risk component because it has zero precedent in Bulwark. De-risk by building Task tool mode first (Session 1), which provides a working baseline. Agent Teams mode layers on top (Session 2) without altering the Task tool path."
  - "Testing is exclusively manual protocol — no automated tests are possible for multi-agent orchestration skills. Build a manual test protocol modeled on tests/manual-test-protocol-P5.10-12.md with separate sections for Task tool mode and Agent Teams mode."
---

# P5.13 Plan-Creation Skill — Senior Development Lead

## Summary

The plan-creation skill is buildable in 3 sessions with bulwark-brainstorm as the structural template. The Task tool mode reuses 80% of brainstorm's patterns, making Session 1 low-risk. Agent Teams mode (Session 2) is the genuinely novel work and the highest-risk component, but its risk is bounded because the Task tool mode provides a working fallback. The estimated 2 sessions in tasks.yaml should be revised to 3.

## Detailed Analysis

### Implementation Feasibility

The skill is feasible with available tools. Here is the evidence:

**Available infrastructure (verified in codebase):**

1. **bulwark-brainstorm** (`/mnt/c/projects/the-bulwark/.claude/skills/bulwark-brainstorm/SKILL.md`) provides the complete structural template: 6-stage execution flow (Pre-Flight, SME, Role Analysis, Critic, Synthesis, Diagnostics), F# pipe syntax, 4-part prompting via `subagent-prompting` dependency, SA2 compliance patterns, token budget management with 4 checkpoints, error handling with single-retry, Critical Evaluation Gate with classification taxonomy, AskUserQuestion protocol, and diagnostic YAML output.

2. **subagent-prompting skill** (`/mnt/c/projects/the-bulwark/.claude/skills/subagent-prompting/SKILL.md`) provides the 4-part GOAL/CONSTRAINTS/CONTEXT/OUTPUT template — already a declared dependency.

3. **pipeline-templates** (`/mnt/c/projects/the-bulwark/.claude/skills/pipeline-templates/references/research-planning.md`) has an existing Research & Planning pipeline that defines a Researcher-PlanDrafter-PlanReviewer loop. The plan-creation skill replaces this with the 5-role scrum team approach, which is more sophisticated but architecturally aligned.

4. **sync script** (`/mnt/c/projects/the-bulwark/scripts/sync-essential-skills.sh`) already handles bulwark-prefixed skill rebranding via the `BULWARK_SKILLS` array. Adding `bulwark-plan-creation:plan-creation` (or just `plan-creation` if not prefixed) is a one-line addition.

**What does NOT exist and must be built from scratch:**

1. Agent Teams orchestration code — no Bulwark skill has ever used Agent Teams. The delegate mode, teammate spawning, mailbox messaging, and shared task list patterns have no existing implementation to copy from.

2. Dual-mode branching logic — detecting `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in pre-flight and switching execution flows. This is a new pattern for Bulwark skills.

3. Five scrum team role definitions — Product Owner, Technical Architect, Engineering Lead, Delivery Lead, QA/Critic. These are distinct from brainstorm's 5 roles (SME, PM, Architect, Dev Lead, Critical Analyst) and must be written fresh. Each needs a `references/role-*.md` file.

4. Plan output templates — the output is an implementation plan (phases, workpackages, milestones, dependencies), not a brainstorm synthesis. New templates are required.

### Effort Estimation

**Session 1: Task Tool Mode + Scaffolding (1 full session)**

| Work Item | Effort | Notes |
|-----------|--------|-------|
| SKILL.md skeleton | Low | Copy brainstorm structure, adapt stages |
| 5 role reference files | Medium | New content, ~300-500 words each |
| Plan output template | Low | Structured markdown with phases/workpackages |
| Diagnostic YAML template | Low | Copy brainstorm's, adapt agent names |
| Synthesis output template | Low | Adapt brainstorm's for plan format |
| Critic output template | Low | Copy brainstorm's, adapt for plan context |
| Task tool execution flow | Medium | Adapt brainstorm's Stage 2-4 pattern |
| Pre-flight with env var detection | Low | New but simple boolean check |
| SA2 compliance | Low | Same pattern as brainstorm |
| Dogfood copy to .claude/skills/ | Low | rsync command |

**Session 2: Agent Teams Mode + Integration (1 full session)**

| Work Item | Effort | Notes |
|-----------|--------|-------|
| Agent Teams execution flow | HIGH | No existing pattern — first-ever implementation |
| Delegate mode configuration | Medium | Documentation exists but no Bulwark precedent |
| Teammate prompts with dual-output (logs + mailbox) | Medium | SA2 compliance adds complexity |
| Mailbox coordination protocol | Medium | Define message format, summary structure |
| Synthesis from Agent Teams output | Medium | Different from Task tool synthesis — must handle mailbox + logs |
| Graceful degradation logic | Low | Env var missing → fall back to Task tool mode |
| Sync script update | Low | Add skill to BULWARK_SKILLS or SKILLS array |

**Session 3: Testing + Validation (1 session)**

| Work Item | Effort | Notes |
|-----------|--------|-------|
| Manual test protocol | Medium | Model on P5.10-12 protocol format |
| Task tool mode test run | Medium | Full invocation with real topic |
| Agent Teams mode test run | HIGH | Requires env flag, first-ever team run |
| SA2 compliance verification | Low | Check logs/ artifacts exist |
| anthropic-validator run | Low | Must pass with 0 critical, 0 high |
| Fix issues found in testing | Variable | Budget half a session for fixes |

**Total: 3 sessions.** The tasks.yaml estimate of 2 is underestimated. The dual-mode architecture and first-ever Agent Teams integration justify the third session. If Agent Teams mode testing reveals significant issues, a 4th session may be needed, but scope it as a stretch.

### Implementation Risks

Ranked by severity:

**1. Agent Teams API instability (HIGH severity, MEDIUM probability)**

Agent Teams are experimental (require `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`). The API surface — teammate spawning, mailbox messaging, delegate mode, shared task lists — could change between Claude Code versions. The skill's Agent Teams mode may break on updates.

*Mitigation*: Build Task tool mode first as a permanent fallback. Document the specific Claude Code version the Agent Teams mode was tested against. Keep Agent Teams orchestration logic isolated in its own SKILL.md section so updates are localized.

**2. Lead context compaction orphans teammates (HIGH severity, LOW probability)**

Per research synthesis, when the lead's context fills and is summarized, it loses awareness of running teammates. Orphaned processes require manual cleanup from `~/.claude/`.

*Mitigation*: Keep the team to 5 agents (within the 3-4 optimal range per research, but at the upper bound). Include explicit cleanup instructions in the skill's error handling section. Add a "verify all teammates completed" check before synthesis.

**3. SA2 compliance in Agent Teams mode (MEDIUM severity, MEDIUM probability)**

Teammates must write artifacts to `logs/` AND coordinate via mailbox. If a teammate writes findings only to mailbox and skips the log file, SA2 is violated. The dual-output instruction must be in every teammate prompt, and there is no automated enforcement.

*Mitigation*: Include explicit dual-output instructions in every role reference file's prompt template. Add a post-completion check in the synthesis stage: "Before synthesizing, verify that all 5 log files exist at `logs/plan-creation/{slug}/`. If any are missing, the corresponding teammate violated SA2 — note in diagnostics."

**4. Scrum team role overlap (LOW severity, HIGH probability)**

The 5 scrum roles (PO, Architect, Eng Lead, Delivery Lead, QA/Critic) may produce overlapping analysis, especially PO vs Delivery Lead and Architect vs Eng Lead. In brainstorm, the roles are more naturally differentiated (SME explores codebase, PM scopes, Architect designs, Dev Lead estimates, Critic challenges).

*Mitigation*: Write sharp role definitions with explicit "DO NOT cover" boundaries. PO focuses on requirements and acceptance criteria. Delivery Lead focuses on phasing, dependencies, and scheduling. Architect focuses on system design. Eng Lead focuses on effort and implementation risks. QA/Critic focuses on gaps, assumptions, and kill criteria.

**5. Token cost in Agent Teams mode (LOW severity, HIGH probability)**

Research synthesis reports ~2x token cost for Agent Teams vs Task tool. Five teammates at 2x cost means significantly higher consumption per invocation.

*Mitigation*: Warn users in pre-flight when Agent Teams mode is detected. Document expected token cost difference in SKILL.md. Do not attempt to reduce it — accept as the cost of peer debate.

### Testing Strategy

**All testing is manual.** Multi-agent orchestration skills cannot be meaningfully automated — the value is in LLM judgment quality, not deterministic output. Follow the pattern established by existing manual test protocols.

**Task Tool Mode Testing:**

1. Invoke `/plan-creation <topic> --research <synthesis-file>` with Agent Teams flag NOT set
2. Verify pre-flight detects Task tool mode and logs it
3. Verify SME agent spawns first, explores codebase autonomously
4. Verify 3 role agents (PO, Architect, Eng Lead) spawn in parallel
5. Verify Delivery Lead spawns after parallel agents complete
6. Verify QA/Critic spawns last with all prior outputs
7. Verify all 5 output files exist in `logs/plan-creation/{slug}/`
8. Verify synthesis is written using plan output template
9. Verify diagnostic YAML is written
10. Verify plan output contains phases, workpackages, milestones, dependencies

**Agent Teams Mode Testing:**

1. Set `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
2. Invoke `/plan-creation <topic> --research <synthesis-file>`
3. Verify pre-flight detects Agent Teams mode and logs it
4. Verify delegate mode is active (lead does not implement)
5. Verify 5 teammates spawn with correct role assignments
6. Verify peer debate occurs via mailbox (teammates challenge each other)
7. Verify all 5 log files exist in `logs/plan-creation/{slug}/` (SA2)
8. Verify synthesis incorporates both log content and debate insights
9. Verify diagnostic YAML captures Agent Teams-specific metrics
10. Verify cleanup: no orphaned teammate processes after completion

**Cross-Mode Comparison Test (optional, if time permits):**

Run the same topic through both modes. Compare output quality — Agent Teams mode should produce richer plans with cross-challenge evidence. Document token cost difference.

**anthropic-validator:** Run `/anthropic-validator` on the completed skill. Must pass with 0 critical, 0 high findings.

### Dependencies and Build Order

**Critical path:**

```
Session 1: Task Tool Mode (no dependencies beyond brainstorm template)
├── SKILL.md skeleton (copy-adapt from brainstorm)
├── 5 role reference files (write fresh)
├── Plan output template (write fresh)
├── Diagnostic + synthesis + critic templates (adapt from brainstorm)
├── Task tool execution flow (adapt from brainstorm Stages 2-4)
├── Pre-flight with dual-mode detection
└── Dogfood copy to .claude/skills/

Session 2: Agent Teams Mode (depends on Session 1 SKILL.md)
├── Agent Teams execution flow section in SKILL.md
├── Teammate prompt templates with dual-output
├── Mailbox coordination protocol
├── Agent Teams synthesis variant
├── Graceful degradation logic
└── Sync script update

Session 3: Testing + Validation (depends on Session 2)
├── Manual test protocol document
├── Task tool mode full test run
├── Agent Teams mode full test run
├── SA2 compliance verification
├── anthropic-validator pass
└── Fix issues found in testing
```

**Build order rationale:**

1. **Task tool mode first** because it reuses 80% of brainstorm patterns and provides a working fallback. If Session 2 is blocked by Agent Teams instability, the skill still ships with Task tool mode.

2. **Agent Teams mode second** because it layers on top of the SKILL.md created in Session 1. The dual-mode branching is added to the existing pre-flight, and the Agent Teams execution flow is a new section — it does not modify the Task tool path.

3. **Testing last** because both modes must be complete before meaningful testing. Testing cannot be interleaved with implementation because each mode test requires a full skill invocation (spawning 5 agents), which consumes significant context.

**What to build first to de-risk:** Start Session 1 with the role reference files. These are the most uncertain component — if the scrum team roles are poorly defined, both modes will produce low-quality output regardless of orchestration. Get the role definitions right before writing orchestration logic.

**Reuse from brainstorm (verified by line-by-line comparison):**

| Component | Reuse Level | Notes |
|-----------|-------------|-------|
| SKILL.md structure (stages, sections, checklists) | 90% | Rename stages, swap role names |
| Pre-flight stage | 85% | Add env var detection |
| AskUserQuestion protocol | 100% | Identical |
| Critical Evaluation Gate | 100% | Identical |
| Token budget management | 100% | Same thresholds |
| Error handling table | 90% | Add Agent Teams failure modes |
| Diagnostic YAML template | 80% | Add Agent Teams metrics |
| Role reference file format | 70% | Same structure, new content |
| Synthesis template | 50% | Plan format differs from brainstorm format |
| Execution flow | 30% | Task tool similar, Agent Teams entirely new |

## Recommendation

**Proceed.** Revise session estimate from 2 to 3. Build Task tool mode first (Session 1) to establish a working baseline with 80% reuse from brainstorm. Layer Agent Teams mode on top (Session 2) as the genuinely novel work. Dedicate Session 3 to manual testing of both modes. The highest risk is Agent Teams API instability, which is fully mitigated by the Task tool fallback. Start Session 1 with role reference files to de-risk the most uncertain component early.
