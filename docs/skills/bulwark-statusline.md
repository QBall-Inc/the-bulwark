# bulwark-statusline

Configures the Claude Code status line to display token usage, model, cost, and git context in real-time.

## Invocation and usage

```
/the-bulwark:bulwark-statusline init        # First-time setup: install config and wire into settings.json
/the-bulwark:bulwark-statusline minimal     # Switch to minimal preset (1 line: model + gauge + tokens)
/the-bulwark:bulwark-statusline developer   # Switch to developer preset (3 lines)
/the-bulwark:bulwark-statusline cost        # Switch to cost preset (2 lines: tokens + cost + duration)
```

**Examples:**

```
/the-bulwark:bulwark-statusline init
```

Run once after installing the plugin. Creates `~/.bulwark/statusline.yaml` and adds the `statusLine` entry to `.claude/settings.json`. Restart your session to activate.

```
/the-bulwark:bulwark-statusline developer
```

Switch to the developer preset. Adds a second line showing the last modified file and a third line showing the current git branch and pending change count.

```
/the-bulwark:bulwark-statusline cost
```

Switch to cost tracking. Line 1 shows model, gauge, tokens, and cost. Line 2 shows session duration.

## Who is it for

- Engineers who want token and cost visibility without switching to `/cost` mid-session.
- Teams monitoring context consumption across long sessions with multiple sub-agents.
- Anyone who wants git context (branch, pending count) visible in the status line at all times.

## How it works

On `init`, the skill creates a config file at `~/.bulwark/statusline.yaml` using the default template and spawns a Haiku sub-agent to merge the `statusLine` key into `.claude/settings.json`. The settings entry points to a bundled shell script (`skills/bulwark-statusline/scripts/statusline.sh`) that Claude Code calls on every interaction to produce the status line output.

On preset commands (`minimal`, `developer`, `cost`), the skill reads `~/.bulwark/statusline.yaml` and updates the `preset:` value. No restart required. The next interaction picks up the new preset.

Presets control what each line shows:

| Preset | Lines | Content |
|--------|-------|---------|
| `minimal` | 1 | Model, context gauge, token count |
| `developer` | 3 | Line 1: model + gauge + tokens. Line 2: last modified file. Line 3: git branch + pending count |
| `cost` | 2 | Line 1: model + gauge + tokens + cost. Line 2: session duration |

Colors use RGB escape codes. Gauge and percentage colors shift from green to yellow to coral as context fills.
