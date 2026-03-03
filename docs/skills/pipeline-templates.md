# pipeline-templates

Pre-defined F# pipe workflow templates for multi-agent orchestration.

## Invocation & usage

`pipeline-templates` is a reference skill (`user-invocable: false`). You do not invoke it directly. It is loaded automatically by the PostToolUse hook after significant code changes, and referenced by `subagent-prompting` for model selection and stage structure.

After a significant write or edit, the hook injects a pipeline recommendation into Claude's context. Claude selects the matching template and begins orchestration. Small changes below the per-file-type line threshold are skipped silently.

To consult the templates directly during orchestration planning, ask Claude:

```
"Which pipeline applies to a bug fix that needs new tests?"

"Show me the Fix Validation pipeline stage breakdown."

"What's the model selection rule for code-writing stages?"
```

## Who is it for

- Orchestrators who need to pick the right workflow template before spawning agents.
- Anyone building new multi-agent skills who wants canonical stage sequences and model assignments to start from.
- Teams wanting to understand how The Bulwark routes code changes to review, test, and fix pipelines automatically.

## How it works

The skill defines six named pipelines. Each pipeline specifies stage order, agent type per stage (role-based or custom sub-agent), model assignment, and output contract. Stages are written in F# pipe syntax: `|>` for sequential execution, `[]` for parallel.

**Pipeline selection** follows the type of work:

| Pipeline | When to use |
|----------|-------------|
| Code Review | Reviewing existing code or a PR |
| Fix Validation | Bug fix or issue resolution |
| Test Audit | Test quality assessment |
| New Feature | Implementing new functionality |
| Research & Planning | Pre-implementation research (min 3 iterations) |
| Test Execution & Fix | Run tests, diagnose failures, apply fixes |

A seventh composite template, Code Change Workflow, chains Code Review, Test Audit, Test Execution, and Fix Validation in sequence. The PostToolUse hook triggers it automatically after significant writes or edits.

**Model assignment** follows a three-tier rubric:

| Task type | Model | Examples |
|-----------|-------|---------|
| Lookups & execute | Haiku | Run tests, file search, classify |
| Review & analyze | Sonnet | Code review, failure analysis, audit synthesis |
| Write & fix | Opus | Implement fixes, write code, write tests |

If a custom agent specifies `model:` in its frontmatter, that takes precedence over the rubric.

**Hook behavior.** The PostToolUse hook fires after every `Write` or `Edit`. Small changes below a per-file-type line threshold are skipped silently. Changes above threshold produce a pipeline suggestion injected into Claude's context. The hook never blocks execution. Pipeline selection remains a suggestion, not a hard gate.

**Progress tracking.** Stage start and stop events are written to `logs/pipeline-tracking.log` via the SubagentStart and SubagentStop hooks. No manual logging needed.
