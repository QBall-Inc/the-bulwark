---
role: development-lead
topic: "P5.15 — Add --exploratory mode to bulwark-brainstorm using Agent Teams peer debate"
recommendation: proceed
key_findings:
  - "P5.15 is feasible within 2 sessions because P5.13's validated sandwich architecture provides 80%+ structural reuse, and the existing SKILL.md is well-modularized with clear stage boundaries for inserting a mode-specific Stage 3B."
  - "The highest-effort component is teammate prompt engineering — each of 3 AT teammates needs a dual-output contract (SA2 logs + mailbox summary), peer challenge directives, and role-output template compliance. Budget 40% of Session 1 for this."
  - "Role consolidation from 5 to 4 (SME solo + 3 AT teammates) requires merging PM and Dev Lead into a combined Product-Implementation Lead. Architect and Critic stay separate. New combined role reference file needed."
  - "No automated testing is possible for LLM brainstorm output. Manual test protocol with side-by-side --scoped vs --exploratory comparison is the verification method. This is consistent with P5.14's verification approach."
  - "The riskiest build step is Agent Teams teammate spawning mechanics — P5.13 will have exercised this first, so P5.15 inherits validated patterns. If P5.13 encounters AT issues, P5.15 risk increases."
---

# P5.15 — Add --exploratory Mode to bulwark-brainstorm — Senior Development Lead

## Summary

P5.15 is buildable in 2 sessions with medium-low risk, provided P5.13 implementation completes first and validates the Agent Teams integration patterns. The existing bulwark-brainstorm SKILL.md (`/mnt/c/projects/the-bulwark/skills/bulwark-brainstorm/SKILL.md`, 391 lines) is well-modularized: Pre-Flight (Stage 1), Synthesis (Stage 5), and Diagnostics (Stage 6) need only mode-aware extensions, while the core change is inserting a new Stage 3B alongside the existing Stage 3 for AT peer debate. The P5.13 task brief (`/mnt/c/projects/the-bulwark/plans/task-briefs/P5.13-plan-creation.md`, lines 140-182) provides the exact sandwich architecture template. Total new content is approximately 150-200 lines of SKILL.md additions plus one new role reference file.

## Detailed Analysis

### 1. Implementation Feasibility

P5.15 can be built with the tools and patterns already available in this project. Every required capability exists:

**SKILL.md modification**: The current SKILL.md has clean stage boundaries (Pre-Flight at line 75, Stage 2 at line 101, Stage 3 at line 128, Stage 4 at line 149, Stage 5 at line 170, Stage 6 at line 229). Insert a Stage 3B section between Stage 3 (rename to Stage 3A) and Stage 4. The synthesis stage (Stage 5) already reads "ALL 5 agent output files" — extend this to be mode-aware (read 4 files in --exploratory mode: SME + 3 AT teammate outputs).

**Mode detection**: Reuse P5.13's env var check pattern verbatim. Check `$CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` in Pre-Flight. Add `--scoped` and `--exploratory` flags to argument parsing (line 56-58 of current SKILL.md). Default to `--scoped` when no flag is provided — this preserves backward compatibility.

**Agent Teams spawning**: Claude Code's Agent Teams API uses the same Task tool interface with additional parameters for teammate configuration. P5.13 will validate the exact spawning mechanics (delegate mode, in-process display, mailbox messaging) before P5.15 begins. Reuse the validated pattern.

**SA2 dual-output contract**: Each AT teammate prompt includes explicit instructions to (1) write full analysis to `logs/brainstorm/{topic-slug}/{NN}-{role}.md` and (2) send a 3-5 sentence coordination summary to the mailbox. This is prompt engineering, not architecture — no new infrastructure needed.

**Role reference files**: The existing 5 references at `/mnt/c/projects/the-bulwark/skills/bulwark-brainstorm/references/` remain unchanged for --scoped mode. Create one new file `references/role-product-implementation-lead.md` for the merged PM+DevLead AT teammate. The existing Architect and Critic references can be reused with minor prompt additions (peer challenge instructions appended for AT mode).

**Sync mechanics**: The rsync script at `/mnt/c/projects/the-bulwark/scripts/sync-essential-skills.sh` (line 88) maps `bulwark-brainstorm:brainstorm` at the directory level. New files added to the skill directory (e.g., the combined role reference) sync automatically. No script modification needed.

### 2. Effort Estimation

**Session 1 (Implementation — 60-70% of total effort):**

| Work Item | Effort | Risk |
|-----------|--------|------|
| Add mode detection to Pre-Flight (Stage 1) | 10% | Low — copy from P5.13 |
| Add argument parsing (--scoped/--exploratory flags) | 5% | Low — extend existing argument block |
| Rename Stage 3 to Stage 3A, add conditional routing | 10% | Low — structural edit |
| Write Stage 3B (AT execution flow) | 20% | Medium — first AT usage in brainstorm context |
| Create `references/role-product-implementation-lead.md` | 10% | Medium — role consolidation content |
| Add AT peer challenge instructions to Architect and Critic reference prompts (AT-specific addendum, not modifying --scoped prompts) | 15% | Medium — prompt engineering |
| Extend diagnostic template with AT metrics | 5% | Low — add fields to existing YAML |
| Update synthesis template for mode-awareness | 5% | Low — add debate-insights section |
| Update completion checklist for AT items | 5% | Low — append items |
| Sync to `.claude/skills/bulwark-brainstorm/` | 5% | Low — file copy |
| Update frontmatter description | 2% | Low |

**Session 2 (Testing + Validation — 30-40% of total effort):**

| Work Item | Effort | Risk |
|-----------|--------|------|
| Manual test: --scoped regression (unchanged behavior) | 15% | Low |
| Manual test: --exploratory with AT env var | 25% | Medium — first AT brainstorm run |
| Manual test: graceful degradation (no env var + --exploratory) | 10% | Low |
| Run `/anthropic-validator` | 10% | Low |
| Fix issues found during testing | 30% | Medium — AT debugging unknown |
| Update manual test protocol | 10% | Low |

**Total: 2 sessions.** This matches the `tasks.yaml` estimate (line 247). The estimate is realistic because: (a) P5.13 validates AT patterns first, eliminating the "first-ever AT" risk from P5.15; (b) 80%+ of SKILL.md structure is reuse; (c) the only novel component is the combined role reference file.

### 3. Implementation Risks

**Risk 1 — Role consolidation dilutes quality (Medium probability, Medium impact):**
Merging PM and Dev Lead into Product-Implementation Lead could produce a less focused analysis than two separate agents. Mitigation: Write the combined role reference with explicit sub-sections (Scope & Value from PM perspective, Feasibility & Effort from Dev Lead perspective) so the agent addresses both concern areas. If testing shows quality loss, split back to 4 roles and drop the Architect (the narrowest contributor in brainstorm context) instead.

**Risk 2 — AT teammate coordination failures (Low probability if P5.13 succeeds, High impact):**
If Agent Teams mailbox messaging is unreliable, teammates cannot challenge each other — eliminating the entire value proposition of --exploratory. Mitigation: P5.13 validates AT mechanics first. If P5.13 encounters systematic AT failures, defer P5.15 until AT stabilizes (kill criterion from research synthesis).

**Risk 3 — Token budget overrun in --exploratory mode (Medium probability, Medium impact):**
AT mode costs ~2x per research. The existing token budget thresholds (30% pre-spawn, 55% checkpoint, 65% post-synthesis) were calibrated for Task tool mode. With AT, the 55% checkpoint may be hit before debate completes. Mitigation: Add an AT-specific token warning in Pre-Flight: "Agent Teams mode consumes approximately 2x the token budget of --scoped mode. Ensure sufficient context remaining." Adjust the checkpoint threshold for AT mode to 45% (earlier warning).

**Risk 4 — Synthesis template incompatibility (Low probability, Low impact):**
The current `templates/synthesis-output.md` references "SME, PM, Architect, Dev Lead, Critic" by name. In --exploratory mode, the roles differ (SME, Product-Implementation Lead, Architect, Critic). Mitigation: Make the synthesis template role-generic: reference "all agent outputs" rather than listing specific role names. The YAML header's `agents_synthesized` count is already a number, not a name list.

### 4. Testing Strategy

**No automated tests are possible.** LLM brainstorm output varies by run. Manual testing is the only verification method, consistent with all existing brainstorm/research skills in this project (P5.14 used the same approach).

**Manual test protocol (6 test cases):**

1. **Regression — --scoped default**: `/bulwark-brainstorm "test topic"` with no mode flag. Verify identical behavior to current skill (5 sequential agents, same output files, same synthesis structure).

2. **Regression — --scoped explicit**: `/bulwark-brainstorm --scoped "test topic"`. Verify identical to test 1.

3. **Exploratory with AT**: Set `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, run `/bulwark-brainstorm --exploratory "test topic"`. Verify: (a) SME runs solo first, (b) 3 AT teammates spawn with delegate-mode lead, (c) peer challenge messages visible in mailbox, (d) all 4 SA2-compliant log files written, (e) synthesis reflects debate dynamics.

4. **Graceful degradation**: Unset env var, run `/bulwark-brainstorm --exploratory "test topic"`. Verify user notification and automatic fallback to --scoped mode.

5. **Side-by-side comparison**: Same topic through both modes. Compare output structure (debate-driven vs sequential), log file contents, and token consumption.

6. **Anthropic validator**: Run `/anthropic-validator` on the updated SKILL.md. Target: 0 critical, 0 high findings.

### 5. Dependencies and Ordering

**Hard dependency — P5.13 implementation (Sessions 67-69):**
P5.13 must complete before P5.15 begins. P5.13 validates: (a) Agent Teams spawning mechanics, (b) delegate mode behavior, (c) SA2 dual-output contract in practice, (d) in-process display mode on WSL2, (e) graceful degradation when env var is absent. If P5.13 encounters systematic AT issues, those must be resolved before P5.15 proceeds.

**Soft dependency — P5.14 (completed):**
Already done. Provides the base bulwark-brainstorm skill that P5.15 extends.

**No dependency on P5.3, P5.4, or P5.5:**
These are parallel evolution tools with no code overlap.

**Build order within P5.15:**

| Step | What | Why First |
|------|------|-----------|
| 1 | Create `references/role-product-implementation-lead.md` | Most uncertain component — validates role consolidation approach early |
| 2 | Add mode detection + argument parsing to Pre-Flight (Stage 1) | Foundation for all subsequent mode-specific logic |
| 3 | Rename Stage 3 to Stage 3A, add Stage 3B skeleton | Structural scaffolding |
| 4 | Write AT teammate prompt blocks in Stage 3B | Core new functionality — includes SA2 dual-output, peer challenge directives |
| 5 | Add AT peer challenge addenda to Architect and Critic references | Augment existing references for AT context without modifying --scoped behavior |
| 6 | Extend diagnostic template with AT fields | Small, mechanical change |
| 7 | Update synthesis template for mode-awareness | Small, make role references generic |
| 8 | Update completion checklist | Append AT-specific verification items |
| 9 | Sync to `.claude/skills/bulwark-brainstorm/` | File copy |
| 10 | Manual testing (Session 2) | Verification |

Start with step 1 (role reference file) because it is the most uncertain component. If the combined role produces unsatisfactory results during testing, the reference file is the only artifact that needs rework — the SKILL.md structural changes are role-agnostic.

## Recommendation

**Proceed** with P5.15 implementation in 2 sessions (estimated Sessions 70-71, after P5.13 completes in Sessions 67-69). The implementation is feasible, effort is well-bounded, and P5.13 de-risks the Agent Teams integration mechanics. The primary risk — role consolidation quality — is addressable through careful prompt engineering and has a clear fallback (swap which role gets merged).

**Condition**: If P5.13 encounters systematic Agent Teams failures that require workarounds or framework bug reports, re-evaluate P5.15 effort estimate. The 2-session budget assumes AT mechanics work as documented.
