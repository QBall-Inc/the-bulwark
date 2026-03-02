---
name: init
description: Initialize Bulwark governance in a project. Sets up CLAUDE.md, rules.md, and optional tooling (statusline, LSP, scaffold).
user-invocable: true
argument-hint: "[--scope=project|user] [--verify] [target-dir]"
---

# Bulwark Init

Initialize Bulwark governance for a project or user. Installs governance files and optionally configures statusline, LSP, and project scaffolding.

## Usage

```
/the-bulwark:init                          # Interactive setup
/the-bulwark:init --scope=project          # Project scope, skip prompt
/the-bulwark:init --scope=user             # User scope
/the-bulwark:init --verify                 # Verify previous init completed
/the-bulwark:init --scope=project /path    # Project scope at specific path
```

---

## Mode Routing

```
IF $ARGUMENTS contains "--verify":
    → Jump to VERIFY MODE (Stage 8)
ELSE:
    → Continue with INIT MODE (Stage 1)
```

---

## INIT MODE

### Stage 1: Parse Arguments

Extract from `$ARGUMENTS`:
- `--scope=project` or `--scope=user` → SCOPE
- Remaining positional argument → TARGET_DIR (optional, defaults to current directory for project scope)

### Stage 2: Pre-Flight — Cross-Scope Initialization Check

**Check BOTH scopes regardless of which scope the user selected.** This prevents silent conflicts where governance files exist at one scope and the user initializes at another.

Detect existing files at **project scope**:
- `./CLAUDE.md` (or `<target-dir>/CLAUDE.md`)
- `./.claude/rules/rules.md` (or `<target-dir>/.claude/rules/rules.md`)

Detect existing files at **user scope**:
- `~/.claude/CLAUDE.md`
- `~/.claude/rules/rules.md`

**Report findings to the user based on what was detected:**

#### Case A: No files found at either scope
Proceed to Stage 3. No warnings needed.

#### Case B: Files found at the SELECTED scope only
Warn the user:

```
Existing Bulwark files detected at [selected] scope:
  - [list files found]

The init script will create .bak backups of these files before overwriting.
```

Ask: "Proceed with initialization? (existing files will be backed up)"

#### Case C: Files found at the OTHER scope (not the selected one)
Warn the user:

```
Existing Bulwark files detected at [other] scope:
  - [list files found]

You are initializing at [selected] scope. The files at [other] scope will
NOT be modified, but having governance files at both scopes may cause
conflicting instructions that impact accurate functioning.

Options:
  1. Proceed — keep files at both scopes (you manage consistency)
  2. Cancel — remove or descope the [other] scope files first, then re-run
```

Ask the user to choose before proceeding.

#### Case D: Files found at BOTH scopes
Combine warnings from Case B and Case C:

```
Existing Bulwark files detected at BOTH scopes:

  Project scope:
    - [list files found]

  User scope:
    - [list files found]

You are initializing at [selected] scope:
  - Files at [selected] scope will be backed up (.bak) and overwritten.
  - Files at [other] scope will NOT be modified.

Having governance files at both scopes may cause conflicting instructions
that impact accurate functioning.

Options:
  1. Proceed — overwrite [selected] scope (backed up), keep [other] scope as-is
  2. Cancel — clean up the [other] scope files first, then re-run
```

Ask the user to choose before proceeding.

### Stage 3: Run Init Script

Execute the init script using the plugin directory path. First verify the environment variable is set:

```bash
if [ -z "$CLAUDE_PLUGIN_DIR" ]; then
  echo "ERROR: CLAUDE_PLUGIN_DIR is not set. This skill must be run as a plugin."
  exit 1
fi
"$CLAUDE_PLUGIN_DIR/scripts/init.sh" [arguments]
```

`$CLAUDE_PLUGIN_DIR` is set by the Claude Code plugin runtime and resolves to the installed plugin root. If unset, the skill is not running in a plugin context.

Where `[arguments]` is the original `$ARGUMENTS` string (excluding `--verify`) passed through verbatim. This preserves `--scope=` and any target directory the user provided.

If `--scope` was not provided, init.sh will present its own interactive scope selection prompt.

### Stage 4: Report Results and Restart Warning

After init.sh completes successfully, present to the user as visible text (NOT hidden in bash output):

```
Bulwark governance initialized!

Files created:
  - [CLAUDE.md path]
  - [rules.md path]

IMPORTANT: Hooks do not activate until you restart your Claude Code session.
This is a known Claude Code limitation (#10997). After restarting, Bulwark's
quality gates (typecheck, lint, build) will enforce automatically on every
code change.
```

If init.sh exits with a non-zero status, report the error output to the user and stop.

### Stage 5: Post-Init Setup Selection

Use AskUserQuestion to present optional setup choices:

**Question:** "Which additional setup would you like to configure?"
**multiSelect:** true
**Options:**
1. **Status line** — Configure the Bulwark status line display (quick, no dependencies)
2. **LSP integration** — Set up Language Server Protocol for code intelligence (requires language servers)
3. **Project scaffold** — Generate Justfile with build/test/lint recipes (requires project manifest)

If the user selects nothing (skips), proceed to Stage 7 (write state and finish).

### Stage 6: Execute Selected Setup

Follow this order strictly:

#### 6a: Statusline (if selected)

Invoke the statusline skill immediately — it has no language dependencies:

```
/the-bulwark:bulwark-statusline
```

Follow the bulwark-statusline skill instructions completely. Once done, continue.

#### 6b: Language Selection (if LSP or scaffold selected)

If the user selected LSP, scaffold, or both, use AskUserQuestion to determine the tech stack:

**Question:** "What languages/frameworks does this project use?"
**multiSelect:** true
**Options:**
1. **Node/TypeScript** — JavaScript, TypeScript, React, Vue, etc.
2. **Python** — Python with pip, poetry, or uv
3. **Rust** — Rust with Cargo
4. **Other** — User specifies manually

Based on the selection, ensure the language toolchain is installed:
- **Node/TypeScript**: Check for `node`, `npm`/`bun`. If missing, guide installation.
- **Python**: Check for `python3`, `pip`/`poetry`/`uv`. If missing, guide installation.
- **Rust**: Check for `rustc`, `cargo`. If missing, guide installation.
- **Other**: Ask the user what package manager and build tools they use.

Also check for project manifest files (`package.json`, `pyproject.toml`, `Cargo.toml`). If none exist, ask the user if they want to initialize one (e.g., `npm init`, `cargo init`).

Once the language toolchain is confirmed present, proceed with the selected skills.

#### 6c: Scaffold (if selected)

Map the language selection to the scaffold `--lang` argument:
- Node/TypeScript → `--lang=node`
- Python → `--lang=python`
- Rust → `--lang=rust`
- Other/generic → `--lang=generic`

Invoke:

```
/the-bulwark:bulwark-scaffold --lang=<detected>
```

Follow the bulwark-scaffold skill instructions completely. Once done, continue.

#### 6d: LSP (if selected)

Map the language selection to the LSP `--lang` argument:
- Node/TypeScript → `--lang typescript`
- Python → `--lang python`
- Rust → `--lang rust`
- Other → `--lang <user-specified>`

Invoke:

```
/the-bulwark:setup-lsp --lang <languages>
```

Follow the setup-lsp skill instructions completely. Note: setup-lsp has its own restart checkpoint at Stage 6. That restart is separate from the init restart.

### Stage 7: Write State and Finish

Write a state file for `--verify` mode to use later:

```bash
mkdir -p "$CLAUDE_PROJECT_DIR/tmp/init"
```

Write to `$CLAUDE_PROJECT_DIR/tmp/init/init-state.yaml` using the schema from [templates/init-state.yaml](templates/init-state.yaml). Populate all placeholder values with actual data from this session.

Present final summary to the user:

```
Bulwark initialization complete!

  Governance: CLAUDE.md + rules.md installed
  Statusline: [configured / skipped]
  LSP:        [configured / skipped]
  Scaffold:   [configured / skipped]

Next step: Restart your Claude Code session, then run:

  /the-bulwark:init --verify

This will confirm all components are working correctly.
```

---

## VERIFY MODE

### Stage 8: Verify Previous Init

Triggered by `--verify` flag. Reads the state file from the previous init run and checks each component.

#### 8a: Read State File

Read `$CLAUDE_PROJECT_DIR/tmp/init/init-state.yaml`. If it does not exist:

```
No init state found. Run /the-bulwark:init first to initialize Bulwark governance.
```

Stop.

#### 8b: Verify Governance Files

Check that the governance files exist at the scope recorded in the state file:

- **Project scope**: Check `./CLAUDE.md` and `./.claude/rules/rules.md`
- **User scope**: Check `~/.claude/CLAUDE.md` and `~/.claude/rules/rules.md`

Report: pass or fail for each file.

#### 8c: Verify Hooks Active

Check that hooks are firing. The simplest check: read the session's hook execution by looking for the governance protocol in the current session context. If this skill was invoked and Bulwark governance protocol was displayed at session start, hooks are active.

Report: pass or fail.

#### 8d: Verify Statusline (if selected)

If `statusline: true` in state file, check that `~/.claude/settings.json` contains statusline configuration.

Report: pass or fail.

#### 8e: Verify LSP (if selected)

If `lsp: true` in state file, invoke the LSP verification:

```
/the-bulwark:setup-lsp --verify
```

Follow the setup-lsp verification flow. Report result.

#### 8f: Verify Scaffold (if selected)

If `scaffold: true` in state file, check that:
- `Justfile` exists in the project root
- `logs/` directory exists

Report: pass or fail.

#### 8g: Verification Summary

Present results:

```
Bulwark Init Verification
=========================

  Governance files:  [PASS / FAIL]
  Hooks active:      [PASS / FAIL]
  Statusline:        [PASS / FAIL / SKIPPED]
  LSP:               [PASS / FAIL / SKIPPED]
  Scaffold:          [PASS / FAIL / SKIPPED]

  Overall: [ALL PASS / X failures]
```

If any failures, provide specific remediation steps for each.

Clean up the state file after successful verification:

```bash
rm $CLAUDE_PROJECT_DIR/tmp/init/init-state.yaml
```
