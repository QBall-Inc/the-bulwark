# Headless Agent Invocation from Sub-Agents

**Discovered**: Session 75 (2026-02-23)
**Status**: Empirically confirmed, production-tested

## The Constraint

Sub-agents (invoked via Task tool) cannot spawn other sub-agents. The Task tool is not available inside a sub-agent context. This was documented in Session 71 as an architectural limitation that made pipeline agents infeasible.

## The Discovery

Sub-agents **can** invoke other agents by running `claude` in headless mode via the Bash tool:

```bash
# Invoke an agent in headless mode from within a sub-agent
claude -p --agent <agent-name> "Your prompt here"

# Or pipe a longer prompt via stdin
cat <<'PROMPT' | claude -p --agent <agent-name>
GOAL: ...
CONSTRAINTS: ...
CONTEXT: ...
OUTPUT: ...
PROMPT
```

The `--print` (`-p`) flag runs Claude in non-interactive (headless) mode. The `--agent` flag loads the specified agent's system prompt and configuration. The output is returned via stdout to the calling sub-agent's Bash tool result.

## How It Was Discovered

During Session 75, the orchestrator launched 8 parallel sub-agents to run `anthropic-validator` on 9 assets. The anthropic-validator skill instructs the executor to spawn `bulwark-standards-reviewer` via the Task tool. Since each executor was itself a sub-agent (and sub-agents can't use Task tool to spawn sub-agents), the sub-agents independently solved this by falling back to headless mode:

```bash
# Sub-agent fetching standards via claude-code-guide agent
claude --print -p "Fetch current standards for Claude Code custom sub-agents..." \
  --agent claude-code-guide 2>/dev/null

# Sub-agent invoking bulwark-standards-reviewer
cat <<'AGENTPROMPT' | claude -p --agent bulwark-standards-reviewer 2>/dev/null
GOAL: Critically analyze .claude/agents/product-ideation-strategist.md...
AGENTPROMPT
```

This was not pre-planned by the orchestrator. The sub-agents discovered the workaround autonomously when they found the Task tool unavailable.

## Trade-Off Analysis

| Concern | Task Tool | Headless Mode | Assessment |
|---------|-----------|---------------|------------|
| Structured return (summary) | Yes — Task tool returns summary | No — raw stdout | **Moot**: Sub-agents write structured output to `logs/` via subagent-output-templating. The orchestrator reads logs, not raw returns (SA2). |
| Agent ID for resumption | Yes — can resume via agent ID | No — one-shot only | **Moot**: Sub-agents are never resumed. Each invocation is a fresh context. |
| Token tracking | Yes — visible in Task metadata | No — opaque | **Minor**: Token usage within the headless call is not tracked in the parent's metrics. Acceptable for bounded, well-scoped agent invocations. |
| Tool permissions | Inherited from parent session | Inherited from parent session | **Equivalent**: Both approaches inherit the same permission context. |
| Context isolation | Full isolation (separate context window) | Full isolation (separate process) | **Equivalent**: Both run in isolated contexts. |

**Conclusion**: For sub-agent-to-agent delegation, headless mode is functionally equivalent to Task tool invocation. The trade-offs that exist in theory don't apply in practice because of how the Bulwark pipeline architecture already works (log-based output, no resumption, SA2 compliance).

## Implications for Existing Tasks

### P6.7: Fix Validation Stage 5 — Code Review

**Previous approach**: Stage 5 uses a general-purpose Sonnet sub-agent for lightweight review because sub-agents can't invoke the full code-review pipeline (which spawns its own sub-agents).

**New approach**: Stage 5 sub-agent can invoke `claude -p --agent bulwark-standards-reviewer` or even run the full code-review skill via headless mode, getting production-grade review instead of a lightweight substitute.

### P6.8: Agent-Scoped Quality Enforcement for bulwark-verify

**Previous approach**: Required a dedicated agent (`bulwark-verify-scriptgen.md`) with a separate quality enforcement hook script (`enforce-quality-tmp.sh`) because the skill's script-generation sub-agent couldn't trigger quality pipelines.

**New approach**: The script-generation sub-agent can invoke quality checks via headless mode, potentially simplifying the architecture. The separate agent and hook script may be unnecessary.

## Usage Pattern

When a sub-agent needs to invoke another agent:

```bash
# 1. Prepare the prompt (use SA1 4-part template)
PROMPT="GOAL: ...
CONSTRAINTS: ...
CONTEXT: ...
OUTPUT: ..."

# 2. Invoke in headless mode
RESULT=$(echo "$PROMPT" | claude -p --agent <agent-name> 2>/dev/null)

# 3. Process the result
# The sub-agent can parse stdout and incorporate findings
# into its own structured log output
```

## Constraints

- The invoked agent runs as a **separate process** with its own context window
- The invoked agent **cannot** access the calling sub-agent's context or conversation history
- The calling sub-agent must pass all necessary context in the prompt
- Headless mode does **not** support interactive features (AskUserQuestion, permission prompts)
- The invoked agent's output comes back as a single stdout blob — structure it via the prompt
- `2>/dev/null` is recommended to suppress stderr noise from the headless process

## Relationship to Other Patterns

| Pattern | When to Use |
|---------|-------------|
| **Task tool** (from main context) | Primary model delegating to sub-agents. Full features. |
| **Headless agent mode** (from sub-agents) | Sub-agent needs to invoke another agent. Workaround for Task tool limitation. |
| **Skills with context:fork** | Running a skill as an isolated task. Different mechanism (skill-as-task, not agent-as-agent). |
| **Agent Teams** | Multiple agents collaborating with peer messaging. Requires experimental flag. |
