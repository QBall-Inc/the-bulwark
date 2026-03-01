# Common Pitfalls Reference

Known mistakes in Claude Code plugin packaging with severity ratings and corrections.
These are derived from real-world plugin development experience.

---

## PITFALL-1: Timeout in Milliseconds Instead of Seconds

**Severity: CRITICAL**

The single most common mistake in hooks.json. Timeout values are in SECONDS. Developers
familiar with JavaScript setTimeout (which uses milliseconds) routinely write:

```json
{ "event": "SessionStart", "script": "scripts/setup.sh", "timeout": 30000 }
```

This sets a timeout of 8.3 hours. Claude Code will hang for hours if the script fails
to complete rather than timing out in 30 seconds as intended.

**Correct:**
```json
{ "event": "SessionStart", "script": "scripts/setup.sh", "timeout": 30 }
```

**Detection rule:** Any timeout value >= 1000 is almost certainly wrong. Flag it.

---

## PITFALL-2: Distributing .claude/ Contents Instead of Root Directories

**Severity: HIGH**

Plugin.json paths pointing into `.claude/` will not distribute correctly because `.claude/`
is an internal development directory.

**Wrong:**
```json
"skills": [".claude/skills/my-skill/SKILL.md"]
```

**Correct:**
```json
"skills": ["skills/my-skill/SKILL.md"]
```

Plugin distribution copies `skills/` and `agents/` from the plugin root into the user's
`.claude/` directory. If your plugin.json points at `.claude/`, users may receive nothing
or receive incorrectly nested paths.

---

## PITFALL-3: Missing Restart Documentation

**Severity: HIGH**

Claude Code hooks do not activate until the user restarts Claude Code after installation.
This is a framework behavior, not a bug. If your README or init script does not mention
this, users will install your plugin, see no change in behavior, and assume it is broken.

**Required:** Document the restart requirement in at least one of:
- README install instructions
- Post-install echo from init script

---

## PITFALL-4: Shipping Legacy and Prototype Files

**Severity: MEDIUM to HIGH**

Prototype, draft, and deprecated files from development commonly end up in the distribution
bundle because the `package.json` `files` field includes entire directories without exclusions.

Files that should NOT ship:
- `*_old.md`, `*_bak.md`, `*_v1.md`, `*_draft.md` — superseded versions
- `*_proto.*`, `*_tmp.*` — prototype/throwaway files
- Test harness agents: files named `*-test-*`, `*-fixture-*`, `*-harness-*`
- Internal planning documents (`plans/`, `sessions/`, `logs/`)

**Detection:** Run an inventory audit (Step 2) to classify every file before distribution.

---

## PITFALL-5: Redundant CLAUDE.md Injection

**Severity: MEDIUM**

A common init script pattern copies a `CLAUDE.md` file to the project root so Claude Code
loads it. However, Claude Code already auto-loads files from `.claude/rules/` at session
start. Injecting to both locations results in duplicate rule loading and potential conflicts.

**Redundant pattern:**
```bash
cp "$CLAUDE_PLUGIN_ROOT/rules/conventions.md" "$PROJECT_DIR/CLAUDE.md"
cp "$CLAUDE_PLUGIN_ROOT/rules/conventions.md" "$PROJECT_DIR/.claude/rules/conventions.md"
```

**Correct pattern — use only .claude/rules/:**
```bash
mkdir -p "$PROJECT_DIR/.claude/rules"
cp "$CLAUDE_PLUGIN_ROOT/rules/conventions.md" "$PROJECT_DIR/.claude/rules/conventions.md"
```

If you need `CLAUDE.md` for projects that do not have `.claude/rules/` support, use it
exclusively and skip `.claude/rules/` — do not write both.

---

## PITFALL-6: Init Script Invoking claude CLI Programmatically

**Severity: HIGH**

Init scripts run during installation and should perform only filesystem operations.
Invoking `claude` from within an init script is unreliable:
- The user's Claude Code version may not support the invoked skill
- The script runs without an interactive session, so user prompts fail silently
- Errors in AI-guided steps are unrecoverable during automated install

**Wrong:**
```bash
claude -p "Run /setup-workspace to configure the project"
```

**Correct — print a checklist instead:**
```bash
echo ""
echo "Installation complete. Next steps:"
echo "  1. Restart Claude Code"
echo "  2. Run /setup-workspace to configure the project"
echo "  3. Run /validate-config to verify your settings"
```

Delegate AI-guided configuration to skills invoked interactively by the user after install.

---

## PITFALL-7: Non-Executable Hook Scripts

**Severity: HIGH**

Hook scripts referenced in hooks.json must be executable. On Linux/macOS, a newly created
script is typically not executable by default. On Windows/WSL with NTFS-mounted paths,
the executable bit may not persist through git clone.

**Fix:**
```bash
chmod +x scripts/my-hook.sh
git update-index --chmod=+x scripts/my-hook.sh
```

The `git update-index` command ensures the executable bit is committed to git, so users
who clone the repo on Linux or macOS get an executable file.

**Detection:** `ls -la scripts/` — look for `-rwxr-xr-x` (executable) vs `-rw-r--r--` (not executable).
