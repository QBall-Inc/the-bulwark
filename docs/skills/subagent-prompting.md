# subagent-prompting

Provides a standardized 4-part prompting structure (GOAL/CONSTRAINTS/CONTEXT/OUTPUT) and F# pipeline notation for orchestrating sub-agents.

## Invocation and usage

```
/the-bulwark:subagent-prompting
```

No arguments. The skill loads its template into context for use during sub-agent orchestration.

**Examples:**

```
/the-bulwark:subagent-prompting
```

Load the prompting template before designing a multi-agent pipeline. Use the 4-part structure to write each `Task()` invocation.

```
/the-bulwark:subagent-prompting
```

Reference during an active orchestration session to check model selection rules or pipeline notation before spawning the next stage.

### Auto-invocation

Per Rules.md SA1, any skill that spawns sub-agents must load `subagent-prompting` before writing `Task()` calls. Skills do this automatically. The template provides:

- The 4-part prompt structure every sub-agent invocation must follow.
- F# pipe notation for planning and documenting pipeline sequences.
- Model selection rules (Haiku for lookups, Sonnet for review, Opus for writing).
- Agent type selection: custom agent in `.claude/agents/` if one exists, otherwise `general-purpose`.

## Who is it for

- Skills that orchestrate multi-agent pipelines and need consistent prompt structure across every `Task()` call.
- Orchestrators designing new pipelines who want a reference for conditional branching, model selection, and output path conventions.
- Anyone writing a new skill that spawns sub-agents and needs the correct template before starting.

## How it works

The skill defines a single `Task()` invocation template with four mandatory sections.

**GOAL** states the desired outcome, not the action. Outcome-focused goals produce more reliable sub-agent behavior than action-focused ones ("identify all security vulnerabilities" vs. "review the auth file").

**CONSTRAINTS** lists explicit limits: read-only, no new dependencies, scope to specific directories. Sub-agents run in isolated context and will not infer limits from the parent conversation.

**CONTEXT** provides all files, background information, and standards the sub-agent needs. Because sub-agents cannot access the parent conversation, anything not in the prompt is invisible to them.

**OUTPUT** specifies the log file path, format (YAML or Markdown), and the maximum-token summary to return to the main thread.

The F# pipe notation (`|>`) is a planning and documentation tool, not executable syntax. Each stage in a conceptual pipeline maps to a sequential `Task()` call from the main thread. Sub-agents cannot spawn other sub-agents via the Task tool.

Model selection follows task type: Haiku for lookups and execution, Sonnet for review and analysis, Opus for writing and implementation. If a custom agent in `.claude/agents/` specifies a model in its frontmatter, that takes precedence.
