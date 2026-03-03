# setup-lsp

Configures Language Server Protocol integration for Claude Code projects: detects project languages, installs language server binaries, guides plugin installation, and verifies servers loaded after restart.

## Invocation and usage

```
/the-bulwark:setup-lsp                    Full setup: detect languages, install binaries, guide plugin install, checkpoint
/the-bulwark:setup-lsp --lang <languages> Skip detection, install specified languages directly
/the-bulwark:setup-lsp --verify           Post-restart verification only (no installation)
/the-bulwark:setup-lsp --troubleshoot     Diagnostics only (no installation)
```

**Examples:**

```
/the-bulwark:setup-lsp
```
Full setup from scratch. Scans manifest files to detect your project's languages, installs server binaries, then walks you through plugin installation.

```
/the-bulwark:setup-lsp --lang typescript,python
```
Skips detection and goes straight to installing the specified language servers. Useful when auto-detection misses a language or you're adding a second project.

```
/the-bulwark:setup-lsp --verify
```
Run this after restarting Claude Code. Reads the debug log and confirms that LSP servers loaded successfully. Proceeds to diagnostics automatically if any server failed.

## Who is it for

- Developers setting up a new project who want semantic code navigation (go-to-definition, find-references, hover types) instead of text search.
- Anyone who just installed LSP plugins and needs to confirm servers initialized correctly after the required session restart.
- Users experiencing broken or missing LSP tools who want a structured diagnostic pass.

## How it works

LSP servers only initialize at session startup. Full setup requires a mandatory exit-and-resume step, which the skill handles by stopping at the right moment and giving you the exact resume command.

**Full setup (no flags).** The skill scans manifest files (`package.json`, `pyproject.toml`, `Cargo.toml`, etc.) up to two directory levels deep and presents the detected languages for confirmation. It then installs the language server binary for each confirmed language, sets `ENABLE_LSP_TOOL=1` in `~/.claude/settings.json` and your shell profile, and guides you through plugin installation via `/plugin` or CLI. Once plugins are installed, it stops and presents the resume command:

```
claude --resume <session-id>
```

After resuming, run `/the-bulwark:setup-lsp --verify` to confirm servers loaded.

**Verify mode (`--verify`).** Reads `~/.claude/debug/latest` and checks for `Total LSP servers loaded: N`. Reports which servers are active. If N is 0 or the line is absent, proceeds to diagnostics automatically.

**Troubleshoot mode (`--troubleshoot`).** Works through five common issues in order: `ENABLE_LSP_TOOL` not set, plugin not installed, plugin installed but not enabled, servers loaded as 0 (async race requiring a second exit-and-resume), and binary not in `$PATH`. Applies fixes where detected and re-runs verification after each fix.

At the end of any run, a diagnostic YAML is written to `logs/diagnostics/lsp-setup-{timestamp}.yaml` with the full setup state: detected languages, binary status, plugin list, verification result, and any issues found.
