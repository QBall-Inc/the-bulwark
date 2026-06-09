# Getting Started

This guide covers prerequisites, installation, and the guided `init` walkthrough. For a quick install, the [README](../../README.md) has the short version; this page is the extended walkthrough.

## Prerequisites

| Requirement | Details |
|-------------|---------|
| Claude Code | Latest version recommended. Plugin support required. |
| Node.js | v18+ (for TypeScript tooling and `just` recipes) |
| [just](https://github.com/casey/just) | Command runner used for build/typecheck/lint recipes. `/the-bulwark:init` offers to install it for you. |
| Language Servers | TypeScript (`typescript-language-server`), Python (`pyright`), etc. The LSP setup within `/the-bulwark:init` will offer to install language servers for your project's languages. |
| Platform | Linux, macOS, WSL2. Native Windows is not tested. |
| Claude Plan | Max or Enterprise recommended. Pro Plus works for single-agent skills but will hit rate limits on multi-agent pipelines. |

## Installation

Two ways to install. Pick whichever works for you.

### Option A: npm

```bash
claude /plugin install npm:@qball-inc/the-bulwark
```

### Option B: Marketplace

First, add the QBall-Inc marketplace (one-time setup):

```bash
claude /plugin marketplace add QBall-Inc/plugins-market
```

Then install:

```bash
claude /plugin install the-bulwark@qball-inc
```

## Post-install: run the init skill

After installing, restart your Claude Code session and run the init skill:

```
/the-bulwark:init
```

This walks you through a guided setup:

- **Rules.md injection** — installs the CS/T/V/ID conventions at `.claude/rules/rules.md` (see [conventions.md](../reference/conventions.md)).
- **CLAUDE.md configuration** — creates a project CLAUDE.md with project-specific instructions, backing up any existing one first. You choose scope: project-level (committed, shared with your team) or user-level (local, not committed).
- **Optional tooling** — LSP setup (offers to install language servers), Justfile scaffolding (build/typecheck/lint recipes), and statusline configuration.

Init auto-detects brownfield projects and adjusts accordingly.

## Keeping your setup current: `init --update`

A `SessionStart` hook (`check-template-drift`) detects when your project's `CLAUDE.md` or `Rules.md` have drifted from the canonical templates shipped with the current plugin version, and surfaces the diff for review. The `/the-bulwark:init --update` flow then walks you through accepting each drifting section, with batched/tabbed prompts when 4+ sections need review and full pre-flight visibility into what's about to change.

Your project's `Rules.md` and `CLAUDE.md` live in your project repo, not in the plugin directory — so plugin updates never silently change them.

## Updating the plugin

```bash
claude plugin update the-bulwark@qball-inc
```

You can also enable auto-updates per marketplace (open `/plugin` → Marketplaces tab → QBall-Inc → toggle auto-update). Auto-update is disabled by default for third-party marketplaces. If you installed via npm, the same update command works — Claude Code resolves the source from the installed plugin metadata.

## Trouble installing?

See [FAQ and troubleshooting](../faq.md) — it covers the SSH "Permission denied (publickey)" clone failure, hooks not firing after install, `just` not found, and more. If your issue isn't covered, [open an issue](https://github.com/QBall-Inc/the-bulwark/issues).

## Next steps

- [How it works](how-it-works.md) — the three-layer model and the multi-agent pipelines
- [Research & planning](research-and-planning.md) — start a new project or feature with structured research
- [Fixing bugs](fixing-bugs.md) — analyze, fix, and verify with the issue/fix pipelines
