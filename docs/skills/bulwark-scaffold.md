# bulwark-scaffold

Generates a Justfile, logs directory structure, and optional hook configuration for a project.

## Invocation and usage

```
/the-bulwark:bulwark-scaffold [options]
```

**Options:**

| Option | Description |
|--------|-------------|
| `--force` | Overwrite an existing Justfile. Creates a timestamped backup before overwriting. |
| `--no-hooks` | Skip hook configuration. Justfile and logs are still created. |
| `--dry-run` | Preview what would be created without writing any files. |
| `--lang=<node\|python\|rust\|generic>` | Override language detection. |

**Examples:**

```
/the-bulwark:bulwark-scaffold
```

Full scaffold: Justfile, logs/, and hook configuration. Language auto-detected from project manifest.

```
/the-bulwark:bulwark-scaffold --lang=python --no-hooks
```

Python Justfile and logs directory only. No hook configuration.

```
/the-bulwark:bulwark-scaffold --dry-run
```

Preview all files that would be created. No changes written.

## Who is it for

- Developers setting up Bulwark enforcement on a project that was not initialized via `/the-bulwark:init`.
- Teams adding Bulwark to an existing project incrementally, without running full guided setup.
- Anyone who wants to re-scaffold after changing project language or resetting hook configuration.

## How it works

The skill detects your project language from manifest files (`package.json`, `pyproject.toml`, `Cargo.toml`). If none are found, it falls back to a generic template. You can override detection with `--lang`.

It then creates three things:

1. **Justfile.** Copied from a language-specific template. Includes `typecheck`, `lint`, `build`, `test`, `ci`, and `fix` recipes. If a Justfile already exists, the skill stops and asks you to pass `--force` to overwrite. A backup is created before any overwrite.

2. **logs/ directory.** Creates `logs/diagnostics/`, `logs/validations/`, and `logs/debug-reports/` with `.gitkeep` files. Appends Bulwark ignore patterns to `.gitignore` so log output stays out of version control.

3. **Hook configuration (default, skippable with `--no-hooks`).** Writes hook entries to `.claude/settings.json`: a `SessionStart` hook that injects the governance protocol, and a `PostToolUse` hook that runs quality checks after every write. Before writing, the skill checks all known hook locations for existing Bulwark hooks to prevent duplicate execution. If hooks are already present anywhere, this step is skipped automatically.

A scaffold log is written to `logs/scaffold-{timestamp}.yaml` recording what was created, what was skipped, and why.
