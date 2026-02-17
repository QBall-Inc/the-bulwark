---
viewpoint: Direct Investigation
topic: "Claude Code Agent Teams — Multi-Agent Orchestration Patterns"
confidence_summary:
  high: 18
  medium: 6
  low: 3
key_findings:
  - "Agent Teams are a distinct Claude Code primitive from Task tool sub-agents: teammates persist until explicit shutdown, communicate via a mailbox system with direct peer-to-peer messaging, and coordinate via a shared task list with file-locked claiming — none of which exist in sub-agent mode."
  - "Agent Teams are experimental and disabled by default (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 required); released alongside Opus 4.6 in February 2026 with known limitations around session resumption and task status lag."
  - "P5.13 (plan-creation skill) is the highest-applicability target — the task brief explicitly specifies 'multi-agent research orchestration using agent teams' as its design intent."
  - "WSL2 + tmux is the required path for split-pane mode on Windows; Windows Terminal is not natively supported (GitHub issue #24384, open as of Feb 9, 2026); in-process mode works in any terminal including WSL2 without tmux."
  - "Agent Teams and Ralph Loops solve orthogonal problems (role specialization vs. context degradation) and can coexist cleanly — Agent Teams for research/review pipelines, Ralph for iterative batch operations — but hybrid patterns (Teams of Ralphs) compound overhead and should not be attempted without empirical validation."
---

# Agent Teams — Direct Investigation

## Summary

Claude Code Agent Teams are an experimental multi-session orchestration primitive released in February 2026 that extends beyond the Task tool sub-agent model by enabling direct peer-to-peer messaging, shared task lists with dependency tracking, and persistent teammate sessions. They are architecturally distinct from Bulwark's current Task tool pipelines and offer genuine advantages for tasks requiring inter-agent deliberation and parallel exploration — but carry meaningfully higher token costs and known stability limitations. P5.13 (plan-creation) is the clearest implementation target; existing Bulwark pipelines (code-review, test-audit, bulwark-research, bulwark-brainstorm) already use the Task tool correctly and do not need migration.

---

## Reasoning Process

### Step 1: Initial Research

Primary sources consulted:
- Official Anthropic documentation at https://code.claude.com/docs/en/agent-teams (complete, authoritative)
- Official cost documentation at https://code.claude.com/docs/en/costs
- GitHub issue #24384: Windows Terminal split-pane support (open feature request)
- GitHub gist by kieranklaassen: Claude Code Swarm Orchestration Skill (community implementation patterns)
- ZoranSpirkovski/creating-agent-teams GitHub repository
- addyosmani.com blog post on Agent Teams architecture
- WebSearch results for WSL2/tmux limitations and Agent Teams vs. subagents comparison

Secondary sources consulted:
- arxiv 2602.01465v2: Agyn multi-agent SWE system (adjacent research, not Anthropic-specific)
- Ralph Loops synthesis from logs/research/ralph-loops/synthesis.md (prior Bulwark research)

Vibecodecamp.blog (403) and charlesjones.dev (403) were inaccessible. Medium's joe.njenga article was also inaccessible. These are secondary sources; their absence does not affect core findings.

### Step 2: Evaluate

| Claim | Evidence | Counterevidence | Net Assessment |
|-------|----------|-----------------|----------------|
| Teammates persist until explicit shutdown | Official docs: "Persists until shutdown requested" vs. sub-agents which terminate after task | None | HIGH |
| Peer-to-peer messaging via mailbox | Docs specify inbox files at `~/.claude/teams/{name}/inboxes/{agent}.json`; `write` vs `broadcast` operations | None | HIGH |
| ~7x token cost in plan mode | Official costs page states "approximately 7x more tokens...when teammates run in plan mode" | Blog sources say ~5x; discrepancy due to measurement scenario | MEDIUM — 5-7x range is safe claim |
| WSL2+tmux enables split panes | GitHub issue #24384 confirms Windows Terminal not supported, WSL2+tmux is workaround | Adds setup complexity | HIGH |
| No nested teams | Official limitations section | None | HIGH |
| TeammateIdle/TaskCompleted hooks exist | Official docs and search results corroborate | None | HIGH |

### Step 3: Identify Gaps After Initial Research

1. **Task-specific applicability**: What exactly are P5.3/P5.4/P5.5/P5.13 and what do they need? Needed tasks.yaml inspection.
2. **Ralph coexistence specifics**: Prior research synthesis already resolved this — reading ralph-loops/synthesis.md filled the gap.
3. **vibecodecamp reverse-engineered architecture**: 403 blocked this source. Gap partially filled by gist source with similar internal detail.

### Step 4: Deepen

- Read tasks.yaml for P5.3/5.4/5.5/5.13 full definitions. Finding: P5.13 explicitly specifies "multi-agent research orchestration using agent teams." P5.4/P5.5 specify Ralph loop guidance, not Agent Teams.
- Read ralph-loops/synthesis.md. Finding: comprehensive coexistence analysis already exists with HIGH confidence.
- Fetched GitHub issue #24384. Finding: Windows Terminal support is an open issue (Feb 9, 2026), WSL2+tmux confirmed as working workaround, environment variables `CLAUDE_CODE_TEAM_NAME`/`CLAUDE_CODE_AGENT_ID`/`CLAUDE_CODE_AGENT_NAME` are the team protocol identifiers.

### Step 5: Reconcile

Initial finding on WSL2 was "tmux works as workaround." After deepening: confirmed with precise evidence — detection order is iTerm2 → tmux → in-process, `$TMUX` env var triggers split-pane mode automatically, and in-process fallback works in any terminal (including WSL2 without tmux). No initial conclusions shifted; depth increased substantially.

---

## Detailed Analysis

### Definition and Architecture

**What Agent Teams Are**

Agent Teams are a Claude Code feature that coordinates multiple Claude Code instances (sessions) as a named team with shared infrastructure. The primitive has four components:

| Component | Role | Storage |
|-----------|------|---------|
| Team Lead | Main session that creates the team, spawns teammates, coordinates work | Lives in main session |
| Teammates | Independent Claude Code instances with their own context windows | Separate processes |
| Task List | Shared work queue with dependency tracking and file-locked claiming | `~/.claude/tasks/{team-name}/N.json` |
| Mailbox | Asynchronous peer-to-peer messaging between any team members | `~/.claude/teams/{name}/inboxes/{agent}.json` |

**Lifecycle**

1. Lead enables the feature (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1) and requests a team
2. Lead calls `spawnTeam` to create infrastructure and designate itself as lead
3. Lead spawns teammates via the Task tool with `team_name` and `name` parameters
4. Teammates load CLAUDE.md, MCP servers, and skills from the project directory (same as a regular session); they do NOT inherit the lead's conversation history
5. Teammates receive their spawn prompt and begin working; they access the shared task list and communicate via mailboxes
6. Teammates self-claim unassigned tasks (file locking prevents race conditions)
7. When a task's dependencies complete, dependent tasks auto-unblock
8. Lead sends `requestShutdown`; teammate approves and exits
9. Lead calls `cleanup` to remove team infrastructure (fails if any teammates still active)

**Key Operational Detail**

Teammate stdout is NOT visible to the team. All coordination flows through inbox messages and TaskUpdate calls. The lead must use `write` (targeted) or `broadcast` (all teammates, expensive) to communicate — direct output is invisible.

**Context per Teammate**

Each teammate has its own context window that does not compound with the lead's context. This enables specialization without context pollution: a security reviewer teammate never reads the performance reviewer's findings unless explicitly messaged.

**Confidence**: HIGH
**Evidence**: Official Anthropic docs (https://code.claude.com/docs/en/agent-teams), GitHub gist (kieranklaassen), ZoranSpirkovski repository

---

### Implementation Variants

**Variant 1: In-Process Mode (Default)**

All teammates run inside the lead's terminal process. Interaction via Shift+Up/Down to select a teammate. Requires no extra setup. Works in any terminal including WSL2 without tmux, VS Code terminal, and Windows Terminal. This is the fallback when no tmux/iTerm2 is detected.

Tradeoff: Less visual. Cannot see all teammates simultaneously. Still fully functional for coordination.

**Variant 2: Split-Pane Mode (tmux)**

Each teammate gets a dedicated tmux pane. Lead's terminal auto-detects `$TMUX` env variable and switches to split-pane mode. Each pane shows a full Claude Code session for that teammate.

Requires tmux installed and Claude Code invoked from within a tmux session. Works on WSL2 if tmux is installed in the Linux environment.

Tradeoff: Higher visual clarity. Session persistence (teammates survive terminal closure). More complex setup.

**Variant 3: Split-Pane Mode (iTerm2)**

macOS-only. Uses iTerm2 Python API and `it2` CLI. Functionally equivalent to tmux variant.

**Variant 4: Hub-and-Spoke with Delegate Mode**

Lead operates in coordination-only mode (Shift+Tab to enter delegate mode). Lead cannot implement — restricted to spawning, messaging, task management, and synthesizing results. All work done by teammates.

This is closest to Bulwark's current orchestrator pattern (orchestrator never implements; agents do the work).

**Variant 5: Peer Deliberation Mode**

Teammates are explicitly prompted to challenge each other's findings. The lead spawns researchers with instruction to message rivals and contest hypotheses. This "adversarial" pattern is the primary differentiator from Task tool sub-agents — sub-agents cannot do this.

Example from official docs: "Spawn 5 agent teammates to investigate different hypotheses. Have them talk to each other to try to disprove each other's theories, like a scientific debate."

**Confidence**: HIGH for variants 1-4; MEDIUM for variant 5 (well-documented but experimental, stability unknown)
**Evidence**: Official docs, GitHub issue #24384, ZoranSpirkovski repository model selection table

---

### Applicability to Bulwark Skills

#### P5.13 — plan-creation (HIGH applicability)

The task brief explicitly states: "Multi-agent research orchestration using agent teams." P5.13 is the canonical Agent Teams implementation target in Bulwark.

The planned output is: high-level plan input → detailed implementation plan. The natural Agent Teams pattern:
- Lead receives a high-level description of work
- Spawns specialized researcher teammates: domain expert, risk analyst, dependency mapper, prior art investigator, contrarian
- Each teammate independently researches one dimension, contributes to the shared task list
- Teammates can message each other to challenge assumptions (Peer Deliberation variant)
- Lead synthesizes findings into a task-brief formatted output

This is structurally identical to bulwark-research (5 Sonnet viewpoints in parallel) but with genuine peer-to-peer messaging capabilities that the current Task tool implementation cannot support. The Agent Teams version would allow the contrarian teammate to directly challenge the domain expert's findings mid-execution, producing stronger synthesis.

**Recommendation**: P5.13 should use Agent Teams with in-process mode (no tmux dependency), delegate mode for the lead, and 5 specialist teammates with explicit challenge prompts.

#### code-review — NOT recommended for migration

Current: 4-agent pipeline (Security, Type Safety, Standards, Architecture) via Task tool.

Agent Teams would not improve this. The 4 reviewers do not need to communicate with each other — they review the same artifact from different lenses and report back. Sequential synthesis by the lead is appropriate. Adding Agent Teams adds coordination overhead and token cost (~5-7x) with no benefit. The current Task tool approach is correct.

If a review variant were built where reviewers challenged each other's findings (e.g., Security reviewer argues with Architecture reviewer about a proposed mitigation), Agent Teams would then be appropriate. But the current use case does not require it.

#### test-audit — NOT recommended for migration

Current: Multi-stage pipeline with AST scripts + LLM classification sub-agents.

The pipeline is inherently sequential (AST analysis → classification → audit → synthesis). Teammates cannot parallelize sequential dependency chains. The existing sub-agent isolation already handles context management correctly. Agent Teams would add overhead with no benefit.

#### bulwark-research — NOT recommended for migration

Current: 5 Sonnet agents in parallel (Direct Investigation, Practitioner, Contrarian, First Principles, Historical) via Task tool.

The current design intentionally prevents cross-contamination between viewpoints — each agent forms its own independent assessment before synthesis. Adding peer messaging would allow early viewpoints to anchor later ones (anchoring bias), degrading the independent-assessment value. The Task tool approach is architecturally correct for this use case.

The only scenario where Agent Teams would improve bulwark-research is the "Evaluate" phase of the Research-Evaluate-Deepen process — where agents are explicitly asked to challenge each other's initial findings. This is currently done sequentially by the orchestrator. A future extension could spawn evaluation teammates to do this in parallel.

#### bulwark-brainstorm — NOT recommended for migration (but watch P5.13 as a pattern)

Current: 5 Opus agents in sequence (SME → PM → Architect → Dev Lead → Critic).

Sequential role progression with context handoff is the design intent — each role builds on the previous. Parallelizing with Agent Teams would lose this deliberate sequencing. In-sequence is correct.

The Critic role in brainstorm benefits specifically from having read all prior roles' outputs. This requires sequential context accumulation that Agent Teams (independent context windows) do not support.

#### P5.3 — continuous-feedback (LOW applicability)

P5.3 captures learnings and proposes enhancements. Ralph Loops research already found this has poor fit for Ralph. Agent Teams fit is also LOW: the skill is designed for periodic batch improvement (learning capture → enhancement proposal → validate → apply), not parallel research. A single agent executing this workflow is sufficient.

#### P5.4 — skill-creator (LOW applicability)

P5.4 creates skills with 4-iteration Ralph loop guidance. Agent Teams would add no value over a single capable agent with Ralph loop structure guidance. The structural validation (anthropic-validator) is sequential by nature. Low applicability.

#### P5.5 — agent-creator (LOW applicability)

Same reasoning as P5.4. Structural generation and validation is sequential. Low applicability.

**Confidence for applicability analysis**: HIGH for P5.13 (explicit task brief alignment); HIGH for code-review/test-audit/bulwark-research/bulwark-brainstorm (clear negative evidence); MEDIUM for P5.3/P5.4/P5.5 (task briefs define them as Ralph-oriented, not Agent Teams-oriented)
**Evidence**: tasks.yaml task definitions, official Agent Teams use case documentation, Ralph Loops synthesis

---

### Agent Teams vs Task Tool Sub-Agents

The fundamental architectural difference:

| Dimension | Task Tool Sub-Agents | Agent Teams Teammates |
|-----------|---------------------|----------------------|
| Context | Own window; results return to caller | Own window; fully independent |
| Communication | Report back to main agent only (one-way) | Direct peer-to-peer via mailbox (bidirectional) |
| Coordination | Main agent manages all sequencing | Shared task list; teammates self-claim |
| Persistence | Terminates when task complete | Persists until explicit shutdown request |
| Visibility | Lead sees result summary | Lead sees inbox messages; stdout not shared |
| Task dependencies | Manually managed by orchestrator | Auto-unblocking via task dependency graph |
| Token cost | Lower; results summarized back | Higher; each teammate is a full Claude instance |
| Best for | Focused tasks where only the result matters | Complex work requiring discussion and collaboration |
| Nested spawning | Allowed (sub-agents can spawn sub-agents) | Prohibited (only team lead can manage team) |

**The critical distinguishing capability**: In sub-agent mode, a security reviewer and an architecture reviewer complete their work independently and report to the lead. They never interact. In Agent Teams, the security reviewer can send a message to the architecture reviewer saying "your proposed refactor creates an injection surface at line 47 — how do you want to handle it?" The architecture reviewer processes this and either revises their finding or defends it. The lead sees both messages and synthesizes a richer result.

**When to use Task tool sub-agents** (Bulwark current approach):
- Tasks with clear, independent scope and no need for cross-agent deliberation
- Sequential pipelines where each stage depends on the previous stage's complete output
- Cost-sensitive operations where ~7x token overhead is not justified
- Production stability required (Agent Teams are experimental)

**When to use Agent Teams**:
- Tasks where teammates need to challenge each other's findings
- Parallel work with genuine self-coordination needs (e.g., multiple features being developed simultaneously)
- Plan-creation workflows where competing research angles should debate
- Work where 5-6 tasks per teammate with self-claiming is more efficient than manual orchestration

**Confidence**: HIGH
**Evidence**: Official docs comparison table and "When to use" guidance, GitHub gist internal architecture details

---

### Agent Teams vs Ralph Loops — Coexistence

Ralph Loops (prior Bulwark research, Session 61) and Agent Teams solve orthogonal problems:

| Dimension | Ralph Loops | Agent Teams |
|-----------|-------------|-------------|
| Problem solved | Context degradation across iterations | Role specialization + parallel exploration |
| Context model | Fresh per iteration; filesystem as memory | Persistent per teammate; independent windows |
| Communication | Via filesystem only (no peer messaging) | Direct peer-to-peer via mailbox |
| Coordination pattern | Sequential, disk-state driven | Parallel, shared task list |
| Best for | Implementation with automated test backpressure | Research, review, parallel exploration |
| Cost | Baseline for sequential work | 5-7x per additional teammate |
| Stability | High (deterministic, file-backed state) | Experimental (known limitations) |

**Coexistence Assessment**

Architecturally possible: A Ralph loop runs `claude` (a single Claude Code session). That session could be a team member. Nothing in the Agent Teams protocol prevents this technically.

Practically: Combining them doubles overhead — you pay both Agent Teams coordination overhead AND Ralph iteration overhead simultaneously. This compounds cost and adds two sources of failure (coordination failures from Agent Teams + specification errors amplified by Ralph). The prior synthesis labeled this "Teams of Ralphs" and categorized it as a specific expensive pattern, not general coexistence.

**Recommended coexistence pattern for Bulwark**:

| Use Case | Approach | Rationale |
|----------|----------|-----------|
| P5.13 plan-creation | Agent Teams | Peer deliberation is the core value |
| P5.4 skill-creator | Ralph Loops | Structural validation with automated backpressure |
| P5.5 agent-creator | Ralph Loops | Same as skill-creator |
| code-review | Task tool sub-agents (current) | Sequential lenses, no peer deliberation needed |
| test-audit | Task tool sub-agents (current) | Sequential pipeline, not parallelizable |
| bulwark-research | Task tool sub-agents (current) | Independent viewpoints intentional |
| bulwark-brainstorm | Task tool sub-agents (current) | Sequential role progression required |
| P5.3 continuous-feedback | Single agent | Too lightweight for either approach |

**Do NOT attempt hybrid** (Agent Team orchestrating Ralph loop teammates) without empirical validation on a low-stakes task. Both are experimental/complex; combining them before either is validated in production adds compounding risk.

**Confidence**: HIGH for the "orthogonal problems" assessment (corroborated by Ralph Loops synthesis, Official Agent Teams docs, and prior art research); MEDIUM for the specific coexistence recommendation table (architectural reasoning is sound but untested in Bulwark specifically)
**Evidence**: Ralph Loops synthesis (logs/research/ralph-loops/synthesis.md), Official Agent Teams docs, Agyn arxiv paper (2602.01465v2) for general multi-agent coordination patterns

---

### WSL2 and Tmux Considerations

**The Fundamental Constraint**

Split-pane display mode requires either tmux or iTerm2. The official docs note: "tmux has known limitations on certain operating systems and traditionally works best on macOS." Windows Terminal is NOT a supported backend (GitHub issue #24384, filed Feb 9, 2026, open). Ghostty, VS Code integrated terminal, and Windows Terminal are all unsupported for split-pane mode.

**Detection Order**

Claude Code auto-detects the execution environment:
```
iTerm2 (checks $ITERM_SESSION_ID) → tmux (checks $TMUX) → in-process fallback
```

The `teammateMode` setting defaults to `"auto"` which uses split panes inside an existing tmux session and falls back to in-process otherwise.

**WSL2 + Tmux: The Working Solution**

Running `claude` inside a tmux session in WSL2 triggers the tmux split-pane backend automatically. Environment variable `$TMUX` is set by tmux, which Claude Code detects.

Practical setup: Install tmux in WSL2 (`apt install tmux`), start a tmux session, then invoke `claude` — Agent Teams will use split-pane mode.

**Known tmux Issues on WSL2**

From Ralph Loops research (not Agent Teams specific, but applies):
- `wslvar` and `wslpath` utilities do not work properly within tmux sessions on WSL2
- Windows SSH server conflicts: if Windows SSH is enabled, tmux sessions are invisible from SSH into WSL2
- NAT networking can cause IDE detection failures; use `mirrored` mode on Win11 22H2+

From GitHub issue #23615 (Agent Teams specific): "Agent teams should spawn in new tmux window, not split current pane." This is an open issue — the current split-pane behavior may occupy the current window in unexpected ways.

**In-Process Mode: The Simpler Alternative**

For Bulwark's use cases, in-process mode may be sufficient and is recommended for initial adoption:
- Works in any terminal including WSL2 without tmux
- Use Shift+Up/Down to navigate between teammates
- No setup overhead
- Avoids all tmux-specific issues

The tradeoff: less visual clarity — you cannot watch all teammates working simultaneously. For code review or plan-creation tasks where the lead synthesizes results at the end rather than monitoring real-time, this tradeoff is acceptable.

**Recommendation for Bulwark**

Start with in-process mode for P5.13 development and testing. If real-time visibility becomes a genuine need (not a preference), add tmux. The `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` flag and in-process mode are the minimum viable configuration; tmux adds visual benefits but is not required for functionality.

Critical note: Agent Teams are experimental and have a known no-session-resumption limitation. `/resume` does not restore in-process teammates after a session ends. For Bulwark's workflow (user-invoked, short-lived research tasks), this is acceptable — the session completes in one run. For long-running overnight automation, this limitation would be blocking.

**Confidence**: HIGH for detection mechanism and in-process fallback; MEDIUM for WSL2 + tmux stability (no direct empirical testing; inferred from Ralph Loops WSL2 research + GitHub issue tracking)
**Evidence**: Official docs display mode section, GitHub issue #24384 (Windows Terminal support), GitHub issue #23615 (tmux window vs pane), Ralph Loops WSL2 synthesis

---

## Confidence Notes

**LOW confidence findings** (3 total):

1. **Exact token cost multiplier**: Official docs say ~7x in plan mode; blog sources say ~5x. The discrepancy likely reflects different measurement scenarios (plan mode vs. active implementation mode). Safe range: 5-7x per active teammate. Actual cost depends on task complexity, spawn prompt size, and whether teammates use extended thinking. Testing on a real P5.13 run would give Bulwark-specific numbers.

2. **Peer deliberation effectiveness**: The "competing hypotheses" pattern (teammates actively challenging each other) is described in official docs as a primary differentiator, but no benchmark data exists for how much this improves output quality vs. independent parallel analysis followed by lead synthesis. The Agyn arxiv paper shows 7.4% improvement of 4-agent over single-agent for software engineering tasks, but that's a different domain and team structure.

3. **WSL2 + tmux Agent Teams stability**: Inferred from Ralph Loops WSL2 research and GitHub issues, not from direct Agent Teams + WSL2 empirical testing. The combination is supported by documentation but not validated in Bulwark's environment. First run of P5.13 in Agent Teams mode should be treated as a validation exercise.

**What would increase confidence**:
- One live run of Agent Teams on a P5.13-equivalent task (plan-creation) in WSL2 in-process mode, noting any errors, token costs, and quality delta vs. bulwark-research output
- Direct access to the vibecodecamp reverse-engineered article (403 blocked) — may contain internal architecture details not in official docs
- Stability testing: does the no-session-resumption limitation affect P5.13 use cases in practice?

---

## Sources

Primary:
- [Claude Code Agent Teams — Official Documentation](https://code.claude.com/docs/en/agent-teams)
- [Claude Code Cost Management — Official Documentation](https://code.claude.com/docs/en/costs)
- [GitHub Issue #24384: Windows Terminal split-pane backend](https://github.com/anthropics/claude-code/issues/24384)
- [GitHub Issue #23615: Agent teams tmux window vs pane](https://github.com/anthropics/claude-code/issues/23615)

Secondary:
- [Claude Code Swarm Orchestration Skill — kieranklaassen gist](https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea)
- [Creating Agent Teams — ZoranSpirkovski repository](https://github.com/ZoranSpirkovski/creating-agent-teams)
- [Claude Code Agent Teams — addyosmani.com](https://addyosmani.com/blog/claude-code-agent-teams/)
- [Agyn Multi-Agent System — arxiv 2602.01465v2](https://arxiv.org/html/2602.01465v2)
- [Agent Teams Just Shipped — charlesjones.dev](https://charlesjones.dev/blog/claude-code-agent-teams-vs-subagents-parallel-development) (403, unavailable)
- [From Tasks to Swarms — alexop.dev](https://alexop.dev/posts/from-tasks-to-swarms-agent-teams-in-claude-code/) (inaccessible)

Internal:
- /mnt/c/projects/the-bulwark/logs/research/ralph-loops/synthesis.md
- /mnt/c/projects/the-bulwark/plans/tasks.yaml (P5.3, P5.4, P5.5, P5.13 task definitions)
