# bulwark-verify

Generates runnable verification scripts for components by orchestrating assertion-patterns and component-patterns against the real component code.

## Invocation and usage

```
/the-bulwark:bulwark-verify [path] [--execute]
```

**Arguments:**

| Argument | Description |
|----------|-------------|
| `[path]` | Optional. Path to the component file to verify. If omitted, the skill infers the target from recent conversation context. |
| `--execute` | Optional. Run the generated script immediately after generating it and report PASS/FAIL results. |

**Examples:**

```
/the-bulwark:bulwark-verify src/cli.ts
```
Generates a verification script for a CLI component. Detects the component type, loads edge case data, and writes the script to `tmp/verification/`.

```
/the-bulwark:bulwark-verify src/server.ts --execute
```
Generates and immediately runs the verification script. Reports PASS/FAIL for each test case.

```
/the-bulwark:bulwark-verify src/parser.py
```
Generates a pytest verification script for a Python file parser. Detects the language from `pyproject.toml` or `setup.py`.

## Who is it for

- Developers who need a standalone verification script for a single component without writing one from scratch.
- Teams working through a test-audit that flags T1-T4 violations and need to validate the rewrite approach first.
- Anyone who wants edge case coverage (boundaries, injection patterns, unicode) baked in automatically.

## How it works

The skill detects the project language (Node, Python, Rust, or generic bash) by scanning for manifest files. It reads the target file, classifies the component type (CLI, HTTP server, file parser, database, process spawner, or external API), and loads the matching patterns and edge case data from three reference skills: `assertion-patterns`, `component-patterns`, and `bug-magnet-data`.

A Sonnet sub-agent handles script generation. It receives the component code, the applicable assertion and component patterns, and curated edge cases (T0 boundary values always; T1 input patterns when applicable). The sub-agent writes the script to `tmp/verification/{component-name}-verify.{ext}`. After generation, the orchestrator validates syntax before surfacing the result. Destructive test patterns (marked `safe_for_automation: false`) are excluded from the runnable script and included as commented-out manual test stubs.

Scripts persist in `tmp/verification/` for inspection. The directory is in `.gitignore` and is not committed. To clean up: `rm -rf tmp/verification/*`.

## Output

| File | Description |
|------|-------------|
| `tmp/verification/{name}-verify.{ext}` | Generated verification script. Extension matches the detected language (`.test.js`, `_test.py`, `.sh`). |
| `logs/bulwark-verify-{YYYYMMDD-HHMMSS}.yaml` | Generation log. Contains component type, language, patterns used, and execution results if `--execute` was passed. |
| `logs/diagnostics/bulwark-verify-{YYYYMMDD-HHMMSS}.yaml` | Diagnostic log. Records model used, patterns loaded, and completion status. |
| Console output | Script location, the command to run it manually, and PASS/FAIL counts if `--execute` was used. |
