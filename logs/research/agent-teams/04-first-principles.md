---
viewpoint: First Principles
topic: "Claude Code Agent Teams — Multi-Agent Orchestration Patterns"
confidence_summary:
  high: 8
  medium: 4
  low: 2
key_findings:
  - "Agent Teams solve two distinct problems: (1) user oversight of parallel workers without going through a lead-summary bottleneck, and (2) agent-to-agent peer coordination that bypasses hierarchical routing. The Task tool solves neither."
  - "The Task tool already solves role specialization, model-tier selection, parallel spawning, sequential pipelines, and log-based state sharing — these are NOT differentiators for Agent Teams."
  - "The single genuine structural gap is peer-to-peer messaging: teammates can share findings, challenge each other, and self-coordinate on a shared task list without orchestrator mediation. No equivalent exists in the Task tool model."
  - "Agent Teams are experimental, require an environment variable flag, have known session-resumption bugs, and produce significantly higher token costs. For Bulwark's current workload, the overhead almost certainly exceeds the benefit."
  - "Minimal viable adoption for Bulwark is zero in the short term. The one genuine differentiator (peer debate for competing hypotheses) can be partially replicated with the Task tool using log-file cross-pollination — at lower cost and without experimental risk."
---

# Agent Teams — First Principles

## Summary

Agent Teams introduce two structural capabilities that the Task tool cannot replicate: direct user interaction with individual agents during execution, and agent-to-agent peer messaging that bypasses the lead. The Task tool already covers the remaining claimed differentiators — role specialization, parallel spawning, model-tier selection, and log-based state sharing. For Bulwark's current pipeline architecture, Agent Teams add coordination overhead and experimental instability without proportional gain. The one scenario where they provide genuine value — peer-debate among agents investigating competing hypotheses — is an edge case for Bulwark's planned skills and can be partially approximated using the Task tool's existing log-passing model.

---

## Detailed Analysis

### The Fundamental Problem

**Problem statement, stripped of buzzwords:**

A single AI agent context is a single serial reasoner with a finite attention span. When a task requires genuinely divergent perspectives — not sequential review, but simultaneous adversarial investigation — a single context cannot hold both the hypothesis and its disproof at the same time without one contaminating the other. The "single reviewer anchoring" problem is real: once one plausible explanation is explored, subsequent investigation is biased toward it. Splitting work across isolated agents with independent contexts eliminates anchoring. But isolated agents that can only report to a lead must still wait for the lead to arbitrate before exchanging insights — introducing a coordination bottleneck that slows convergence.

**Agent Teams' specific contribution:** Remove the lead-as-bottleneck by giving agents a shared task list and a direct messaging channel. Agents can self-claim tasks, send findings directly to peers, and have peer responses injected into their conversation history as `<teammate-message>` blocks. No orchestrator mediation required.

**The Task tool's gap:** Task tool sub-agents are structurally hub-and-spoke. Every message flows through the primary model. Peer insights can only be shared by writing to log files and having the orchestrator read and relay them — adding a latency step and burning orchestrator context tokens for content that the peer agents could exchange directly.

**Confidence**: HIGH
**Evidence**: Official Agent Teams docs (code.claude.com/docs/en/agent-teams) explicitly state: "Unlike subagents, which run within a single session and can only report back to the main agent, you can also interact with individual teammates directly without going through the lead." The reverse-engineered implementation (vibecodecamp.blog) confirms messaging via `sendMessage` tool writes to `.claude/teams/<team_id>/inbox/` with per-agent inboxes, injected as new user messages.

---

### What Task Tool Already Solves

The following are commonly cited as Agent Teams differentiators but are already handled by the Task tool:

**Role specialization:** Bulwark already assigns roles by sub-agent definition (bulwark-implementer, bulwark-research, bulwark-brainstorm). The Task tool's `context` field in the 4-part SA1 template carries role-specific instructions. No Agent Teams capability needed.

**Model-tier selection:** OR2 in CLAUDE.md explicitly covers Haiku/Sonnet/Opus selection per agent complexity. The Task tool spawns these with model selection in the sub-agent prompt. Agent Teams adds a model specification flag at spawn time — convenient syntax, not a new capability.

**Parallel execution:** The Task tool supports multiple simultaneous Task calls in a single message. This is how Bulwark's bulwark-research skill spawns 5 parallel Sonnet agents. Agent Teams' "teammates work simultaneously" is the same capability with a different coordination layer.

**Sequential pipelines:** SA4 covers F# pipe syntax where each agent reads the previous agent's log. The shared task list in Agent Teams provides dependency management (`blocked_until` fields), but the same dependency semantics are achievable with explicit log-read prompting.

**Fresh context per agent:** Every Task tool sub-agent gets its own context window. The context isolation that Agent Teams provides is identical to the isolation the Task tool already provides. This is not a differentiator.

**Persistence via shared files:** Bulwark uses `logs/` as the shared state layer. Agent Teams uses `~/.claude/tasks/{team-name}/` as the shared task list. Both are filesystem-backed. The Task tool's log convention (SA2) is functionally equivalent to Agent Teams' task list for Bulwark's use cases.

**Confidence**: HIGH
**Evidence**: CLAUDE.md (SA1-SA6, OR2), Bulwark's existing skill implementations (bulwark-research spawning 5 parallel Sonnet agents; bulwark-brainstorm using sequential Opus pipeline). Official Agent Teams docs confirm context isolation and parallel execution are shared with subagents.

---

### What Genuinely Needs Agent Teams

Two capabilities have no equivalent in the Task tool:

**1. Direct user interaction with individual agents**

In the Task tool model, the user sees only what the orchestrator reports. Individual sub-agent outputs go to log files — the user can read them manually, but cannot interject mid-execution into a specific sub-agent's context without interrupting the orchestrator. Agent Teams' in-process mode (Shift+Up/Down) and split-pane mode let the user message any teammate directly, redirect an approach, or ask follow-up questions without the lead mediating. This is fundamentally a user oversight model — it trades "sealed black box" sub-agents for "observable, interruptible co-workers."

**When this matters for Bulwark:** During long-running parallel work where one agent goes off-track. Currently, if a sub-agent produces wrong output, the orchestrator reads the log, detects the issue, and spawns a corrective agent. Agent Teams would let the user catch the issue in real-time and redirect without waiting for the pipeline to complete. For Bulwark's current planned skills (P5.3-5, P5.13), which are research and generation tasks with short execution windows, this advantage is minor. For hypothetical future long-running autonomous work (multi-hour autonomous implementation), the oversight value increases significantly.

**2. Agent-to-agent peer messaging (adversarial debate)**

The Agyn paper (arxiv.org/html/2602.01465v2) demonstrates that having agents explicitly try to disprove each other's hypotheses produces meaningfully better root-cause identification than sequential investigation. The mechanism is peer challenge: Agent A identifies hypothesis X, sends it to Agent B, Agent B actively searches for evidence against X rather than for X. This cannot be replicated with the Task tool without using the orchestrator as a relay — which adds latency, burns orchestrator context, and requires the orchestrator to correctly synthesize and relay partial findings mid-execution rather than only at completion.

**When this matters for Bulwark:** P5.13 (plan-creation) involves multi-agent research orchestration for implementation planning. If the plan-creation skill needs to produce robust plans with competing hypotheses vetted, Agent Teams' peer-debate structure could improve output quality. The bulwark-research and bulwark-brainstorm skills both currently use sequential (not adversarial) multi-agent approaches — findings from one agent do not reach peers, they only reach the orchestrator. Agent Teams would enable a genuinely different research topology.

**Confidence**: HIGH for the structural gap (peer messaging vs. log-relay). MEDIUM for the materiality of the gap for Bulwark's specific planned skills.
**Evidence**: Official docs; Agyn paper Section on "Investigate with competing hypotheses" example in docs shows sequential investigation suffers from anchoring — "the theory that survives [adversarial debate] is much more likely to be the actual root cause."

---

### Minimal Viable Adoption

**The minimum useful adoption is: one experimental use of Agent Teams for P5.13 (plan-creation), specifically for the competing-hypotheses research phase.**

Reasoning:

1. P5.13 is explicitly "multi-agent research orchestration for implementation planning." Planning quality matters more than implementation quality — a good plan prevents wrong implementation. This is precisely the scenario where adversarial peer debate improves output.

2. The experimental risk is bounded: P5.13 is research output (a plan document), not code. If Agent Teams produces corrupt output, the plan can be re-generated. No production code is at risk.

3. The token cost is bounded: plan-creation runs once per feature, not in a continuous loop. The "significantly more tokens" cost is acceptable for a one-time planning exercise.

4. The tmux constraint is manageable: WSL2 supports tmux. In-process mode (no tmux required) is also available. The split-pane limitation (not supported in VS Code integrated terminal or Windows Terminal) is relevant to the Bulwark development environment, but in-process mode works in any terminal.

**What should NOT use Agent Teams:**

- P5.3 (continuous-feedback): Iterative single-agent loop. No peer debate needed. Ralph loop pattern is a better fit.
- P5.4 (skill-creator): Generation task. Validates via anthropic-validator, not peer debate. Task tool sufficient.
- P5.5 (agent-creator): Same as skill-creator. Single output generation.
- Code review pipeline: Already 4-agent sequential pipeline via Task tool. Adding Agent Teams would add coordination overhead without changing the fundamental review structure.

**Confidence**: MEDIUM
**Evidence**: P5.13 description in CLAUDE.md context (multi-agent research orchestration). Experimental flag caveat means timing is uncertain — Agent Teams could become stable or deprecated before P5.13 is implemented.

---

### Problem Decomposition: Agent Teams vs Ralph Loops

These solve orthogonal problems across four dimensions:

**Context management:**
- *Ralph Loops*: Solve context degradation within a single agent across iterations. Mechanism: fresh context per iteration, filesystem-based state. The constraint being solved is the LLM attention degradation that occurs past ~40-60% of the context window.
- *Agent Teams*: Solve context isolation between agents operating in parallel. Each teammate has its own context window. The constraint being solved is single-agent anchoring (one context biasing toward its first plausible answer).
- *First-principles distinction*: Ralph loops are temporal isolation (fresh context across time); Agent Teams are spatial isolation (parallel contexts at the same time).

**Role specialization:**
- *Ralph Loops*: No native role specialization. The same agent prompt runs every iteration. External specialization requires separate loop scripts per role.
- *Agent Teams*: Native role specialization. Teammates receive distinct system prompts at spawn. The lead assigns tasks by role. Model-tier selection is explicit per teammate.
- *First-principles distinction*: Ralph loops enforce iteration discipline; Agent Teams enforce role discipline.

**Iteration:**
- *Ralph Loops*: Core mechanism. Each bash loop iteration = one fresh context window executing one task.
- *Agent Teams*: Not a native concept. Teammates run until their task is complete, then idle or pick up the next task. Iteration requires a teammate to self-loop (which is not documented behavior) or requires plan-rejection to force a retry.
- *First-principles distinction*: Ralph loops are best for sequential iterative tasks; Agent Teams are best for parallel non-iterative tasks.

**Persistence:**
- *Ralph Loops*: Filesystem-only (git commits, markdown plan files). State survives between bash loop invocations.
- *Agent Teams*: `~/.claude/teams/{team-name}/config.json` and `~/.claude/tasks/{team-name}/` for task state. Also filesystem-backed. Session resumption is explicitly listed as a known limitation — in-process teammates are lost on `/resume`.
- *First-principles distinction*: Both use filesystem persistence. Agent Teams' persistence is more structured (JSON task list with dependency tracking) but has known reliability gaps (task status can lag, no session resumption for in-process teammates).

**Can they coexist?** Yes. An Agent Team lead could spawn a teammate configured to run a Ralph loop for iterative implementation of one module, while other teammates handle research and review in single-shot mode. This is architecturally sound but has no documented precedent.

**Confidence**: HIGH for Ralph loops (previous research in this series validated empirically). MEDIUM for Agent Teams composition with Ralph loops (architecturally sound but untested in practice).
**Evidence**: Ralph Loops synthesis document (logs/research/ralph-loops/synthesis.md); Agent Teams docs stating "teammates cannot spawn their own teams or teammates" — the loop would have to be external bash, not a nested Agent Team.

---

### WSL2 as First-Principles Constraint

WSL2 introduces concrete constraints that affect Agent Teams feasibility:

**Split-pane mode is compromised.** The official docs state: "Split panes require tmux or iTerm2. Split-pane mode isn't supported in VS Code's integrated terminal, Windows Terminal, or Ghostty." On WSL2, the development environment is typically accessed via VS Code Remote-WSL or Windows Terminal running WSL. Both are explicitly listed as unsupported for split-pane mode. This means Agent Teams visual oversight (the main user-facing differentiator) degrades to in-process mode, where teammates run inside the main terminal with Shift+Up/Down navigation.

**In-process mode has no visual parallelism.** Without split panes, the user cannot see multiple agents working simultaneously. The oversight advantage — seeing agents in real time, redirecting off-track agents — is significantly reduced. The lead's terminal lists teammates and their tasks, but agent output is not visible until you navigate to that teammate.

**tmux is available but adds operational complexity.** tmux runs natively on WSL2. Installing it unlocks split-pane mode. However, tmux sessions are separate from the VS Code terminal experience, requiring the user to operate from a native WSL2 terminal. This is a workflow change that may or may not be acceptable depending on the project's typical development workflow.

**Filesystem constraints apply to team config storage.** Agent Teams stores state in `~/.claude/teams/` and `~/.claude/tasks/`. On WSL2, `~` resolves to the native Linux home directory (`/home/user/`) — the fast filesystem, not `/mnt/c/`. This means team coordination files avoid the 9P protocol I/O penalty that affects project files on `/mnt/c/`. From a performance standpoint, the coordination layer is not penalized by WSL2. However, project files that teammates read and modify during tasks (source code on `/mnt/c/`) still incur the cross-filesystem penalty.

**Process model constraint:** Agent Teams spawns multiple Claude Code instances. Each instance is a separate process. On WSL2, process management is straightforward, but the "orphaned tmux sessions" limitation noted in the docs is more likely to manifest in WSL2 environments where tmux session cleanup relies on proper SIGTERM delivery, which can be inconsistent under WSL2's non-standard process namespace.

**Summary of WSL2 impact:**
- Split-pane mode: Degraded (requires tmux workaround)
- In-process mode: Functional (all terminals support it)
- Coordination state I/O: Not penalized (native Linux filesystem)
- Source file I/O by teammates: Penalized if files are on /mnt/c/
- Process lifecycle management: Slightly more fragile (orphaned sessions more likely)

**Confidence**: HIGH for filesystem and terminal constraints (known WSL2 properties). MEDIUM for process lifecycle fragility (no empirical data specific to Agent Teams on WSL2).
**Evidence**: Official Agent Teams docs (limitations section on split-pane requirements); WSL2 9P protocol performance data from Ralph Loops research (logs/research/ralph-loops/04-first-principles.md); general WSL2 process model behavior.

---

## Reasoning Trace: What Changed Between Initial and Deepened Analysis

**Initial framing:** Agent Teams solve peer-to-peer inter-agent communication. The Task tool solves everything else.

**After deepening:** The initial framing was correct but incomplete in two directions:

1. **Simpler than initially framed:** The peer-to-peer messaging capability, while real, may be less valuable for Bulwark than initially suggested. Bulwark's current pipelines are sequential, not adversarial. The peer-debate benefit only materializes for genuinely competing-hypothesis scenarios. For P5.13's planning work, this matters; for P5.3-5, it does not.

2. **More complex than initially framed:** The *user oversight* dimension was initially underweighted. Agent Teams are not just about agent-to-agent coordination — they fundamentally change the user's relationship to parallel execution. The user can observe and redirect individual agents without the lead as intermediary. This is a different trust and control model, not just a communication topology change. In WSL2 environments without split-pane mode, this dimension is significantly reduced.

**Key shift:** The minimal viable adoption recommendation changed from "consider for several planned skills" to "one experimental use for P5.13 only, if and when Agent Teams exits experimental status." The experimental flag, WSL2 visual degradation, and the adequacy of the Task tool for all current Bulwark pipelines reduce the urgency substantially.

---

## Confidence Notes

**LOW confidence findings (2):**

1. **Materiality of peer-debate advantage for P5.13**: The Agyn paper demonstrates peer-debate improves hypothesis investigation on SWE-bench. Whether this improvement transfers to Bulwark's plan-creation use case (which is more structured and specification-driven than open-ended debugging) is speculative. The recommendation to try Agent Teams for P5.13 is based on architectural plausibility, not empirical validation.

   *What would increase confidence*: Implement P5.13 with the Task tool first, measure plan quality, then try Agent Teams and compare. The difference (if any) would reveal whether the peer-debate advantage is real for this specific use case.

2. **Agent Teams' production stability timeline**: The feature is experimental with known limitations (session resumption broken, task status can lag, shutdown can be slow). Whether it stabilizes before Bulwark's P5.13 implementation is unknowable. Committing to Agent Teams adoption before stability is validated is premature.

   *What would increase confidence*: Monitor Agent Teams changelog; the experimental flag removal would be the signal to revisit.

**MEDIUM confidence findings (4):**

1. **In-process mode adequacy on WSL2**: In-process mode is documented as functional in any terminal, but the user experience (Shift+Up/Down navigation between agents vs. visual split panes) may be insufficient for the oversight value Agent Teams provide. No empirical testing of in-process mode on WSL2 was conducted.

2. **P5.13 task decomposition fit**: The assumption that P5.13 involves "competing hypotheses" research is based on the description "multi-agent research orchestration for implementation planning" and the context from CLAUDE.md. If P5.13 ends up being sequential research (Viewpoint A → Viewpoint B → synthesis), the Task tool is sufficient.

3. **Agent Teams + Ralph loop composition**: Architecturally sound (teammates are independent Claude sessions; a bash loop could be an external wrapper around a teammate). No documented examples exist, and the "teammates cannot spawn their own teams" limitation confirms nesting is blocked, but the external-bash-loop pattern should work.

4. **Token cost materiality**: The docs state Agent Teams use "significantly more tokens." For Bulwark's planned one-time research tasks (not continuous loops), this may be affordable. But no token budget analysis was conducted for a concrete P5.13-sized task.

---

## Sources

- [Official Agent Teams Documentation](https://code.claude.com/docs/en/agent-teams)
- [Agyn: Multi-Agent Systems for Software Engineering (arXiv:2602.01465v2)](https://arxiv.org/html/2602.01465v2)
- [Agent Teams — Reverse Engineered Implementation Details](https://vibecodecamp.blog/blog/how-to-install-and-use-claude-code-agent-teams-reverse-engineered)
- [Creating Agent Teams (GitHub Repository)](https://github.com/ZoranSpirkovski/creating-agent-teams)
- [Ralph Loops — First Principles (prior research)](../ralph-loops/04-first-principles.md)
- [Ralph Loops — Synthesis (prior research)](../ralph-loops/synthesis.md)
- [Bulwark Architecture](../../../../docs/architecture.md)
- [CLAUDE.md — Project Rules (SA1-SA6, OR1-OR4)](../../../../CLAUDE.md)
