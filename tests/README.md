# Bulwark Tests

Test infrastructure for validating Bulwark skills and agents.

## Directory Structure

```
tests/
├── fixtures/
│   └── calculator-app/         # TypeScript app with intentional issues
│       ├── src/
│       │   ├── calculator.ts   # Source with bugs, security issues, type issues
│       │   └── calculator.test.ts  # Mix of real and mock-heavy tests
│       ├── package.json
│       ├── tsconfig.json
│       └── README.md
├── agents/                     # Test agents (proper subagent format)
│   └── test-validator.md       # Reusable test agent
└── README.md                   # This file
```

## Test Validator Agent

The `test-validator` is a proper subagent that:

1. Runs in isolated context (subagent behavior)
2. References skills via `skills:` frontmatter
3. Performs analysis tasks on fixtures
4. Writes output in structured YAML format
5. Validates skill functionality

### Setup

Copy to `.claude/agents/` for availability:

```bash
cp tests/agents/test-validator.md .claude/agents/
```

### Invocation

Ask the orchestrator (Opus) to invoke the agent:

```
Use the test-validator agent to analyze the calculator app.
Use the subagent-prompting skill to structure the invocation.

GOAL: Identify security issues in calculator-app

CONTEXT:
Target: tests/fixtures/calculator-app/src/calculator.ts
```

The orchestrator will:
1. Read subagent-prompting skill for prompt structure
2. Invoke test-validator agent via Task tool
3. Agent uses subagent-output-templating (from its skills: frontmatter)
4. Agent writes YAML output and returns summary

### Modifying for Different Skills

To test a different skill, edit `skills:` in test-validator.md:

```yaml
skills:
  - subagent-output-templating
  - {skill-to-test}
```

## Validation by Phase

| Phase | Skill | What to Validate |
|-------|-------|------------------|
| P0.2 | subagent-output-templating | YAML output format correct |
| P0.3 | pipeline-templates | Pipeline execution works |
| P0.4 | issue-debugging | Validation loop documented |
| P0.6 | test-classification | Real vs mock-heavy classification |
| P0.7 | mock-detection | Mock patterns detected |
| P0.8 | test-audit | Full audit produces YAML inventory |

## Calculator App Fixture

Contains intentional issues for testing:

| Category | Issues |
|----------|--------|
| **Bugs** | Division by zero, overflow, race condition, memory leak |
| **Security** | `eval()` usage, no input sanitization |
| **Type Safety** | `any` usage, unsafe assertions |
| **Tests** | Mix of real and mock-heavy tests, missing coverage |

See `fixtures/calculator-app/README.md` for details.

## Checking Output

```bash
# List log files
ls logs/test-validator-*.yaml
ls logs/diagnostics/test-validator-*.yaml

# Validate YAML syntax
python -c "import yaml; print(yaml.safe_load(open('logs/test-validator-XXXX.yaml')))"
```

## Success Criteria

A skill validation passes when:

1. Test-validator agent completes without error
2. Log file is valid YAML with all required sections
3. Diagnostic file written
4. Summary is 100-300 tokens
