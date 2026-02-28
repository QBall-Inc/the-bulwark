# Targeted Research: `once: true` and SessionStart Hook Firing Behavior

**Date**: 2026-02-28
**Purpose**: P7 launch planning — determine whether Bulwark's `inject-protocol.sh` SessionStart hook needs `once: true` or equivalent configuration
**Sources**: Official Claude Code docs (code.claude.com), GitHub issues, community articles

---

## Finding 1: `once: true` Does NOT Exist as a Hook Configuration Option

`once: true` is **not a valid field** in Claude Code's hooks configuration schema — in either `hooks/hooks.json` (plugin format) or `settings.json`.

The documented hook configuration fields for a command-type hook are:

```json
{
  "type": "command",
  "command": "path/to/script.sh",
  "timeout": 60,
  "async": true
}
```

Fields confirmed in official documentation and schema references:
- `type` — `"command"`, `"prompt"`, or `"agent"` (required)
- `command` — shell command to execute (required for command type)
- `prompt` — LLM prompt (required for prompt/agent type)
- `timeout` — seconds before hook times out (default 600, i.e., 10 minutes)
- `async` — boolean, run hook in background without blocking Claude (added in Claude Code 2.1.0)

No `once`, `run_once`, `once_per_session`, or similar field appears in any official schema, GitHub issue, or community documentation reviewed.

**Conclusion**: `once: true` does not exist. Do not add it to `hooks.json` — it would be silently ignored or cause a validation error.

---

## Finding 2: SessionStart Hook Firing Behavior

### Official documentation statement (hooks-guide, hooks reference):

> "Some events fire once per session, while others fire repeatedly inside the agentic loop."

SessionStart is explicitly listed among the events that fire at lifecycle boundaries, not inside the agentic loop.

### What "once per session" means for SessionStart

SessionStart fires **once per trigger**, and there are **four distinct trigger conditions** (the `source` field):

| `source` value | When it fires |
|----------------|---------------|
| `startup` | New session begins (first launch or `claude` without `--resume`) |
| `resume` | Session resumed with `--resume` or `--continue` or `/resume` |
| `clear` | After user runs `/clear` |
| `compact` | After context compaction runs (automatic or manual) |

Each of these is a **separate event firing**. In a typical session:
- Launch Claude Code → SessionStart fires once with `source: "startup"`
- Continue working (agentic loop) → SessionStart does NOT fire again
- Run `/clear` mid-session → SessionStart fires again with `source: "clear"`
- Compaction triggers → SessionStart fires again with `source: "compact"`

**SessionStart is NOT a per-turn or per-tool-call event.** It fires at the session lifecycle boundary points listed above, not repeatedly during normal execution.

### Practical implication for inject-protocol.sh

The Bulwark's current `hooks.json` has no `matcher` on the SessionStart hook:

```json
"SessionStart": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/hooks/inject-protocol.sh",
        "timeout": 5000
      }
    ]
  }
]
```

Without a matcher, this fires on ALL four `source` values: `startup`, `resume`, `clear`, and `compact`.

**This is likely correct behavior** for `inject-protocol.sh`. Injecting governance rules after `/clear` or compaction re-establishes the protocol context that was lost. This is explicitly the pattern recommended by the official docs for re-injecting context after compaction:

> "Use a `SessionStart` hook with a `compact` matcher to re-inject critical context after every compaction."

The Bulwark's hook — with no matcher — covers all four cases, which is stricter governance (inject on every session boundary event, not just startup).

---

## Finding 3: Should inject-protocol.sh Use `once: true`?

**No**, because:
1. `once: true` does not exist as a valid field
2. SessionStart is already inherently not a per-loop event — it does not fire repeatedly during a session's agentic turns
3. Re-injecting on `clear` and `compact` is desirable for governance (context is reset)

The only refinement worth considering is **using a matcher to restrict firing to `startup` only**, if the intent is to inject exactly once per physical session start:

```json
"SessionStart": [
  {
    "matcher": "startup",
    "hooks": [
      {
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/hooks/inject-protocol.sh",
        "timeout": 5000
      }
    ]
  }
]
```

However, this would mean governance rules are NOT re-injected after `/clear` or compaction, which is a weaker enforcement posture. The current no-matcher approach (fire on all session boundary events) is more appropriate for a governance plugin.

---

## Finding 4: Other Hook Configuration Options Relevant to Plugin hooks.json

### `async: true` (Claude Code 2.1.0+)

The `async` field runs hooks in the background without blocking Claude. Added in Claude Code 2.1.0.

```json
{
  "type": "command",
  "command": "script.sh",
  "async": true,
  "timeout": 30
}
```

When async is true, Claude continues immediately. If the async hook produces JSON output with `systemMessage` or `additionalContext`, it is delivered on the **next conversation turn**.

**Relevance**: `inject-protocol.sh` should NOT be async — it injects context that Claude needs to see immediately at session start. Async delivery on the "next turn" is not suitable for session initialization.

### `timeout` field

Timeout is in **seconds** in the hook configuration schema. The Bulwark's current hooks.json uses `5000` for `inject-protocol.sh` — this would be interpreted as 5000 seconds (over 83 minutes), not 5 seconds.

**This is a bug**: The timeout on `inject-protocol.sh` is `5000` but should likely be `5` (5 seconds) or `10` (10 seconds). The official default timeout is 600 seconds (10 minutes) if not specified. Other Bulwark hooks use `60000` and `30000` which have the same issue if seconds are expected.

**Action required for P7**: Verify whether `timeout` in hooks.json is in seconds or milliseconds. The official docs say "timeout in seconds" but the Bulwark's values suggest the developer assumed milliseconds. This needs to be tested.

### Matcher for SessionStart

SessionStart supports matchers on the `source` field:

| Matcher value | Fires when |
|---------------|------------|
| `startup` | New session only |
| `resume` | Session resumed only |
| `clear` | After `/clear` only |
| `compact` | After compaction only |

Regex patterns are supported: `startup|resume` would fire on startup and resume but not clear or compact.

### Hook deduplication

From the official docs: "When an event fires, all matching hooks run in parallel, and identical hook commands are automatically deduplicated."

This means if the same command string appears multiple times (e.g., from overlapping plugin and project settings), Claude Code deduplicates them. This is relevant if the Bulwark's plugin hooks.json and a user's project settings.json both define the same SessionStart hook.

---

## Finding 5: Known Bug — SessionStart Doesn't Fire on First Run with Marketplace Plugins

**GitHub Issue #10997**: SessionStart hooks from marketplace plugins do NOT execute on the **first run** due to a race condition between async marketplace loading and hook registration.

- **First run**: Hook silently fails (marketplace not yet cached)
- **Subsequent runs**: Hook fires correctly (marketplace is cached)

This affects the Bulwark's `inject-protocol.sh` on first install. The user would need to restart Claude Code after the initial install for hooks to take effect.

**Mitigation**: Document this as a known first-run behavior in the Bulwark plugin's README/setup instructions.

---

## Summary

| Question | Answer |
|----------|--------|
| Does `once: true` exist? | No — not a valid hook field |
| Does SessionStart fire once per session? | Effectively yes, but it fires once per session boundary event (`startup`, `resume`, `clear`, `compact`) |
| Does our hook need `once: true`? | No — SessionStart already does not fire inside the agentic loop |
| Should we restrict to `startup` only? | No — re-injecting after `/clear` and compaction is correct for governance |
| Is there a timeout unit issue? | Possibly — verify whether `timeout` is seconds or milliseconds |
| First-run bug? | Yes — marketplace plugin hooks skip on first run (issue #10997) |

---

## Relevant Documentation Links

- [Hooks reference](https://code.claude.com/docs/en/hooks) — official event schemas, configuration options
- [Automate workflows with hooks](https://code.claude.com/docs/en/hooks-guide) — hook guide with SessionStart examples and matcher table
- [Plugins reference](https://code.claude.com/docs/en/plugins-reference) — plugin hooks.json format
- [GitHub Issue #10997](https://github.com/anthropics/claude-code/issues/10997) — SessionStart hooks don't execute on first run with marketplace plugins
- [GitHub Issue #10808](https://github.com/anthropics/claude-code/issues/10808) — Feature request: autonomous messages after SessionStart
- [Async hooks article](https://blog.devgenius.io/claude-code-async-hooks-what-they-are-and-when-to-use-them-61b21cd71aad) — async: true configuration details
