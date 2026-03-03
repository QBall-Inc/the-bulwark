# test-fixture-creation

Guidelines for creating unbiased test fixtures that integrate with project infrastructure and hook automation.

## Invocation & usage

```
/the-bulwark:test-fixture-creation
```

No arguments. Load this skill when you need to create fixtures for E2E or manual testing. It provides a structured workflow covering fixture design, placement, Phase 1 validation, prompt writing, and cleanup.

Common scenarios where you would load it:

- Setting up fixtures to validate a new skill end-to-end before shipping it
- Preparing a scenario that exercises the fix-bug pipeline on realistic code
- Building code samples with deliberate issues for LLM review validation

## Who is it for

- Developers setting up E2E test scenarios that need hooks to fire on real code.
- Anyone building validation fixtures for new skills or agents where the fixture author must not read the implementation.
- Teams that want fixture-authoring steps documented and cleanup tracked explicitly.

## How it works

The core principle is eliminating bias. When Claude knows a file is a test fixture, it may treat it differently, skip pipeline automation, or produce different output than it would on real code. To prevent this, fixtures are created by a Sonnet agent that has not read the implementation under test, and every fixture must look like production code with no markers, no test-referencing filenames, and no explanatory comments.

The workflow has six steps. First, plan the fixture structure by mapping skill sections to files and deciding what deliberate issues each file will contain. Second, create supporting infrastructure: stub files for imports (database clients, loggers) placed in `scripts/lib/` so fixtures compile without pulling in real dependencies. Third, write the fixture files in `scripts/components/` using realistic names like `user-service.ts` or `data-processor.ts`. Deliberate issues cover four categories: security (SQL injection, hardcoded secrets), type safety (excessive `any`, unsafe assertions), linting (poor naming, deep nesting), and coding standards (global state, mixed concerns). Fourth, run `just typecheck` and `just lint` to confirm Phase 1 passes. Fixtures that fail Phase 1 cannot reach LLM review. Fifth, write the test protocol using symptom-based, conversational prompts rather than technical instructions. Sixth, document cleanup steps so fixture files are fully removed after testing.

Fixture placement within `tsconfig.json` include paths is required for hooks to fire. Files outside those paths are invisible to the automation layer.
