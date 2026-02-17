---
topic: "Claude Code Agent Teams — Multi-Agent Orchestration Patterns"
phase: research
agents_synthesized: 5
confidence_distribution:
  high: 47
  medium: 24
  low: 11
---

# Agent Teams — Research Synthesis

## Key Findings (Convergent)

All 5 viewpoints converge on these findings with HIGH confidence:

| Finding | Supporting Viewpoints | Confidence |
|---------|----------------------|------------|
| Agent Teams are architecturally distinct from Task tool sub-agents in three ways: persistent sessions, peer-to-peer mailbox messaging, and shared task lists with self-claiming. These are genuine structural differences, not syntactic sugar. | All 5 | HIGH |
| Existing Bulwark pipelines (code-review, test-audit, bulwark-research, bulwark-brainstorm) should NOT migrate to Agent Teams in their current modes. They are "focused workers that report back" — the exact use case Anthropic's own docs recommend Task tool sub-agents for. However, bulwark-brainstorm could gain an `--exploratory` mode using Agent Teams for idea validation (see Post-Synthesis Decisions). | All 5 + post-synthesis user input | HIGH |
| P5.13 (plan-creation) is the canonical Agent Teams candidate for Bulwark. The task brief explicitly specifies "multi-agent research orchestration using agent teams." Peer debate between research agents would improve plan quality over independent parallel analysis. | DI, Prac, FP, PA, Contrarian (acknowledges as genuine use case) | HIGH |
| P5.3 (continuous-feedback), P5.4 (skill-creator), P5.5 (agent-creator) have LOW applicability for Agent Teams. P5.3 is a batch pipeline, P5.4/P5.5 are generation+validation tasks. None require peer debate. | All 5 | HIGH |
| Agent Teams are experimental (Feb 2026), require `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`, and have known limitations: session resumption broken for in-process mode, task status lag, lead context compaction can orphan teammates. Not production-ready. | All 5 | HIGH |
| WSL2 split-pane mode requires tmux (Windows Terminal not supported, GitHub #24384). In-process mode works in any terminal. Start with in-process mode for Bulwark. | All 5 | HIGH |
| Agent Teams and Ralph Loops solve orthogonal problems (role specialization vs. context degradation) via independent historical lineages. They can coexist but should NOT be hybridized without empirical validation. | All 5 | HIGH |
| The Task tool is sufficient for all current Bulwark workflows. Switching costs (migration, debugging complexity, token overhead, SA2 compliance risk) are not justified. | All 5 | HIGH |
| Effective team size caps at 3-4 agents before coordination overhead dominates. Token cost is ~2x for equivalent team sizes (1.8-2x per practitioner data), with official docs citing up to 7x in plan mode. | Prac, Contrarian, PA, FP | HIGH |
| Agent Teams' coordination files (`~/.claude/teams/`, `~/.claude/tasks/`) live on native Linux filesystem in WSL2, not `/mnt/c/`. Coordination primitives are fast regardless of project file location. | DI, Prac | HIGH |

## Research Objective 1: What Are Agent Teams?

### Definition

Agent Teams are an experimental Claude Code feature (Feb 2026) that coordinates multiple persistent Claude Code instances as a named team. Each teammate has its own context window, communicates via a filesystem-based mailbox system, and coordinates via a shared task list with file-locked claiming.

### Architecture

| Component | Role | Storage |
|-----------|------|---------|
| Team Lead | Creates team, spawns teammates, coordinates work | Main session |
| Teammates | Independent Claude instances with own context | Separate processes |
| Task List | Shared work queue with dependencies and file-locked claiming | `~/.claude/tasks/{team-name}/` |
| Mailbox | Async peer-to-peer messaging (targeted `write` or `broadcast`) | `~/.claude/teams/{id}/inbox/` |

### Key Differences from Task Tool Sub-Agents

| Dimension | Task Tool Sub-Agents | Agent Teams |
|-----------|---------------------|-------------|
| Context | Own window; results return to caller | Own window; fully independent |
| Communication | Report to parent only (hub-and-spoke) | Peer-to-peer via mailbox (mesh) |
| Coordination | Orchestrator manages all sequencing | Shared task list; self-claiming |
| Persistence | Terminates on task completion | Persists until explicit shutdown |
| Nested spawning | Unlimited depth | Prohibited (lead only) |
| Token cost | Lower (result summarized) | ~2x higher (full context per teammate) |
| Session resumption | Works | Broken for in-process mode |
| Stability | Production feature | Experimental |

### Implementation Variants

1. **In-Process Mode** (default) — all teammates in one terminal, Shift+Up/Down to switch. Works in any terminal including WSL2.
2. **Split-Pane Mode (tmux)** — each teammate gets a dedicated tmux pane. Requires tmux; auto-detected via `$TMUX` env var.
3. **Split-Pane Mode (iTerm2)** — macOS only.
4. **Delegate Mode** — lead restricted to coordination only (Shift+Tab). Prevents lead from implementing.
5. **Peer Deliberation Mode** — teammates explicitly prompted to challenge each other's findings. Primary differentiator from Task tool.

### Historical Lineage (Prior Art)

Agent Teams recapitulate the blackboard systems architecture (HEARSAY-II, 1971-1976): shared workspace + independent specialist knowledge sources + scheduler. The LLM is the new substrate — it eliminates the prohibitive cost of manually engineering each knowledge source. FIPA's 1997 standardized agent communication failed due to brittle symbolic semantics; Agent Teams' natural-language mailbox succeeds where FIPA failed because LLMs interpret messages adaptively.

## Research Objective 2: Applicability to Bulwark Skills

### Applicability Matrix

| Skill/Task | Agent Teams Fit | Rationale | Viewpoint Agreement |
|------------|----------------|-----------|---------------------|
| **P5.13 (plan-creation)** | HIGH | Task brief explicitly specifies Agent Teams. Peer debate between research agents improves plan quality. Delegate mode matches orchestrator pattern. | All 5 |
| **code-review** | NOT APPLICABLE | 4 independent reviewers report back. No peer debate needed. Adding Agent Teams = ~2x cost with no benefit. | All 5 |
| **test-audit** | NOT APPLICABLE | Sequential pipeline. Agent Teams explicitly poor fit for sequential dependencies. | All 5 |
| **bulwark-research** | NOT APPLICABLE | Independent viewpoints are intentional design. Peer messaging would introduce anchoring bias, degrading independent assessment quality. | All 5 |
| **bulwark-brainstorm (--scoped)** | NOT APPLICABLE | Sequential role progression (SME→PM→Arch→Dev Lead→Critic) is intentional for focused implementation brainstorming. Parallelizing loses deliberate sequencing. Critic needs prior roles' context. | All 5 |
| **bulwark-brainstorm (--exploratory)** | HIGH | New mode: 5 personas debate collaboratively via Agent Teams peer messaging to validate whether an idea has merit. Peer challenge prevents early anchoring. See Post-Synthesis Decisions. | Post-synthesis user input |
| **P5.3 (continuous-feedback)** | LOW | Batch improvement pipeline. Sequential, no peer debate needed. | All 5 |
| **P5.4 (skill-creator)** | LOW | Generation + structural validation. Ralph Loops better fit. | All 5 |
| **P5.5 (agent-creator)** | LOW | Same as P5.4. | All 5 |
| **P5.14 (completed)** | NOT APPLICABLE | Already completed. Research/brainstorm skills are one-shot analysis. | DI |

### The Decision Principle

> **If the task requires agents to challenge each other's findings mid-execution (adversarial debate), Agent Teams add value. If agents work independently and report back, the Task tool is correct.**
> — Convergent across all 5 viewpoints

### Specific Features That Would Benefit from Agent Teams

Two Bulwark patterns would genuinely benefit:

1. **Competing-hypotheses investigation** — where agents actively try to disprove each other's theories rather than independently analyze. This is Agent Teams' primary differentiator. Applicable to P5.13's multi-agent research phase.

2. **Exploratory brainstorming** — where personas collaboratively debate whether an idea has merit, rather than independently assessing a well-defined topic. The current bulwark-brainstorm `--scoped` mode (sequential assessment) works well for focused implementation brainstorming. A new `--exploratory` mode using Agent Teams would serve idea validation, where the problem framing itself is uncertain and benefits from real-time cross-challenge between personas.

Features that work fine with Task tool (no Agent Teams needed):
- Parallel independent reviewers → orchestrator synthesis (code-review, bulwark-research)
- Sequential pipeline stages (test-audit)
- Sequential role progression with context handoff (bulwark-brainstorm `--scoped`)
- Single-agent focused tasks (bulwark-implementer, P5.4, P5.5)

### P5.13 Recommended Configuration

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Display mode | In-process | WSL2 safe default, no tmux dependency |
| Lead mode | Delegate | Prevents lead from implementing |
| Teammates | 5 specialist researchers | Matches bulwark-research viewpoint count |
| Communication | Peer challenge prompts | Explicit "challenge teammate X's finding" instructions |
| Model | Sonnet per teammate | OR2 standard complexity |

## Research Objective 3: Agent Teams vs Ralph Loops

### Ralph Loops Descoped from Bulwark

**Decision (Post-Synthesis)**: Ralph Loops have been descoped from Bulwark entirely. Two research sessions (Session 61 + Session 62) conclusively established:

1. **Session 61**: Near-zero applicability for existing skills. Only P5.4/P5.5 structural validation had MODERATE-HIGH fit.
2. **Session 62**: Agent Teams solve the more relevant problem for Bulwark (peer debate, collaborative exploration).
3. **The remaining Ralph use case** (P5.4/P5.5 "loop until anthropic-validator passes") is basic iterative development, not a formal methodology worth adopting.
4. **Ralph's core insight** — fresh context per iteration for long-running autonomous work — doesn't apply. Bulwark skills are short-lived, user-supervised, and orchestrator-driven.

The two research sessions were valuable for ruling Ralph out with evidence rather than assumption.

### Recommended Orchestration Approach per Skill

| Use Case | Approach | Rationale |
|----------|----------|-----------|
| P5.13 plan-creation | Agent Teams (dual mode — see Post-Synthesis Decisions) | Peer deliberation is the core value |
| P5.4 skill-creator | Task tool | Generation + validation, iterative dev as needed |
| P5.5 agent-creator | Task tool | Same as skill-creator |
| P5.3 continuous-feedback | Task tool or single agent | Batch improvement pipeline |
| code-review | Task tool (current) | Independent lenses, no peer debate |
| test-audit | Task tool (current) | Sequential pipeline |
| bulwark-research | Task tool (current) | Independent viewpoints intentional |
| bulwark-brainstorm --scoped | Task tool (current) | Sequential role progression for focused brainstorming |
| bulwark-brainstorm --exploratory | Agent Teams | Collaborative peer debate for idea validation |

## Research Objective 4: WSL2 and Tmux Considerations

### WSL2 Constraints

| Area | Impact | Mitigation |
|------|--------|------------|
| **Split-pane mode** | Windows Terminal NOT supported (GitHub #24384). VS Code terminal NOT supported. | Use in-process mode (works in any terminal) or install tmux in WSL2 |
| **tmux workaround** | Works: `apt install tmux`, launch claude from within tmux session. Auto-detected via `$TMUX` env var. | Dedicated tmux session for Agent Teams (GitHub #23615: splits disrupt existing layouts) |
| **Coordination files** | `~/.claude/teams/` and `~/.claude/tasks/` are on native Linux FS (fast). | No mitigation needed — coordination is not penalized by WSL2 |
| **Project files on /mnt/c/** | Each teammate loads CLAUDE.md and project files at spawn — all go through 9P protocol (slow). Multiplied by team size. | Accept for small teams (3-4). Consider git worktree on /home/ for larger operations |
| **Process lifecycle** | Orphaned tmux sessions may persist. SIGTERM delivery can be inconsistent under WSL2. | Manual cleanup: `tmux ls` + `tmux kill-session`. Lead must run cleanup. |
| **Session resumption** | `/resume` does NOT restore in-process teammates. | Acceptable for short-lived research tasks. Blocking for long-running automation. |

### Tmux Advantages for Agent Teams on WSL2

1. **Visual parallelism** — see all teammates working simultaneously (not available in in-process mode)
2. **Session persistence** — survives terminal closure, Windows updates, laptop sleep
3. **Direct teammate observation** — each pane shows full Claude Code session for one teammate
4. **Copy mode debugging** — scroll back through teammate output history

### Tmux Gotchas on WSL2

1. **GitHub #23615**: Agent Teams split into current tmux window, disrupting layouts. Use dedicated tmux session.
2. **wslvar/wslpath**: Don't work properly within tmux sessions
3. **Windows SSH server conflicts**: tmux sessions invisible from SSH into WSL2 if Win10 SSH enabled
4. **NAT networking**: IDE detection failures. Use `mirrored` networking mode (Win11 22H2+)

### Recommendation

**Start with in-process mode** for initial P5.13 development. It works in any terminal, requires no setup, and avoids all tmux-specific issues. Add tmux only if real-time visual oversight of parallel agents becomes a genuine need (not a preference).

## Tensions and Trade-offs

### Tension 1: P5.13 Timing — Now vs. Wait for Stability

- **View A** (Direct Investigation, Prior Art): Use Agent Teams for P5.13 now. The task brief specifies it. Peer debate improves plan quality. Experimental risk is bounded — output is a plan document, not production code.
- **View B** (Contrarian, First Principles): Wait for Agent Teams to exit experimental status. Task tool can replicate most of the value via log-file cross-pollination at lower cost and without experimental risk. Known failure modes (lead context compaction, task status lag, session resumption) add operational burden.
- **View C** (Practitioner): Evaluate empirically — try one P5.13 run with Agent Teams and one with Task tool. Compare output quality and token cost.
- **Implication**: The pragmatic approach is View C. Implement P5.13 first with the Task tool (known quantity), then optionally re-run with Agent Teams to compare. This avoids blocking P5.13 on Agent Teams stability while generating empirical data for the adoption decision.

### Tension 2: Peer Debate Value — Genuine vs. Over-Hyped

- **View A** (Direct Investigation, Prior Art): Genuine advantage. The Agyn paper demonstrates adversarial investigation produces better root-cause identification. HEARSAY-II's blackboard architecture validated multi-agent specialization 50 years ago. Agent Teams are the first credible LLM implementation.
- **View B** (Contrarian, First Principles): Over-hyped for Bulwark's context. Bulwark's pipelines are "focused workers that report back." Peer debate adds value only for genuinely competing hypotheses — an edge case. Log-file cross-pollination via the orchestrator can approximate the benefit at lower cost.
- **Implication**: Peer debate is genuinely valuable for novel investigation (debugging, research), but Bulwark's current skills are structured analysis, not open-ended investigation. The value is real but the applicability to Bulwark's current architecture is narrow. P5.13 is the one planned skill where it could matter.

### Tension 3: SA2 Compliance Risk

- **View A** (Contrarian): Agent Teams' mailbox communication creates an information channel outside SA2's closed-loop requirement. Teammates exchange findings via messages never written to `logs/`, violating SA2.
- **View B** (Direct Investigation, Practitioner): Manageable via explicit prompting — instruct teammates to write findings to logs/ in addition to sending messages. The mailbox is for coordination, not for final output.
- **Implication**: If Agent Teams are adopted for P5.13, the skill must include explicit SA2-compliant output instructions. Teammate prompts must specify: "Write your findings to logs/ AND send summary to peers."

## Unique Insights

| Insight | Source Viewpoint | Confidence |
|---------|-----------------|------------|
| Agent Teams = HEARSAY-II (1971) with LLM knowledge sources. The architecture is 50 years old; the substrate is new. | Prior Art | HIGH |
| FIPA (1997-2005) failed because symbolic ACL was too brittle. Agent Teams succeed because LLMs interpret natural-language mailbox messages adaptively — exactly the universal parser FIPA needed. | Prior Art | HIGH |
| Lead context compaction = total team loss. When the orchestrator's context fills and is summarized, it loses all awareness of running teammates. Orphaned processes require manual cleanup from `~/.claude/`. Most severe underdiscussed failure mode. | Contrarian | HIGH |
| XML-tag injection as the inter-agent communication substrate is fragile. Messages are injected as `<teammate-message>` blocks into conversation histories — this consumes context (accelerating compaction) and can break with Claude Code version changes. | Contrarian | MEDIUM |
| Error multiplication: 5 agents at 95% individual accuracy = 77% system reliability in a sequential chain. Peer debate helps but introduces its own error surface. | Contrarian | MEDIUM |
| The "Inverse Conway Maneuver" — Agent Teams' delegate mode makes Conway's Law programmable. Restrict the lead to coordination → force genuine parallelism. | Prior Art | MEDIUM |
| Mob programming's empirical 4-5 person optimum maps to Agent Teams' 3-4 agent coordination overhead cap. | Prior Art | MEDIUM |
| Task tool's nested spawning (unlimited depth) is actually an advantage over Agent Teams (no nested teams). Bulwark's hierarchical orchestration pattern benefits from nesting capability. | Contrarian, FP | HIGH |
| The field is replaying FIPA's standardization with A2A (Google) and MCP (Anthropic). Agent Teams' filesystem mailbox is a pre-standardization protocol likely to converge toward A2A. | Prior Art | MEDIUM |

## Confidence Map

| Finding | Supporting Viewpoints | Confidence |
|---------|----------------------|------------|
| Agent Teams vs Task tool structural differences | All 5 | HIGH |
| Existing Bulwark pipelines should not migrate | All 5 | HIGH |
| P5.13 is the canonical Agent Teams candidate | All 5 | HIGH |
| P5.3, P5.4, P5.5 have LOW applicability | All 5 | HIGH |
| Agent Teams are experimental with known limitations | All 5 | HIGH |
| WSL2: in-process mode is safe default, tmux for split-panes | All 5 | HIGH |
| Agent Teams and Ralph Loops solve orthogonal problems | All 5 | HIGH |
| Task tool is sufficient for current Bulwark workflows | All 5 | HIGH |
| 3-4 agent cap before coordination overhead dominates | Prac, Contrarian, PA, FP | HIGH |
| Peer debate is the primary differentiator | All 5 | HIGH |
| Lead context compaction = total team loss | Contrarian | HIGH |
| Token cost ~2x for equivalent teams | Prac | MEDIUM |
| Agent Teams + Ralph coexistence architecturally sound | DI, FP, PA | MEDIUM |
| SA2 compliance manageable with explicit prompting | DI, Prac | MEDIUM |
| P5.13 should try Task tool first, Agent Teams second | Prac, FP | MEDIUM |
| Agent Teams = HEARSAY-II architecture | PA | MEDIUM |
| Hybridizing Agent Teams + Ralph = unnecessary complexity | Contrarian | MEDIUM |
| WSL2 process lifecycle fragility | Contrarian, FP | LOW |
| Peer debate improvement quantification | DI, PA | LOW |

## Open Questions

1. **P5.13 implementation approach**: Should P5.13 use Agent Teams from the start (as the task brief specifies) or implement with Task tool first and optionally re-run with Agent Teams? The pragmatic path is Task tool first, but this defers the Agent Teams validation that P5.13 was designed for.

2. **Agent Teams stability timeline**: When will Agent Teams exit experimental status? The experimental flag removal would be the signal to adopt more broadly. No timeline exists.

3. **Token cost for Bulwark-scale tasks**: Reported costs (~2x) are from community benchmarks, not Bulwark-specific measurements. What would a P5.13-equivalent task cost with Agent Teams vs Task tool?

4. **SA2 compliance enforcement**: If Agent Teams are adopted, how do we ensure mailbox messages don't become an undocumented information channel that bypasses SA2's closed-loop log requirement?

5. **WSL2 tmux stability**: The tmux+WSL2 workaround is documented as working, but no Bulwark-specific testing has been done. Should a validation run precede P5.13 adoption?

## Post-Synthesis Decisions

*User input incorporated after synthesis review. Classifications per Critical Evaluation Gate.*

### P5.13 Implementation Approach — User Preference (deferred to brainstorm)

> **User**: "I think a dual implementation would be better, but this is an implementation question so it probably belongs more in the brainstorm phase."

**Classification**: Opinion/Preference — clear design direction, correctly scoped to brainstorm phase.

**Impact on findings**: P5.13's approach (Task tool vs. Agent Teams vs. dual) is confirmed as a brainstorm-phase design question, not a research question. The research establishes that both approaches are viable; the brainstorm should decide the implementation strategy.

### SA2 Compliance — User Preference (deferred to brainstorm)

> **User**: "I'd lean towards explicit logs for artifacts and keep mailbox specific to coordination + summaries between peers."

**Classification**: Opinion/Preference — aligns with synthesis Tension 3 resolution.

**Impact on findings**: Confirms the recommended approach (explicit log-writing in teammate prompts, mailbox for coordination only). SA2 rule amendment is not needed — the existing rule holds if prompts enforce log output. Detailed design deferred to brainstorm phase.

### Ralph Loops Descoped — User Decision

> **User**: "Agree with descoping Ralph loops — no use case in Bulwark requires it."

**Classification**: Factual — confirmed by two research sessions (61 + 62).

**Impact on findings**: Ralph Loops removed from the orchestration approach table. P5.4/P5.5 revert to Task tool with basic iterative development. Research schedule sessions referencing Ralph brainstorm can be dropped.

### Bulwark-Brainstorm Two Modes — User Decision

> **User**: "For bulwark-brainstorm, the two modes make perfect sense. Instead of calling it sequential or collaborative, we can call these switches as `--scoped` and `--exploratory`. Use scoped (sequential) when the problem statement is well understood and needs focused brainstorming on implementation. Use exploratory (collaborative) to validate an idea."

**Classification**: Opinion/Preference — design direction grounded in clear use-case distinction.

**Impact on findings**: bulwark-brainstorm gains a second Agent Teams use case alongside P5.13. This strengthens the case for Agent Teams adoption in Bulwark — two concrete use cases (plan-creation + exploratory brainstorming) rather than one. The `--scoped` mode remains unchanged (Task tool, sequential personas). The `--exploratory` mode uses Agent Teams peer messaging for real-time collaborative debate. Detailed design deferred to brainstorm phase.

| Mode | Mechanism | When to Use |
|------|-----------|-------------|
| `--scoped` | Task tool, sequential (current design) | Problem statement is well understood, need focused implementation brainstorming |
| `--exploratory` | Agent Teams, peer debate | Validating whether an idea has merit, problem framing is uncertain |

### Research Schedule — Finalized (Session 62)

**Original schedule** (8 sessions: 3 research + 1 cross-synthesis + 4 brainstorm) compressed to **4 sessions** (1 research + 3 brainstorm):

> **User decisions**:
> - Ralph Loops descoped → Ralph brainstorm dropped
> - No cross-topic synthesis needed — no overlap between Agent Teams and Feedback Patterns findings
> - P5.3 needs brainstorm (implementation questions), not research
> - P5.4/P5.5 needs research (meta-skill design is novel)
> - P5.13 and brainstorm-exploratory each need brainstorm
> - WSL2: use WSL as-is, tmux deferred to later

**Finalized schedule:**

| Session | Topic | Activity | Focus |
|---------|-------|----------|-------|
| 63 | P5.3 (continuous-feedback) | `/bulwark-brainstorm --scoped` | Pipeline design, per-skill specialization, improvement identification automation |
| 64 | P5.4/P5.5 (skill-creator, agent-creator) | `/bulwark-research` | Meta-skill design patterns — framework for deciding skill needs (scripts, sub-agents, Agent Teams, etc.) |
| 65 | P5.13 (plan-creation) | `/bulwark-brainstorm --scoped` | Agent Teams dual-mode implementation, peer debate structure, SA2 compliance |
| 66 | bulwark-brainstorm `--exploratory` | `/bulwark-brainstorm --scoped` | Agent Teams collaborative mode design, persona dynamics, `--scoped` vs `--exploratory` switching |

**Classification**: All user responses were Opinion/Preference (design direction) or Factual (existing workflow knowledge). No Speculative responses — no follow-up research triggered.

**Decision reference**: These schedule decisions were made in Session 62 (2026-02-16). Future sessions implementing these items should reference the Agent Teams synthesis (`logs/research/agent-teams/synthesis.md`) and this session's handoff for full context on the rationale.

## Implications for Next Steps

### For P5.3-5 Implementation

The research conclusively establishes:
- **P5.3** should use a single agent or Task tool sub-agents (batch improvement pipeline, no peer debate needed)
- **P5.4/P5.5** should use Task tool with basic iterative development (generate → validate via anthropic-validator → fix → re-validate). Ralph Loops descoped.
- **None of P5.3-5 need Agent Teams**

### For P5.13 Implementation

P5.13 is the one Bulwark skill where Agent Teams could genuinely improve output quality via peer debate. The pragmatic approach:
1. Implement P5.13 with Task tool first (known quantity, SA2 compliant, production stable)
2. Optionally re-implement with Agent Teams to compare quality and cost
3. Adopt Agent Teams for P5.13 only if: (a) quality improvement is measurable, (b) Agent Teams exits experimental status, (c) token cost is acceptable

### For Session 63-64 (Feedback Patterns + Cross-Topic Synthesis)

Session 63 (Feedback Patterns research) should focus on P5.3's batch improvement workflow — Agent Teams are not relevant.

Session 64 (Cross-Topic Synthesis) gate decision material:
- Ralph Loops: narrowly applicable to P5.4/P5.5 structural phases only
- Agent Teams: applicable to P5.13 only, experimental, not needed for P5.3-5
- Existing Task tool: correct for all current and most planned Bulwark skills
- The three approaches are complementary at different scales, not competing

### For Existing Skills (code-review, test-audit, bulwark-research, bulwark-brainstorm)

**No migration needed for current modes.** All four skills use the Task tool correctly for their specific design patterns:
- Parallel independent reviewers → orchestrator synthesis (code-review, bulwark-research)
- Sequential pipeline stages (test-audit)
- Sequential role progression with context handoff (bulwark-brainstorm `--scoped`)

**One new mode identified**: bulwark-brainstorm `--exploratory` using Agent Teams for collaborative idea validation. This is a new capability, not a migration — the existing `--scoped` mode remains unchanged. Design deferred to brainstorm phase alongside P5.13.

### For Agent Teams Adoption in Bulwark (Summary)

Two concrete use cases justify eventual Agent Teams adoption:

| Use Case | Skill | Mode | Timing |
|----------|-------|------|--------|
| Multi-agent research with peer debate | P5.13 plan-creation | Dual (Task tool + Agent Teams) | When P5.13 is implemented |
| Collaborative idea validation | bulwark-brainstorm | `--exploratory` | When Agent Teams exits experimental status |

Both are gated on Agent Teams stability. Neither requires migrating existing working skills.
