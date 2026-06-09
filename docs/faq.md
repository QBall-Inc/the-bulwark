# FAQ & Troubleshooting

## Plugin clone fails with "Permission denied (publickey)"

If you see this error when installing from the marketplace:

```
git@github.com: Permission denied (publickey).
fatal: Could not read from remote repository.
```

Your git is defaulting to SSH for GitHub, but you don't have SSH keys configured. Fix by telling git to use HTTPS:

```bash
git config --global url."https://github.com/".insteadOf "git@github.com:"
```

Then retry the install. This applies globally and redirects all GitHub SSH URLs to HTTPS.

## Hooks aren't firing after install

Restart your Claude Code session. Hooks only load at session start. If they still don't fire, check that the plugin is installed:

```bash
claude /plugin list
```

If `the-bulwark` appears in the list but hooks still don't run, check `hooks/hooks.json` exists in the plugin directory. The `${CLAUDE_PLUGIN_ROOT}` variable must resolve to the plugin's install location.

## Quality gate keeps failing on non-code files

The `enforce-quality.sh` hook skips files in `tmp/`, `logs/`, `.claude/`, `docs/`, and `node_modules/`. If you're editing a file outside these directories that isn't code (like a config file), the hook may still trigger. This is by design. If the failure is a false positive, check that your `Justfile` recipes handle the file type correctly.

## Multi-agent pipelines time out or get interrupted

This usually means you're hitting rate limits on your Claude plan. The product-ideation pipeline spawns 6 agents sequentially, and plan-creation can spawn 4. Each agent consumes tokens independently. Max and Enterprise plans handle this without issues. Pro Plus will work for single-agent skills but may hit limits on pipelines with 3+ agents.

## `just` command not found

The `/the-bulwark:init` skill offers to install `just` for you during setup. If you skipped that step, install it manually:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
```

Or via your package manager: `brew install just` (macOS), `cargo install just` (Rust), `apt install just` (Debian/Ubuntu).

## Rules.md conflicts with my existing project rules

The Bulwark installs its rules at `.claude/rules/rules.md`. If you already have rules in `.claude/rules/`, they won't be overwritten. The Bulwark's rules and your project rules both load at session start and coexist. If there's a conflict, your project-specific CLAUDE.md instructions take precedence since they load after the rules.

## Can I use this with other Claude Code plugins?

Yes. The Bulwark doesn't interfere with other plugins. Its hooks use `${CLAUDE_PLUGIN_ROOT}` for path resolution, so there's no collision. The only potential issue is if another plugin also installs PostToolUse hooks on Write/Edit, in which case both hooks run (Claude Code runs all matching hooks, not just the first one).

## How do I update the plugin?

Use the plugin update command:

```bash
claude plugin update the-bulwark@qball-inc
```

You can also enable auto-updates per marketplace. Open `/plugin`, go to the Marketplaces tab, select the QBall-Inc marketplace, and toggle auto-update on. Note that auto-update is disabled by default for third-party marketplaces.

If you installed via npm, the same update command works. Claude Code resolves the source from the installed plugin metadata.

Your project's Rules.md and CLAUDE.md are not affected by updates since they live in your project repo, not in the plugin directory.

## The statusline shows token usage but not cost

Cost tracking depends on your Claude Code version and plan. If cost data isn't available from the API, the statusline falls back to showing token counts only. Run `/the-bulwark:bulwark-statusline` to reconfigure or switch presets.

## I want to disable a specific hook temporarily

You can't disable individual plugin hooks without modifying `hooks/hooks.json` in the plugin directory. But you can work around it by adding the file path to the skip list in `enforce-quality.sh`, or by working in a directory that the hook already skips (`tmp/`, `logs/`, etc.).

## Still stuck?

[Open an issue](https://github.com/QBall-Inc/the-bulwark/issues) on GitHub. Include your plugin version, Claude Code version, OS/platform (WSL/macOS/Linux), and the relevant hook or skill.
