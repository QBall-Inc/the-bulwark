---
topic: "P5.15 — Add --exploratory mode to bulwark-brainstorm using Agent Teams peer debate"
phase: brainstorm
agents_synthesized: 5
overall_verdict: modify
verdict_source: critical-analyst
---

# P5.15 — Add --exploratory Mode to bulwark-brainstorm — Brainstorm Synthesis

## Consensus Areas

All 5 roles agree on these foundational points:

| Area | Supporting Roles | Confidence |
|------|-----------------|------------|
| P5.13 must complete first — it validates AT mechanics that --exploratory depends on | All 5 | HIGH |
| Sandwich architecture from P5.13 is the correct pattern: shared Pre-Flight/SME/Synthesis/Diagnostics, mode-specific Stage 3A/3B | All 5 | HIGH |
| SME runs solo via Task tool first (no debate benefit for codebase exploration), identical in both modes | All 5 | HIGH |
| Role consolidation is required: 5 roles → SME solo + 3 AT teammates to stay within 3-4 coordination cap | All 5 | HIGH |
| PM + Dev Lead is the natural merge (both focus on value-effort tradeoffs); Architect and Critic stay distinct | SME, PM, Architect, Dev Lead (Critic does not dispute which roles merge) | HIGH |
| Backward compatibility is non-negotiable: --scoped is default, no-flag = current behavior | All 5 | HIGH |
| SA2 dual-output contract: full analysis → logs/, summary → mailbox (settled from P5.13) | All 5 | HIGH |
| No changes to Critical Evaluation Gate — it uses Task tool for follow-up, not AT | SME, Architect | HIGH |
| Diagnostic YAML extended (not replaced) for AT metrics | SME, Architect, Dev Lead | HIGH |

## Divergence Areas

### Divergence 1: Is the investment justified?

- **PM**: Yes — --exploratory fills a genuine capability gap (idea validation under uncertainty). Prevents wasted implementation sessions. High value per use even if infrequent.
- **Critic**: The gap is real but the frequency is too low. Only 1 proof point (Ralph Loops) across 60+ sessions. A 2-session investment for a once-per-quarter capability is marginal ROI.
- **Decision needed**: Is the triggering frequency sufficient to justify a dedicated mode, or should the gap be addressed with a lighter-weight enhancement (Critic problem-framing challenge)?

### Divergence 2: Session count — 1 or 2?

- **PM**: 1 implementation session (P5.13 de-risks, 80%+ reuse)
- **Dev Lead**: 2 sessions (Session 1 implementation, Session 2 testing). AT prompt engineering is 40% of effort. 30% of Session 2 budgeted for debugging.
- **Critic**: Dev Lead's 2-session estimate is more credible because it accounts for AT debugging unknowns.
- **Decision needed**: Accept Dev Lead's 2-session estimate.

### Divergence 3: Critic role in --exploratory — active participant or enhanced sequential?

- **Architect**: Active AT teammate throughout = "primary quality advantage" of Agent Teams. Critic challenges in real time.
- **Critic**: Active participation means partial information. For idea validation (finding fatal flaws), complete information before judgment is better. The Architect's own mitigation ("withhold verdict until all summaries shared") functionally recreates sequential pattern within AT.
- **Decision needed**: Does the Critic participate as an equal AT teammate from the start, or join late (after other teammates have exchanged initial summaries)?

### Divergence 4: Pre-implementation validation

- **PM, Architect, Dev Lead**: Build it, test after (PM's kill criterion: check after first test run)
- **Critic**: Validate BEFORE building — run bare AT debate test (30 min cost) + historical frequency count. If either fails, don't build.
- **Decision needed**: Should pre-implementation validation gates be added?

### Divergence 5: Combined role naming

- **PM**: "Product & Delivery"
- **Architect**: "Product & Delivery Lead"
- **Dev Lead**: "Product-Implementation Lead"
- **Critic**: Three names = concept not crisp enough to implement yet
- **Decision needed**: Settle on one name before implementation

## Critical Analyst Verdict

**Verdict**: MODIFY (Confidence: medium)
**Conditions**: P5.13 AT debate quality validated, bare AT debate test shows genuine cross-challenge, historical frequency >= 3 instances

The Critic's core challenge: the problem --exploratory solves may be too rare to justify a dedicated mode, and LLM agents may converge rather than genuinely debate. The proposed modification is a phased approach:
1. Immediately: Enhanced Critic mode (add problem-framing challenge to --scoped Critic) — 1 hour
2. After P5.13: Observe AT debate dynamics
3. Before P5.15: Run two pre-implementation validation checks (bare AT test + frequency count)
4. If both pass: Proceed with full --exploratory implementation

The Critic also identifies a simpler alternative: strengthen the --scoped Critic with explicit problem-framing challenge instructions, delivering 60% of the value at 10% of the cost.

## Implementation Outline

### v1 Scope (from PM, adjusted by Critic)

**In v1:**
- `--scoped` / `--exploratory` argument parsing with --scoped as default
- Pre-flight env var detection (P5.13 pattern)
- Stage 3B: SME solo (Task tool) then 3 AT teammates with delegate-mode lead
- Role consolidation: SME + combined PM/DevLead + Architect + Critic
- SA2 dual-output in all teammate prompts
- In-process display mode
- Diagnostic YAML extended with AT metrics
- Updated completion checklist
- 3-location sync

**Deferred:**
- tmux split-pane display mode
- Cross-mode comparison tooling
- Token budget recalibration (use existing with warning)
- Custom team size (`--exploratory --agents N`)

### Architecture (from Architect)

Sandwich structure with Stage 3 fork:
- Stages 1, 2, 5, 6: Shared (unchanged / mode-aware extensions)
- Stage 3A: --scoped (existing Stage 3 + 4, unchanged)
- Stage 3B: --exploratory (AT teammates, delegate mode, dual-output)
- Stage 4: Only executes in --scoped; Critic is AT teammate in --exploratory
- AT failure recovery: fall back to --scoped for unfinished roles

### Build Plan (from Dev Lead)

2 sessions (post P5.13):
1. **Session 1**: Combined role reference → mode detection → Stage 3A/3B split → AT prompts → diagnostics → sync
2. **Session 2**: 6-case manual test protocol → fix issues → anthropic-validator

Start with most uncertain component (combined role reference).

## Risks and Mitigations

| Risk | Source Role | Severity | Mitigation |
|------|-----------|----------|------------|
| Backward compatibility broken | PM | CRITICAL | Sandwich architecture isolates mode-specific logic. Test no-flag path first. |
| --exploratory produces worse output than --scoped | PM, Critic | HIGH | Teammate prompts include explicit challenge instructions. Kill criterion: no cross-challenge = kill mode. |
| AT peer debate converges instead of debates | Critic | HIGH | Pre-implementation bare AT test. P5.13 canary. Enhanced Critic as fallback. |
| Role consolidation dilutes perspectives | Architect, Dev Lead | MEDIUM | Combined reference with explicit sub-sections. Fallback: swap which role merges. |
| AT experimental instability | PM, Architect | MEDIUM | Graceful degradation (env var gating, fallback to --scoped). Mid-run checkpoint. |
| Lead context compaction orphans teammates | Architect | MEDIUM | SME runs before AT (reduces lead context pressure). Document in error handling. |
| Token budget overrun (~2x) | Dev Lead | MEDIUM | User warning at invocation. Adjusted token checkpoints (25%/45%). |
| AT API removed or breaking changes | Critic | LOW-MEDIUM | Only Stage 3B affected. Dead code removal if AT deprecated. |
| Problem recurrence too rare | Critic | MEDIUM | Historical frequency count (Critic's pre-implementation gate). Enhanced Critic as alternative. |

## Open Questions

All resolved via post-synthesis decisions (see below).

## Post-Synthesis Decisions

*User input incorporated after synthesis review. Classifications per Critical Evaluation Gate.*

### Decision 1: Pre-implementation validation approach — P5.13 is sufficient

> **User**: Selected "P5.13 is sufficient validation" — if P5.13's AT mode shows genuine peer debate, skip additional validation and proceed directly to P5.15.

**Classification**: Preference — clear design direction on validation gating.

**Impact**: Overrides Critic's recommendation for separate bare AT debate test and historical frequency count. P5.13 serves as the single canary for AT debate quality. If P5.13's AT mode produces genuine cross-challenge, P5.15 proceeds. If it doesn't, P5.15 is reconsidered. The PM's post-first-run kill criterion is retained as a safety net.

### Decision 2: Critic participates as active AT teammate from start

> **User**: Selected "Active from start" — Critic is a full AT teammate from spawn.

**Classification**: Preference — resolves Divergence 3.

**Impact**: Adopts the Architect's position. The Critic challenges in real time throughout the AT debate, with partial information early. The Architect's prompt mitigation applies: "Do not form a final verdict until all teammates have shared their summaries. Challenge early findings, but reserve your formal verdict for your log artifact." This preserves the Critic's adversarial value (real-time challenge) while mitigating the partial-info risk (deferred verdict).

### Decision 3: Enhanced Critic problem-framing challenge added to --scoped as part of P5.15

> **User**: "Add this as an additional enhancement to --scoped as part of the P5.15 implementation."

**Classification**: Preference — scope addition, bundled with P5.15.

**Impact**: The Critic's role reference (`references/role-critical-analyst.md`) and output template (`templates/critic-output.md`) gain a new "Problem Validation" section: "Should this problem be solved at all? Is the premise valid? What evidence suggests this is worth investing in?" This applies to BOTH modes — the --scoped Critic gets the enhancement too. Addresses the Critic's Alternative 1 as a value-add for all brainstorm runs, not as a replacement for --exploratory. Low effort (~1 hour of prompt editing), high leverage.

### Decision 4: Combined role named "Product & Delivery Lead"

> **User**: Selected "Product & Delivery Lead"

**Classification**: Preference — resolves Divergence 5.

**Impact**: The new combined role reference file is `references/role-product-delivery-lead.md`. Naming aligns with P5.13's "Eng & Delivery Lead" convention (role + function). Settles the naming inconsistency the Critic flagged.
