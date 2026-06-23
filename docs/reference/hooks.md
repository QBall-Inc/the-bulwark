# Hooks Reference

The Bulwark installs eight hooks that run automatically. No manual invocation needed. All hooks use `${CLAUDE_PLUGIN_ROOT}` for path resolution, so they work regardless of where the plugin is installed.

| Hook | Event | Trigger | Timeout | What it does |
|------|-------|---------|---------|--------------|
| `enforce-quality.sh` | PostToolUse | Every `Write`, `Edit`, or `MultiEdit` on code files | 60s | Runs `just typecheck`, `just lint`, `just build`. Flags failures to Claude with full error output. Skips non-code files (`tmp/`, `logs/`, `.claude/`, `docs/`). |
| `suggest-pipeline-stop.sh` | Stop | End of every Claude turn | 30s | Suggests relevant review/audit pipelines based on session activity. File-type-aware routing, per-file registry, post-fix grace period to suppress redundant suggestions. |
| `inject-protocol.sh` | SessionStart | Every new session | 5s | Injects the governance protocol into Claude's context. Loads Rules.md, activates quality enforcement, displays the activation banner. |
| `cleanup-stale.sh` | SessionStart | Every new session | 30s | Deletes files older than 10 days from `logs/` and `tmp/`. Preserves `.gitkeep` files. Keeps your repo from accumulating stale pipeline output. |
| `cleanup-review-registry.sh` | SessionStart | Every new session | 5s | Wipes stale review-accumulator state so pipeline gating works correctly across sessions. |
| `check-template-drift.sh` | SessionStart | Every new session in a Bulwark-initialized project | 5s | Detects drift between the project's `CLAUDE.md`/`Rules.md` and the canonical templates shipped with the current plugin version. Surfaces drifting sections for `/the-bulwark:init --update`. |
| `track-pipeline-start.sh` | SubagentStart | Any sub-agent spawned | 30s | Logs pipeline invocation metadata (agent name, timestamp, parent context) for observability. |
| `track-pipeline-stop.sh` | SubagentStop | Any sub-agent exits | 30s | Logs pipeline completion metadata (agent name, duration, exit status) for observability. |

## How hooks fit the model

Hooks are **Layer 2** of the defense-in-depth model — they run programmatic checks after every code change, independent of whatever Claude intends to do. See [how-it-works.md](../guides/how-it-works.md) for the three-layer model (rules → hooks → pipelines) and [architecture.md](../architecture.md) for the deeper design rationale.

## Optional: permission-bypass hook (opt-in, default off)

Beyond the eight automatic hooks above, The Bulwark ships **one optional hook that is off by default** and must be explicitly turned on: `bulwark-permission-hook.sh`. It is the only Bulwark hook that does nothing unless you opt in.

**The problem it solves.** Claude Code re-prompts for permission every time it reads, edits, or runs one of the plugin's *own* bundled files — even though you already trusted the plugin when you installed it. On some platforms (notably WSL) the underlying allow-rules don't persist reliably, so those prompts keep coming back. The hook auto-approves Read, Edit, and Bash operations whose target resolves **inside The Bulwark's own plugin directory**, and stays silent — deferring to Claude Code's normal permission flow — for everything else.

**The safety boundaries** (what it deliberately does *not* do):

- **Only Bulwark-owned paths are ever auto-approved.** Anything outside the plugin directory — your own source files, `/etc/passwd`, a `curl` to the internet — goes through Claude Code's normal prompt, completely unchanged.
- **Writes are never auto-approved.** The hook does not act on the `Write` tool at all. Creating new files always prompts.
- **Path-traversal is denied, not approved.** A path that looks like a plugin path but escapes it (for example `…/the-bulwark/../../../../etc/passwd`) is actively blocked.
- **Bash is the most conservative case.** Only a plain "run a bundled script" command is auto-approved (for example `bash <plugin-dir>/scripts/some-hook.sh`). Anything with a pipe, redirect, `&&`, subshell, or a path that points outside the plugin defers to the normal prompt — and a destructive command such as `rm` on a plugin file is *not* auto-approved.

**Who should consider it.** Users who don't run Claude Code in auto mode (for example on the Pro tier), or who prefer deterministic allow-rules over the auto-mode classifier. If you're on a plan with auto mode enabled, most of these prompts are already handled for you and you likely don't need this hook.

**How to enable it.**

- *Per project* — run `/the-bulwark:bulwark-scaffold --with-permission-hook`. It asks you to confirm the trust decision, then installs the hook into that project's `.claude/settings.json`. Without the flag, nothing is installed.
- *Plugin-wide* — set the plugin's `enable_permission_bypass` user-config option to `true`. It defaults to `false`, and the hook stays completely inert until you set it, so installing or updating the plugin never turns it on for you.

**How to disable it.** Remove the hook entry from your project's `.claude/settings.json` (project install), or set `enable_permission_bypass` back to `false` (plugin install). Once removed, every operation reverts to Claude Code's default prompting.

**Why it's a workaround, and when it retires.** This hook exists only because Claude Code currently has no built-in way to permanently trust a plugin's own bundled assets — so it is meant to be temporary. We will retire it when either of these lands:

- Claude Code ships a native "trust this plugin / directory" mechanism — tracked upstream at [anthropics/claude-code#29285](https://github.com/anthropics/claude-code/issues/29285), or
- auto mode becomes available and reliable across all plan tiers, removing the need this hook serves.

Until then it stays opt-in and off by default.

## Notes

- **Quality gate scope** — `enforce-quality.sh` skips files in `tmp/`, `logs/`, `.claude/`, `docs/`, and `node_modules/`. Edits to code outside those directories trigger the gate.
- **Disabling a hook** — individual plugin hooks can't be toggled off without editing `hooks/hooks.json` in the plugin directory. Workarounds: add a path to the skip list in `enforce-quality.sh`, or work in a directory the hook already skips. See [FAQ](../faq.md).
- **Coexistence** — hooks use `${CLAUDE_PLUGIN_ROOT}` so they don't collide with other plugins. If another plugin also installs PostToolUse hooks on Write/Edit, both run (Claude Code runs all matching hooks).
