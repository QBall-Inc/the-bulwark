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

## Notes

- **Quality gate scope** — `enforce-quality.sh` skips files in `tmp/`, `logs/`, `.claude/`, `docs/`, and `node_modules/`. Edits to code outside those directories trigger the gate.
- **Disabling a hook** — individual plugin hooks can't be toggled off without editing `hooks/hooks.json` in the plugin directory. Workarounds: add a path to the skip list in `enforce-quality.sh`, or work in a directory the hook already skips. See [FAQ](../faq.md).
- **Coexistence** — hooks use `${CLAUDE_PLUGIN_ROOT}` so they don't collide with other plugins. If another plugin also installs PostToolUse hooks on Write/Edit, both run (Claude Code runs all matching hooks).
