---
name: bulwark-verify
description: Generate runnable verification scripts for components. Orchestrates assertion-patterns and component-patterns to produce executable scripts.
user-invocable: true
skills:
  - assertion-patterns
  - component-patterns
---

# Bulwark Verify

## Purpose

Generate runnable verification scripts that test real component behavior without mocks.
This skill orchestrates assertion-patterns (P2.1) and component-patterns (P2.2) to produce
executable scripts for any component type.

## When to Use

**Load this skill when:**
- User requests `/bulwark-verify [path]`
- test-audit Step 7 needs verification scripts
- Generating standalone verification for a component

**DO NOT use for:**
- Running existing tests (use `just test`)
- Writing unit tests (implement directly)
- Test auditing (use `test-audit` skill)

---

## Usage

```
/bulwark-verify [path] [--execute]
```

**Examples:**
- `/bulwark-verify src/cli.ts` - Generate verification script for CLI
- `/bulwark-verify src/server.ts --execute` - Generate and run
- `/bulwark-verify` - Infer from recent context

---

## Orchestration Instructions

When this skill is loaded, follow these steps exactly:

### Step 1: Resolve Target

```
IF $ARGUMENTS provided:
    target = first non-flag argument
    execute_flag = "--execute" in $ARGUMENTS
ELSE:
    Look for component files in recent conversation context
    IF found: target = that path
    ELSE: Ask user: "Which component should I generate a verification script for?"
```

### Step 2: Detect Project Language

Check for project manifest files in order (search from target file's directory up to project root):

| Check | Language | Test Runner |
|-------|----------|-------------|
| `package.json` exists | Node | jest/vitest/node |
| `pyproject.toml` OR `setup.py` exists | Python | pytest/python |
| `Cargo.toml` exists | Rust | cargo test |
| None of the above | Generic | bash |

### Step 3: Analyze Component

1. **Read the target file**

2. **Identify component type** using indicators from `component-patterns` skill:
   - Has `spawn`/`exec`/`execSync` imports → Process Spawner
   - Has `listen()`/`createServer`/`express()`/`fastify()` → HTTP Server
   - Has `fs.readFile`/`parse` functions → File Parser
   - Has `process.argv`/`yargs`/`commander`/`argparse` → CLI Command
   - Has database imports (`pg`, `mysql`, `mongoose`, `prisma`) → Database
   - Has `fetch`/`axios`/`got`/`requests` calls → External API

3. **Load dependent skills:**
   - Load `assertion-patterns` skill content
   - Load `component-patterns` skill content

4. **Select applicable patterns:**
   - From `assertion-patterns`: Identify T1-T4 transformation patterns relevant to the component
   - From `component-patterns`: Select the matching component type template

### Step 4: Generate Script (Sonnet Sub-Agent)

Spawn sub-agent for script generation using the 4-part prompt template below:

```
Task(
    description="Generate verification script for {component_name}",
    subagent_type="general-purpose",
    model="sonnet",
    prompt=<constructed_4part_prompt>
)
```

### Step 5: Report Results

Present summary to user:

```markdown
## Verification Script Generated

**Component:** {component_path}
**Type:** {component_type}
**Language:** {language}

**Script location:** tmp/verification/{name}-verify.{ext}

**To run manually:**
```
{runner_command}
```
```

If `--execute` flag was provided:
1. Run the generated script using Bash
2. Capture output
3. Report PASS/FAIL counts
4. Show any failures with details

---

## Generation Prompt Template

Use this 4-part prompt when spawning the Sonnet sub-agent:

```markdown
## GOAL

Generate an executable verification script for `{component_path}` that tests real
component behavior without mocks. The script must verify observable output and
report clear PASS/FAIL for each test.

## CONSTRAINTS

- Language: {detected_language}
- Test runner: {runner} (e.g., jest, pytest, bash)
- Component type: {detected_type}
- MUST be directly executable: `{runner_command}`
- MUST use assertion patterns from assertion-patterns skill (real output, not mock calls)
- MUST follow component pattern from component-patterns skill ({component_type} verification)
- Include setup and teardown if component requires it
- Report clear PASS/FAIL for each verification
- Handle cleanup on both success and failure (use trap for bash, afterAll for jest, fixtures for pytest)
- Exit with code 0 on all pass, code 1 on any failure

## CONTEXT

### Component Code
```{language}
{component_content}
```

### Component Type
{detected_type}

### Applicable Assertion Patterns (from assertion-patterns)
{relevant_assertion_patterns}

### Applicable Component Pattern (from component-patterns)
{component_pattern_template}

## OUTPUT

Write script to: `tmp/verification/{component_name}-verify.{ext}`

Extension mapping:
- Node → `.test.js`
- Python → `_test.py`
- Rust → `.rs` (or `.sh` if cargo test not suitable)
- Generic → `.sh`

### Script Structure
1. Setup (create temp files, start services, initialize test DB)
2. Execute component under test
3. Verify observable output (not mock calls)
4. Report PASS/FAIL clearly for each test
5. Cleanup (kill processes, remove temp files)
6. Exit with appropriate code (0 = all pass, 1 = any fail)

### Report your actions to the log file
Write to: `logs/bulwark-verify-{YYYYMMDD-HHMMSS}.yaml`
```

---

## Output Formats

### Generated Script Location
```
tmp/verification/{component-name}-verify.{ext}
```

### Log Schema
```yaml
metadata:
  skill: bulwark-verify
  timestamp: {ISO-8601}
  model: sonnet

generation:
  target: {component_path}
  language: node|python|rust|generic
  component_type: cli|http|file-parser|process|database|api
  script_path: tmp/verification/{name}-verify.{ext}
  patterns_used:
    assertion: [T1_transformation, T2_transformation]
    component: "{component_type} verification"

execution:  # Only if --execute
  ran: true
  runner: {runner_command}
  exit_code: 0|1
  duration_ms: 1234
  results:
    pass: 3
    fail: 0
  output: |
    === Verification: {component} ===
    Test 1: Basic functionality... PASS
    Test 2: Error handling... PASS
    Test 3: Edge cases... PASS
    === All tests passed ===

summary: |
  Generated verification script for {component} ({type}).
  Script: tmp/verification/{name}-verify.{ext}
  Run with: {runner_command}
  [Execution: 3 passed, 0 failed]
```

### Diagnostic Schema
```yaml
skill: bulwark-verify
timestamp: {ISO-8601}
diagnostics:
  model_requested: sonnet
  model_actual: sonnet
  context_type: main
  language_detected: node|python|rust|generic
  component_type: cli|http|file-parser|process|database|api
  patterns_loaded:
    - assertion-patterns
    - component-patterns
  script_generated: true
  script_path: tmp/verification/{name}-verify.{ext}
  execution_requested: true|false
  execution_result: pass|fail|skipped
  completion_status: success|error
```

Write diagnostic output to: `logs/diagnostics/bulwark-verify-{YYYYMMDD-HHMMSS}.yaml`

---

## Integration with test-audit

When test-audit Step 7 invokes this skill:

1. test-audit provides the test file path and violation info
2. This skill generates a verification script as intermediate artifact
3. The script validates the rewrite approach before modifying the test
4. If verification passes, test-audit proceeds with the rewrite

**Flow:**
```
test-audit Step 7
    → Load assertion-patterns
    → Load component-patterns
    → Generate verification script (tmp/verification/)
    → Run verification script
    → If pass: Apply rewrite to test file
    → If fail: Report issue, do not rewrite
```

---

## Runner Commands by Language

| Language | Default Runner | Command |
|----------|---------------|---------|
| Node | node (built-in test) | `node --test tmp/verification/{name}-verify.test.js` |
| Node (Jest) | jest | `npx jest tmp/verification/{name}-verify.test.js` |
| Python | pytest | `pytest tmp/verification/{name}_test.py -v` |
| Rust | cargo | `cargo test --test {name}` |
| Generic | bash | `bash tmp/verification/{name}-verify.sh` |

When generating scripts, prefer the simplest runner:
- For Node: Use built-in `node --test` if no external deps needed
- For Python: Use `pytest` for better output
- For Generic: Always use bash

---

## Error Handling

### Target file not found
```
Error: Target file not found: {path}
Please provide a valid path to the component you want to verify.
```

### Language detection failed
```
Warning: Could not detect project language. Using generic (bash) templates.
To specify: /bulwark-verify {path} --lang=node
```

### Component type detection failed
```
Warning: Could not determine component type from code analysis.
Please specify: /bulwark-verify {path} --type=cli

Available types: cli, http, file-parser, process, database, api
```

### Script generation failed
```
Error: Failed to generate verification script.
Reason: {error_message}

Check logs/bulwark-verify-*.yaml for details.
```

---

## Examples

### Example 1: CLI Component
```
User: /bulwark-verify src/cli.ts

Output:
## Verification Script Generated

**Component:** src/cli.ts
**Type:** CLI Command
**Language:** Node

**Script location:** tmp/verification/cli-verify.test.js

**To run manually:**
```
node --test tmp/verification/cli-verify.test.js
```
```

### Example 2: HTTP Server with Execution
```
User: /bulwark-verify src/server.ts --execute

Output:
## Verification Script Generated

**Component:** src/server.ts
**Type:** HTTP Server
**Language:** Node

**Script location:** tmp/verification/server-verify.test.js

**Execution Results:**
```
=== HTTP Server Verification: server ===
Test 1: Health endpoint... PASS (HTTP 200)
Test 2: API response... PASS (valid JSON)
Test 3: 404 handling... PASS (HTTP 404)
=== All tests passed ===
```

**Summary:** 3 passed, 0 failed
```

### Example 3: Python Parser
```
User: /bulwark-verify src/parser.py

Output:
## Verification Script Generated

**Component:** src/parser.py
**Type:** File Parser
**Language:** Python

**Script location:** tmp/verification/parser_test.py

**To run manually:**
```
pytest tmp/verification/parser_test.py -v
```
```
