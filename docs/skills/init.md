# init

Guided initialization skill for setting up Bulwark governance in a project. Installs `CLAUDE.md` and `rules.md`, then offers optional tooling setup.

## Invocation and usage

```
/the-bulwark:init                          # Interactive setup
/the-bulwark:init --scope=project          # Project scope, skip prompt
/the-bulwark:init --scope=user             # User scope (local to your machine)
/the-bulwark:init --scope=project /path    # Initialize at a specific directory
/the-bulwark:init --verify                 # Verify a previous init completed correctly
```

Run this once after installing the plugin. It is interactive and guides you through each step.

## Who is it for

- Anyone adopting Bulwark for the first time on a project.
- Teams setting up shared governance files that get checked into the repo.
- Individual users who want per-machine governance without committing it to source control.

## How it works

Init runs in two modes: `INIT MODE` (the default) and `VERIFY MODE` (triggered by `--verify`).

**Init mode** walks through four stages:

1. **Scope detection.** Checks both project scope (`./CLAUDE.md`, `./.claude/rules/rules.md`) and user scope (`~/.claude/CLAUDE.md`, `~/.claude/rules/rules.md`) before writing anything. If governance files already exist at either scope, it warns you and offers to back them up (`.bak`) before proceeding. Having files at both scopes simultaneously is flagged as a potential conflict.

2. **Governance install.** Runs `init.sh` from the plugin directory. Creates `CLAUDE.md` and `rules.md` at the selected scope. On completion, displays the list of files created and reminds you to restart your Claude Code session. Hooks do not activate until after a restart.

3. **Optional tooling.** Presents a multi-select prompt for additional setup. You can pick any combination or skip all of them:
   - **Statusline.** Configures the Claude Code status line to show token usage. Invokes `/the-bulwark:bulwark-statusline`.
   - **LSP integration.** Sets up language servers for your project's languages. Invokes `/the-bulwark:setup-lsp`.
   - **Project scaffold.** Generates a `Justfile` with build, typecheck, and lint recipes. Invokes `/the-bulwark:bulwark-scaffold`.

4. **State file.** Writes `tmp/init/init-state.yaml` recording what was configured. This file is used by `--verify` mode on the next session.

**Verify mode** reads the state file from the previous init run and checks each component: governance files exist, hooks are active, and any selected tooling is correctly configured. It prints a pass/fail summary for each component and provides remediation steps for any failures.
