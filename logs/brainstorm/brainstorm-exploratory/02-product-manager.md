---
role: product-manager
topic: "P5.15 — Add --exploratory mode to bulwark-brainstorm using Agent Teams peer debate"
recommendation: proceed
key_findings:
  - "--exploratory serves a distinct user need (idea validation under uncertainty) that --scoped cannot address — this is net-new capability, not a marginal improvement to existing functionality"
  - "The user base is narrow (Bulwark/Essential Skills power users running brainstorm sessions) but the value per use is high — preventing investment in ideas that lack merit saves entire implementation sessions"
  - "v1 scope must be ruthlessly bounded: SME solo + 3 AT teammates debating + synthesis. No new role references, no new templates beyond AT-specific diagnostics, no Critical Evaluation Gate changes"
  - "P5.13 plan-creation must ship first — it is both the architectural proving ground and the dependency that de-risks --exploratory implementation from 2 sessions to 1"
  - "Kill criteria must be measurable at the end of the first test run: if peer debate produces no observable cross-challenge between teammates, the mode adds cost without differentiation"
---

# P5.15 — Add --exploratory Mode to bulwark-brainstorm — Senior Product Manager

## Summary

The --exploratory mode addresses a genuine gap in the brainstorm skill's capability: the current --scoped mode excels at structured analysis of well-defined problems but offers no mechanism for collaborative idea validation when the problem framing itself is uncertain. Agent Teams peer debate fills this gap by enabling real-time cross-challenge between personas, preventing premature anchoring on untested assumptions. The feature should proceed, scoped tightly to the sandwich architecture pattern from P5.13, with P5.13 implementation as a hard prerequisite.

## Detailed Analysis

### 1. User Value Proposition — Who Benefits and How?

**Primary beneficiary**: The developer-operator who invokes `/bulwark-brainstorm` to evaluate whether a capability is worth building. Today, this user has one mode: sequential expert opinions on a well-framed topic. When the topic itself is uncertain — "Should we even build this? Is the problem real?" — the sequential mode produces 5 independent assessments that each treat the premise as given, rather than challenging whether the premise holds.

**The value gap is real and observable**. Across 6+ brainstorm sessions (Sessions 59, 60, 63, 64, 65, and the current session), every invocation has been --scoped: the problem statement was pre-defined, research was completed, and the brainstorm was focused on "how to implement." None of these sessions needed --exploratory because the problem framing was settled before brainstorming began. But the research phase (Session 62) identified the need explicitly: when evaluating Agent Teams applicability, the question was not "how do we implement Agent Teams?" but "does Agent Teams even make sense for Bulwark?" That is an --exploratory question.

**Concrete value delivery**:
- **Prevents wasted implementation sessions**: A single --exploratory run that exposes fatal flaws in an idea saves 1-3 implementation sessions (15-60K tokens each). The Ralph Loops descoping decision (Sessions 61-62) is the proof point — two research sessions established near-zero applicability. An --exploratory brainstorm could have surfaced this faster through adversarial debate.
- **Produces higher-confidence go/no-go decisions**: When personas actively challenge each other's positions in real time (via mailbox), the synthesis captures genuine tensions rather than independently generated opinions that may converge on the same blind spot.
- **Fills the workflow gap between research and scoped brainstorm**: The current pipeline is `/bulwark-research` (gather facts) then `/bulwark-brainstorm --scoped` (plan implementation). There is no step for "validate whether this idea deserves implementation planning." --exploratory occupies that middle ground.

**Who does NOT benefit**: Users with well-defined implementation problems. If the problem statement is clear, --scoped remains the correct tool. The skill's argument-hint and usage docs must make this distinction unmissable.

### 2. Prioritization — What Delivers the Most Value Soonest?

Ranked by value-to-effort ratio:

**Priority 1: Sandwich architecture integration (Pre-Flight mode detection + Stage 3B AT flow)**
- User value: Enables the entire --exploratory capability
- Who benefits: Every user who invokes --exploratory
- Effort: Low-medium — P5.13 will have proven the pattern; this is adaptation, not invention
- Cost of delay: Blocks all other --exploratory work
- Verdict: Build first. This is the load-bearing wall.

**Priority 2: Role consolidation from 5 to SME + 3 AT teammates**
- User value: Prevents coordination breakdown that would make --exploratory worse than --scoped
- Who benefits: Output quality — without consolidation, 5 AT teammates exceed the 3-4 coordination cap and produce noise, not debate
- Effort: Medium — must decide which roles merge without losing distinct perspectives
- Cost of delay: If deferred, --exploratory ships with degraded quality and damages user trust in the mode
- Verdict: Build as part of Priority 1. The role mapping is a design decision, not a separate work item. Use the P5.13 pattern: SME solo first (Task tool), then 3 AT teammates. The natural consolidation is PM + Dev Lead into a single "Product & Delivery" teammate (their focus areas overlap on feasibility, scope, and effort), keeping Architect and Critic as distinct teammates. This preserves the Critic's adversarial role — the primary quality differentiator of Agent Teams mode.

**Priority 3: SA2 dual-output contract in teammate prompts**
- User value: Ensures log artifacts exist for post-session review and audit trail
- Who benefits: The user reviewing brainstorm outputs after the session, and any downstream skill that consumes brainstorm logs
- Effort: Low — prompt engineering only, pattern proven in P5.13
- Cost of delay: If deferred, mailbox becomes the only record of debate, violating SA2 and losing the audit trail
- Verdict: Build as part of Priority 1. Non-negotiable per settled decisions.

**Priority 4: Diagnostic YAML extension for AT metrics**
- User value: Enables comparison between --scoped and --exploratory runs on the same topic
- Who benefits: The operator evaluating whether --exploratory justified its 2x token cost
- Effort: Low — extend existing template with 4-5 new fields
- Cost of delay: Low — diagnostics are observability, not functionality. Can ship in v1.1.
- Verdict: Include in v1 because effort is trivial. But if session time runs short, this is the first item to defer.

**Recheck — challenging my own prioritization**:
- "If I'm wrong about the user value of Priority 1 (sandwich architecture), how does the ranking change?" If the sandwich pattern does not transfer cleanly from P5.13, Priority 1 becomes Priority 0 (research/prototype) and the entire feature slips a session. This is mitigated by building P5.13 first — it validates the pattern.
- "What user segment am I underweighting?" Users of the Essential Skills standalone repo who do not have Bulwark context. For them, --exploratory is a novel capability with no prior sequential mode to compare against. The usage guidance must be self-explanatory without Bulwark history.
- "Are my scope boundaries driven by actual constraints or assumptions?" The 3-4 agent cap is research-backed (all 5 viewpoints, HIGH confidence). The 2x token cost is empirical. The role consolidation to 4 is a constraint, not an assumption. The one assumption I am making is that P5.13 will ship before P5.15 — if P5.13 is delayed, --exploratory loses its architectural proving ground and should be deferred.

### 3. Scope Boundaries — What Is v1 vs. Deferred?

**v1 (this implementation, targeting 1-2 sessions):**

| Deliverable | Rationale |
|-------------|-----------|
| `--scoped` / `--exploratory` argument parsing with --scoped as default | Backward compatibility is non-negotiable |
| Pre-flight env var detection (identical to P5.13 pattern) | Graceful degradation when Agent Teams unavailable |
| Stage 3B: SME solo (Task tool) then 3 AT teammates with delegate-mode lead | Matches proven P5.13 architecture |
| Role consolidation: SME (solo) + Product & Delivery + Architect + Critic (AT teammates) | Stays within 3-4 coordination cap |
| SA2 dual-output in all teammate prompts | Settled decision, non-negotiable |
| In-process display mode hardcoded | WSL2 safe default, settled decision |
| Diagnostic YAML extended with AT metrics | Low effort, high observability value |
| Updated completion checklist for --exploratory | Ensures no steps skipped |
| Sync to `.claude/skills/bulwark-brainstorm/` and Essential Skills repo | 3-location sync requirement from SME analysis |

**Deferred (v1.1 or later):**

| Item | Reason for Deferral |
|------|---------------------|
| tmux split-pane display mode option | In-process is sufficient for v1; tmux adds WSL2 complexity |
| Separate role reference files for consolidated roles | v1 reuses existing references with mode-specific prompt sections; dedicated files are a polish item |
| Cross-mode comparison tooling (run same topic through both modes, diff output) | Valuable but not essential for initial validation |
| Token budget recalibration for 2x AT cost | Use existing thresholds with a user warning; tune after empirical data from real runs |
| --exploratory with custom team size (e.g., `--exploratory --agents 2`) | Over-engineering for v1; fixed at 3 teammates |

**Explicitly out of scope (do not build):**

| Item | Reason |
|------|--------|
| Migration of --scoped to Agent Teams | Research consensus: sequential mode works correctly with Task tool |
| Changes to Critical Evaluation Gate | Gate spawns follow-up agents via Task tool, not AT; no change needed |
| New synthesis template for --exploratory | Existing template handles both sequential and debate-driven inputs with mode-aware sections |
| Agent Teams for bulwark-research | Research skill's independent viewpoints are intentional; peer messaging would introduce anchoring bias |

### 4. Success Criteria — How Do We Know This Works?

**Functional success (must-pass):**

1. `/bulwark-brainstorm <topic>` with no mode flag produces identical output to current behavior (backward compatibility)
2. `/bulwark-brainstorm --scoped <topic>` produces identical output to current behavior (explicit scoped)
3. `/bulwark-brainstorm --exploratory <topic>` spawns SME solo, then 3 AT teammates in delegate mode
4. AT teammates produce observable cross-challenge in their outputs — at least one teammate explicitly references and disputes another teammate's position
5. All 4 SA2-compliant log files exist in `logs/brainstorm/{topic-slug}/` after --exploratory run
6. Graceful degradation: --exploratory without env var notifies user and falls back to --scoped
7. Passes `/anthropic-validator` with 0 critical, 0 high

**Quality success (should-pass):**

8. --exploratory synthesis identifies at least one risk or objection not present in a --scoped run on the same topic
9. Diagnostic YAML captures AT-specific metrics (teammate_count, display_mode, peer_challenges_observed)
10. Token cost for --exploratory is within 1.5-2.5x of --scoped (confirming research estimates)

**Adoption success (measured over 3+ sessions):**

11. --exploratory is invoked at least once per 3 brainstorm sessions where the problem framing is uncertain
12. No user reverts from --exploratory to --scoped mid-session due to quality or reliability issues

### 5. Risk to User Experience if Implemented Poorly

**Risk 1: --exploratory produces worse output than --scoped (SEVERITY: HIGH)**
If peer debate devolves into agreement or tangential discussion rather than genuine adversarial challenge, the user gets 2x token cost with lower quality output. The sequential --scoped mode, where the Critic reviews all prior work, may produce more structured analysis than freeform debate. Mitigation: teammate prompts must include explicit challenge instructions ("Before agreeing with any teammate, identify the weakest assumption in their position and challenge it"). Kill criterion: if first test run shows no cross-challenge, kill the mode.

**Risk 2: Backward compatibility broken (SEVERITY: CRITICAL)**
If adding --exploratory introduces any regression in the default (no-flag) behavior, every existing brainstorm workflow breaks. This is the highest-stakes risk. Mitigation: the sandwich architecture isolates mode-specific logic to Stage 3A/3B. Pre-flight and synthesis stages are shared. Test the no-flag path first before testing --exploratory.

**Risk 3: AT experimental instability disrupts the session (SEVERITY: MEDIUM)**
Known issues: session resumption broken for in-process mode, lead context compaction orphans teammates. If an --exploratory run fails mid-debate, the user has no output and has consumed significant tokens. Mitigation: graceful degradation is already designed (env var gating, fallback to --scoped). Add a mid-run checkpoint: if AT team fails to produce any log file within a reasonable timeframe, abort AT and fall back to --scoped with a user notification.

**Risk 4: Role consolidation dilutes perspectives (SEVERITY: MEDIUM)**
Merging 5 roles into 4 (SME + 3 AT teammates) means one combined role covers two previous perspectives. If the consolidation is wrong — e.g., merging Architect + Dev Lead loses the distinction between "what should we build" and "can we build it" — output quality degrades. Mitigation: follow the P5.13 pattern (PO + Architect + Eng+Delivery Lead + QA/Critic). For brainstorm, the natural merge is PM + Dev Lead into "Product & Delivery" because both focus on value-effort tradeoffs, while Architect and Critic have sharply distinct functions.

**Risk 5: 3-location sync forgotten (SEVERITY: LOW but persistent)**
The skill exists in `skills/`, `.claude/skills/`, and the Essential Skills repo. Adding --exploratory to one location without syncing to the others creates drift. Mitigation: the sync script (`scripts/sync-essential-skills.sh`) already handles the full directory rsync with the `bulwark-brainstorm:brainstorm` rename. The `.claude/skills/` copy must be manually updated — add this to the completion checklist.

## Recommendation

**Proceed with --exploratory mode implementation**, bounded by these conditions:

1. **Hard prerequisite**: P5.13 plan-creation must be implemented and tested first. It validates the sandwich architecture, mode detection, SA2 dual-output, and delegate mode patterns that --exploratory will reuse. Do not start P5.15 until P5.13's Task tool mode is functional.

2. **Build order**: One implementation session (not two). P5.13 de-risks the architecture, and 80%+ of the brainstorm skill's stages (Pre-Flight, Synthesis, Critical Evaluation Gate, Diagnostics) remain unchanged. The new work is Stage 3B (AT teammate spawning with consolidated roles) and argument parsing.

3. **Role consolidation**: SME (solo, Task tool) + 3 AT teammates: Product & Delivery (merged PM + Dev Lead), Technical Architect, Critical Analyst. The Critic participates throughout in AT mode — this is the primary quality advantage, do not gate the Critic until the end.

4. **Kill criteria enforced after first test run**: If --exploratory produces no observable peer challenge (teammates never reference or dispute each other's positions), kill the mode immediately. The cost of maintaining a mode that adds token overhead without differentiation exceeds the cost of removing it.

5. **Token budget warning**: --exploratory must warn users at invocation: "Exploratory mode uses Agent Teams peer debate and consumes approximately 2x the token budget of scoped mode. Proceed?"

The justification is straightforward: --exploratory serves a use case that --scoped structurally cannot (adversarial idea validation under uncertainty), the architectural patterns are proven by P5.13, the implementation effort is bounded to one session, and the kill criteria ensure we do not maintain a mode that fails to deliver its differentiating value.
