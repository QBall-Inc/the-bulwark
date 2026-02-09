
### Project Rules (Bulwark-Specific)

These extend Rules.md for this project.

#### Modes of Operation

- **Implementer Mode**: Primary model directly implements all deliverables (OR1)
- **Orchestrator Mode**: Primary model orchestrates sub-agents for review/audit (OR2-OR4, SA1-SA6)

#### Orchestrator Rules (OR)

OR1: Implementation work is always performed by an Opus-class model — either the primary model directly or a dedicated Opus sub-agent (e.g., bulwark-implementer). Non-Opus sub-agents are for review, audit, and research only.

OR2: Sub-Agent Model Selection

When spawning sub-agents for review/audit/research:

| Complexity | Model | Use Cases |
|------------|-------|-----------|
| Simple | Haiku | Quick lookups, single-file reads |
| Standard | **Sonnet** (default) | Code review, test audit, research |
| Complex | Opus | Architecture review, novel problem analysis |

Default to Sonnet unless task clearly fits Simple or Complex.

OR3: Custom sub-agents specify their model in frontmatter. The Orchestrator respects this.

OR4: Use F# pipe syntax for workflow orchestration. Sequential by default; parallel execution supported where documented in pipeline-templates.

#### Sub-Agent Rules (SA)

SA1: All sub-agent invocations use the 4-part template:
1. **GOAL**: What success looks like
2. **CONSTRAINTS**: What cannot be done
3. **CONTEXT**: What the agent needs to know
4. **OUTPUT**: Expected deliverables and format

SA2: All sub-agent output MUST be written to the `logs/` directory. Main thread reads logs, not raw output.

- **When an agent definition specifies output paths and format**: The agent MUST use those exact paths and formats. No additional log files. For example, if the agent specifies `logs/debug-reports/{id}-{timestamp}.yaml`, that is the ONLY output file (plus any diagnostics path also specified). Do NOT also write a generic `.md` file.
- **When no output path is specified**: The agent MUST write output to `logs/{agent-name}-{timestamp}.md` as a fallback.

This is a closed loop: every sub-agent MUST produce a log artifact, and MUST produce exactly the artifacts specified - no more, no fewer.

SA3: Sub-agent results return as summaries only (findings, severity, next actions). Full reasoning stays in logs.

SA4: Complex workflows use F# pipe syntax. Each agent reads previous agent's log output.

SA5: Do not use `run_in_background: true` when spawning sub-agents. Retrieving background agent output via `TaskOutput` or `TaskStop` dumps the full transcript into parent context, causing token spikes. Foreground sub-agents return only their summary (per SA3) while full output goes to logs (per SA2).

SA6: Pipeline suggestions from code-writing sub-agents are **PRESUMED EXECUTE**. The orchestrator MUST run the suggested pipeline unless the user explicitly approves deferral. Orchestrator self-deferral is a rule violation.

- **Default action**: Execute the suggested pipeline immediately
- **Deferral**: Only permitted with explicit user approval. Ask the user: "Pipeline X was suggested for [files]. Execute or defer?"
- **Silent ignoring**: Rule violation
- **Self-rationalizing deferral** (e.g., "change is small", "not warranted"): Rule violation

#### Task Conventions

- Implementation plans: `plans/task-briefs/P{X}.{Y}-{name}.md`
- Debugging logs: `logs/debugging-{issue-id}.md`
- Session handoffs: `sessions/` using session-handoff skill
- Sub-agent logs: `logs/{agent-name}-{timestamp}.md` (fallback path per SA2)

#### Grounding Clause

Validate all new Claude Code assets (hooks, skills, agents, plugins, commands, MCP servers) using the `/anthropic-validator` skill.
