# subagent-output-templating

Provides the standard YAML log format, task completion report structure, and summary constraints that all Bulwark sub-agents use when writing output.

## Invocation and usage

```
/the-bulwark:subagent-output-templating
```

This skill is not typically invoked directly. See "Auto-invocation" below.

### Auto-invocation

Per Rules.md SA2, every sub-agent that writes output loads this skill automatically. It governs three things:

- **Log file format**: YAML output written to `logs/{agent-name}-{YYYYMMDD-HHMMSS}.yaml`, covering metadata, goal, completion report, pipeline suggestions, summary, and diagnostics.
- **Task completion report**: A structured WHY/WHAT/TRADE-OFFS/RISKS block that each sub-agent appends to its log. Documents the problem, changes made, trade-offs accepted, and forward-looking risks.
- **Summary constraints**: The summary field is capped at 100-300 tokens. It is the only content returned to the main thread. Full reasoning stays in the log.

When a custom agent definition specifies its own output paths and format, those take precedence over this skill's defaults. When no agent-specific format is defined, this skill's format applies.

## Who is it for

- Orchestrators who need to parse sub-agent results consistently across pipeline stages.
- Anyone writing a new Bulwark skill or agent that spawns sub-agents.
- Developers auditing sub-agent behavior via log files.

## How it works

Each sub-agent writes a YAML log file with a required structure: a metadata block (agent name, timestamp, model, task ID, duration), the verbatim goal from the prompt, a completion report, an optional pipeline suggestions block for code-writing agents, a summary, and a diagnostics block.

The completion report follows WHY/WHAT/TRADE-OFFS/RISKS. WHY documents the problem and root cause. WHAT lists every file changed with line ranges. TRADE-OFFS names what was gained and what it cost. RISKS assigns severity (low, medium, high, critical) and mitigation to each forward-looking concern.

Code-writing agents that receive pipeline suggestions from `implementer-quality.sh` include those suggestions in both the log and the summary, using mandatory language so the orchestrator acts on them per SA6. Read-only agents omit the pipeline suggestions block.

Diagnostics are written to `logs/diagnostics/{agent-name}-{YYYYMMDD-HHMMSS}.yaml` and record model requested vs. actual, context type (main or forked), hooks fired, execution time, and completion status. These fields support automated behavioral testing without mocks.
