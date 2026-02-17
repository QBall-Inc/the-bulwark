---
viewpoint: Practitioner Perspective
topic: "Claude Code Agent Teams — Multi-Agent Orchestration Patterns"
confidence_summary:
  high: 8
  medium: 4
  low: 2
key_findings:
  - "Agent Teams are experimental (Feb 2026 release) and require CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 to activate; this is not a stable production API."
  - "Token cost is approximately 2x subagents for equivalent team size; a 3-teammate team costs ~800k tokens vs ~440k for 3 Task-tool subagents."
  - "Split-pane mode does NOT work with Windows Terminal or VS Code's integrated terminal; WSL2 users on Windows Terminal must use in-process mode or install tmux inside WSL2."
  - "Session resumption is broken for in-process teammates: /resume and /rewind orphan all teammates, requiring manual re-spawn."
  - "Bulwark's current Task-tool patterns (parallel isolated specialists reporting to orchestrator) are the right tool for the current architecture; Agent Teams add cost without coordination benefit for patterns that do not require peer-to-peer debate."
---

# Agent Teams — Practitioner Perspective

## Summary

Claude Code Agent Teams (released February 2026 as an experimental feature) enable peer-to-peer coordination between parallel Claude instances via a shared task list and mailbox system. Practitioners find clear value in adversarial/debate patterns and cross-layer parallelism but report significant operational roughness — session resumption failures, task status lags, and token costs roughly 2x higher than equivalent Task-tool subagents. For Bulwark's existing skills, the Task tool remains the appropriate choice; Agent Teams would add value only if skills are redesigned to require genuine inter-agent negotiation, which current skill designs do not need.

---

## Research Process Summary (Research-Evaluate-Deepen)

**Initial research** drew on official docs (code.claude.com/docs/en/agent-teams), the ZoranSpirkovski plugin repo, alexop.dev's Task-to-Swarms comparison, the aicosts.ai token-cost postmortem, Addy Osmani's practitioner post, the claudefa.st guide, and the paddo.dev reverse-engineering article.

**Evaluate**: All sources agreed on token cost premium and experimental status. Divergence appeared on WSL2/tmux: some sources said "tmux works cross-platform," others pointed to the GitHub issues (#24384, #23615) showing Windows Terminal is explicitly unsupported.

**Gaps identified**: (1) No practitioner data on Agent Teams specifically for Bulwark-style code-review orchestration. (2) No data on `/mnt/c/` path interaction with Agent Teams coordination files. (3) No failure postmortems specific to Agent Teams (most cost data is subagent-focused).

**Deepen**: The alexop.dev Task-vs-Teams article gave concrete token comparisons. GitHub issues #24384 and #23615 confirmed Windows Terminal is an open feature request, not a temporary gap. The paddo.dev reverse-engineering article confirmed the in-process backend is the fastest and most stable mode but lacks session persistence.

**Reconcile**: Initial assessment ("Agent Teams add clear value for parallel work") was refined to: "Agent Teams add clear value specifically for tasks requiring peer-to-peer debate or mutual discovery. For tasks where a parent orchestrator controls parallel isolated workers — which describes most of Bulwark's current skills — the Task tool is better on all dimensions: cost, simplicity, reliability, and resumability."

---

## Detailed Analysis

### Real-World Adoption Patterns

**Who uses Agent Teams and for what**: Adoption is early-stage. The primary reported use cases are (1) parallel code review with specialized lenses (security / performance / test coverage), (2) adversarial debugging where teammates test competing root-cause hypotheses, and (3) cross-layer feature implementation where frontend, backend, and test files have no shared ownership. The most dramatic published case is Anthropic's own 16-agent C compiler project (~100,000 lines of Rust, ~2,000 sessions, approximately $20,000 in API costs), though this predates the official Agent Teams release and used predecessor orchestration patterns.

Community adoption skews toward solo developers and small teams exploring the feature, not production engineering teams. The experimental flag requirement and known limitations around session resumption make it unsuitable as a load-bearing workflow component in team environments as of February 2026.

**Project types**: Research, code review, and debugging are the strongest fits because these tasks have naturally independent subtasks and benefit from independent perspectives. Implementation parallelism (building multiple modules simultaneously) works when file ownership is strict and clean; it fails when teammates drift toward shared files.

**Confidence**: HIGH
**Evidence**: Anthropic official docs; Addy Osmani practitioner post; claudefa.st guide; nxcode.io guide; the C compiler case from search results

---

### Setup and Management

**Enabling**: Set `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in `~/.claude/settings.json` under the `env` key. Alternatively export it in `.bashrc`/`.zshrc`. Without this flag, all Agent Teams functionality is hidden.

**Display mode selection**: Two modes exist. In-process (default) runs all teammates inside the main terminal with `Shift+Up/Down` to switch. Split-pane mode spawns each teammate into a separate tmux pane. Set via `"teammateMode": "in-process" | "tmux" | "auto"` in `settings.json` or pass `--teammate-mode` per session.

**Delegate mode**: Press `Shift+Tab` to cycle the lead into coordination-only mode, preventing it from implementing tasks itself. Without this, the lead often begins coding instead of waiting for teammates — this is the most commonly reported coordination failure mode.

**Plan approval**: Teammates can be required to get lead approval before implementing, enabling a staged workflow (plan-only mode until approved, then full execution). This is useful for risky or ambiguous tasks.

**Team config storage**: `~/.claude/teams/{team-name}/config.json` and `~/.claude/tasks/{team-name}/`. These live on the Linux native filesystem in WSL2, not on `/mnt/c/`. This is important: coordination primitives are fast regardless of project file location.

**Specifying models**: Natural language works — "Create a team with 4 teammates using Sonnet for each." The ZoranSpirkovski plugin formalizes this with explicit role → model tiers: Opus for orchestrator, Sonnet for implementation, Haiku for search/grep.

**Confidence**: HIGH
**Evidence**: Official docs; claudefa.st; marc0.dev; ZoranSpirkovski plugin repo

---

### Practical Gotchas and Debugging

**1. Lead implements instead of delegating** (most common failure): Without delegate mode, the lead starts coding directly rather than waiting for teammates. Use `Shift+Tab` or explicitly instruct "wait for teammates to complete tasks before proceeding."

**2. Session resumption is broken for in-process teammates**: `/resume` and `/rewind` do not restore teammates. After a session restart, the lead will attempt to message teammates that no longer exist. Workaround: spawn a fresh team after resuming. This is a documented limitation with no current fix.

**3. Task status lags**: Teammates sometimes fail to mark tasks as completed, blocking dependent tasks. The wait before assuming a task is stuck is around 10-15 seconds; then verify actual completion and nudge manually or tell the lead to mark it complete.

**4. File ownership conflicts**: Two teammates writing the same file results in last-write-wins overwrite. This is silent data loss. Mitigation: strict file partition by teammate before spawning; each teammate should own a non-overlapping set of files/directories.

**5. Orphaned tmux sessions**: If a tmux session persists after team end, use `tmux ls` and `tmux kill-session -t <name>`. The lead must run cleanup, not teammates; teammate-initiated cleanup may leave resources in an inconsistent state.

**6. Permission prompt flood**: Teammate permission requests bubble up to the lead, which interrupts coordination. Pre-approve common operations in `settings.json` permissions before spawning to reduce friction.

**7. Token cost explosion risk**: The aicosts.ai postmortem documents a developer who triggered 49 parallel subagents via a slash command and hit 887,000 tokens/minute. Initialization alone costs 5,000-50,000 tokens per agent. With Agent Teams, each teammate carries a full independent context window — broadcasted messages are particularly expensive because they multiply across all teammates. Use targeted `write` over `broadcast`.

**8. One team per session**: A lead can only manage one team at a time. Clean up the current team before starting another.

**9. No nested teams**: Teammates cannot spawn their own teams. This prevents recursive cost explosions but also limits hierarchical orchestration.

**10. Task count guideline**: 5-6 tasks per teammate keeps everyone productive without excessive idle time waiting for work.

**Confidence**: HIGH for items 1-7 (documented officially or confirmed in multiple practitioner sources); MEDIUM for items 8-10 (officially documented but limited failure case data)
**Evidence**: Official docs; Addy Osmani; alexop.dev; claudefa.st; aicosts.ai postmortem

---

### Applicability to Bulwark Skills

**Current skills using Task tool (code-review, test-audit, bulwark-research, bulwark-brainstorm, bulwark-implementer)**:

These skills use the Task tool's orchestrator-controls-parallel-workers pattern. Sub-agents receive structured prompts, execute independently, and report structured output to the orchestrator. There is no need for sub-agents to communicate with each other mid-execution.

This pattern maps exactly to what the official docs and multiple practitioners identify as the subagent use case, not the Agent Teams use case. The distinction: subagents "report results back to the main agent only" and are appropriate for "focused tasks where only the result matters." Agent Teams add value only when "teammates need to share findings, challenge each other, and coordinate on their own."

**Specific assessment per skill**:

- **code-review (4 parallel Sonnet agents: Security, Type Safety, Standards, Architecture)**: Each reviewer operates on the same file set but applies an independent lens. There is no need for them to negotiate mid-execution — the orchestrator synthesizes results. Task tool is the right choice. Agent Teams would add ~2x token cost with no benefit.

- **test-audit (multi-stage AST + LLM pipeline)**: Sequential pipeline with dependency between stages. Agent Teams are explicitly a poor fit for sequential tasks with dependencies (official docs). Task tool is correct.

- **bulwark-research (5 parallel Sonnet agents)**: Same as code-review — parallel isolated perspectives, orchestrator synthesizes. Task tool is correct. The one scenario where Agent Teams might add value: if sub-agents were explicitly designed to challenge each other's findings mid-research (like the competing-hypotheses debugging pattern). Current implementation doesn't do this; adding it would require rearchitecting the skill.

- **bulwark-brainstorm (5 Opus agents in sequence, Propose-Challenge-Refine)**: This skill's Critic role explicitly challenges prior output. The sequential design means Agent Teams wouldn't help (sequential tasks are poor Agent Teams candidates). However, if the Propose, Challenge, and Refine phases were decomposed into peer-coordinating teammates rather than sequential agents, the debate dynamic could improve. This would require significant rearchitecting and would roughly double token costs.

- **bulwark-implementer (Opus sub-agent for code writing)**: Single-agent task. No parallelism applicable.

**Planned skills**:

- **P5.3 (continuous-feedback — periodic batch improvement)**: Likely involves analyzing code over time and producing improvement suggestions. If multiple feedback reviewers run in parallel on different modules, Task tool is sufficient. Agent Teams only helps if reviewers need to cross-reference findings.

- **P5.4 (skill-creator)**: Single-agent creative/implementation task. No benefit from Agent Teams.

- **P5.5 (agent-creator)**: Same as P5.4.

- **P5.13 (plan-creation)**: If plan creation involves multiple perspectives (feasibility analysis, risk assessment, dependency mapping), this is a candidate for either parallel Task-tool agents or Agent Teams. Agent Teams would be valuable only if the planners need to negotiate across their perspectives — e.g., a feasibility agent challenging the scope proposed by a requirements agent. Without inter-agent negotiation, Task tool is sufficient.

**Confidence**: MEDIUM (inference from official documentation and practitioner patterns applied to Bulwark's specific architecture; no direct testing of Bulwark skills under Agent Teams)
**Evidence**: alexop.dev Task-vs-Swarms; official docs comparison table; claudefa.st coordination model description

---

### Features That Benefit from Agent Teams vs Task Tool

**What genuinely benefits from Agent Teams**:

1. **Adversarial debate patterns**: The competing-hypotheses debugging example is the strongest documented case. When teammates are explicitly tasked with disproving each other's theories, Agent Teams' direct messaging enables real-time challenge-response that the Task tool cannot replicate (Task tool sub-agents never see each other's output).

2. **Cross-layer implementation with dependencies**: When backend and frontend work must interlock mid-execution (e.g., "the API teammate should tell the frontend teammate when the endpoint contract is finalized"), direct messaging enables handoffs that the Task tool cannot do without going through the parent.

3. **Plan approval gates as quality enforcement**: The TeammateIdle and TaskCompleted hooks provide quality gates that fire when teammates finish work. This is Agent Teams-specific functionality not available with the Task tool.

4. **Human-in-the-loop checkpoints at teammate level**: Users can message individual teammates directly without going through the lead. This is useful for redirecting a specific reviewer mid-flight.

**What works fine with the Task tool (and doesn't need Agent Teams)**:

1. Parallel independent reviewers whose outputs are synthesized only at the end — this describes code-review, bulwark-research.
2. Sequential pipeline stages — this describes test-audit.
3. Any pattern where the orchestrator controls flow entirely — this describes all current Bulwark skills.
4. Single-focus sub-agents with structured output contracts — bulwark-implementer.

**Token cost differential** (from alexop.dev concrete comparison):
- 3 Task-tool subagents: ~440k tokens (~80k each + orchestrator overhead)
- 3 Agent teammates: ~800k tokens (~200k each)
- Ratio: Agent Teams cost approximately 1.8x more for equivalent team sizes

**Confidence**: HIGH for the functional distinction; MEDIUM for token numbers (one source, plausible methodology)
**Evidence**: alexop.dev; official docs comparison table; GitHub gist on TeammateTool primitives; claudefa.st

---

### WSL2 and Tmux Practical Considerations

**Critical constraint**: Split-pane mode is not supported in Windows Terminal. This is explicitly documented in the official Claude Code docs: "Split-pane mode isn't supported in VS Code's integrated terminal, Windows Terminal, or Ghostty." There is an open feature request for Windows Terminal support (GitHub issue #24384). For Bulwark's WSL2 environment, this means:

- **Default/safe choice**: Use `"teammateMode": "in-process"` in `settings.json`. This works in any terminal including Windows Terminal running WSL2. All teammates run in the main terminal; use `Shift+Up/Down` to switch between them.
- **Split-pane on WSL2**: Possible, but requires running tmux inside WSL2 (not Windows Terminal's native tabs). Install tmux in Ubuntu via `sudo apt install tmux`, then launch Claude Code from within a tmux session. The `auto` mode will detect the tmux session and use split panes. This gives real-time pane visibility.

**Tmux setup on WSL2** (from the Zenn WSL+tmux guide):
1. Install tmux: `sudo apt install tmux`
2. Configure `~/.tmux.conf` with sensible defaults
3. Launch a tmux session: `tmux new -s main`
4. From inside tmux, run `claude`
5. Agent Teams auto-detects tmux and will use split panes when `teammateMode` is `auto` or `tmux`
6. Set `"CLAUDE_CODE_SPAWN_BACKEND": "tmux"` in settings.json as an additional configuration point

**GitHub issue #23615**: Reports that Agent Teams spawn new tmux panes by splitting the current window, breaking existing layouts and causing command corruption when multiple agents start simultaneously. This is an open bug as of February 2026. The workaround is to launch Agent Teams from a dedicated tmux session separate from working sessions.

**Project path performance**: Bulwark's code lives on `/mnt/c/` (NTFS via WSL2). Agent Teams coordination files (task lists, mailboxes, team config) live at `~/.claude/teams/` which is on the native Linux ext4 filesystem. This means coordination primitives are fast. The performance penalty from `/mnt/c/` affects only file reads/writes to the actual codebase, which sub-agents and teammates both experience equally. Agent Teams does not make `/mnt/c/` path issues better or worse.

**Tmux usage patterns with Agent Teams on WSL2**:
- Launch from `~/projects/the-bulwark` (symlink or `cd` from the native filesystem) rather than `/mnt/c/projects/the-bulwark` for better tmux responsiveness
- If project must stay on `/mnt/c/`, use a dedicated tmux window for Agent Teams to isolate layout disruption from the issue #23615 pane-splitting behavior
- The `tmux-resurrect` plugin (mentioned in the Zenn guide) can persist tmux sessions across restarts, but it will NOT restore Claude Code sessions or Agent Teams state — that remains a Claude Code limitation

**Confidence**: HIGH for the Windows Terminal incompatibility (two GitHub issues + official docs); MEDIUM for the tmux+WSL2 workaround (confirmed working by the Zenn article but limited WSL2-specific failure case data); LOW for the `/mnt/c/` path interaction (inference from architecture analysis, no direct testing)
**Evidence**: Official docs limitations section; GitHub issues #24384, #23615, #25396; Zenn WSL+tmux guide; marc0.dev; geeky-gadgets.com

---

## Confidence Notes

**LOW confidence findings** (two):

1. **Bulwark-specific applicability assessments (P5.3, P5.4, P5.5, P5.13)**: These assessments are inferences from applying the official Agent Teams use-case framework to planned skill designs. No practitioner has specifically tested Bulwark-class pipeline skills against Agent Teams. The fundamental patterns are clear, but edge cases (e.g., whether plan-creation benefits from peer negotiation) require empirical testing.

2. **`/mnt/c/` path interaction with Agent Teams**: No source specifically addressed NTFS-via-WSL2 path performance in the context of Agent Teams. The analysis relies on understanding that coordination primitives use `~/.claude/` (native Linux FS) while code access uses `/mnt/c/` (NTFS). This is architecturally sound but untested.

**What would increase confidence**:
- Direct testing of code-review and bulwark-research skills under Agent Teams to measure actual token delta and output quality difference
- A dedicated Agent Teams session on Bulwark to observe task status lag in practice
- Testing tmux split-pane mode from inside WSL2 Ubuntu (not Windows Terminal) to confirm the workaround reliability

---

## Sources

- [Official Agent Teams Documentation](https://code.claude.com/docs/en/agent-teams)
- [ZoranSpirkovski creating-agent-teams plugin](https://github.com/ZoranSpirkovski/creating-agent-teams)
- [From Tasks to Swarms: Agent Teams in Claude Code — alexop.dev](https://alexop.dev/posts/from-tasks-to-swarms-agent-teams-in-claude-code/)
- [Claude Code Swarm Orchestration Skill — GitHub Gist (kieranklaassen)](https://gist.github.com/kieranklaassen/4f2aba89594a4aea4ad64d753984b2ea)
- [Claude Code Swarms — Addy Osmani](https://addyosmani.com/blog/claude-code-agent-teams/)
- [Agent Teams: Multi-Session Orchestration — claudefa.st](https://claudefa.st/blog/guide/agents/agent-teams)
- [Claude Code Subagent Cost Explosion: 887K Tokens/Min — aicosts.ai](https://www.aicosts.ai/blog/claude-code-subagent-cost-explosion-887k-tokens-minute-crisis)
- [Claude Code: Multiple AI Agents, One Repo — marc0.dev](https://www.marc0.dev/en/blog/claude-code-agent-teams-multiple-ai-agents-working-in-parallel-setup-guide-1770317684454)
- [Claude Code Agent Teams Hidden Swarm — paddo.dev](https://paddo.dev/blog/claude-code-hidden-swarm/)
- [Building Ultimate Dev Environment: WSL, VSCode, tmux, Claude Code — Zenn](https://zenn.dev/kosk_t/articles/wsl-vscode-tmux-claude-code-setup?locale=en)
- [Agent Teams Token Usage — Geeky Gadgets](https://www.geeky-gadgets.com/agent-teams-token-usage/)
- [Claude Code Agent Teams Workflows — Geeky Gadgets](https://www.geeky-gadgets.com/claude-code-agent-team-guide/)
- [NxCode Agent Teams Guide 2026](https://www.nxcode.io/resources/news/claude-agent-teams-parallel-ai-development-guide-2026)
- [GitHub Issue #23615: Agent teams spawn in wrong tmux pane](https://github.com/anthropics/claude-code/issues/23615)
- [GitHub Issue #24384: Add Windows Terminal as split-pane backend](https://github.com/anthropics/claude-code/issues/24384)
- [GitHub Issue #25396: Spawn teammates in separate tmux windows](https://github.com/anthropics/claude-code/issues/25396)
