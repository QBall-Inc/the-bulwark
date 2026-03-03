# assertion-patterns

Reference for transforming T1-T4 violating tests into real output verification.

## Invocation & usage

```
/the-bulwark:assertion-patterns
```

This skill carries no required arguments. Load it when you need the pattern library directly.

**Examples:**

```
/the-bulwark:assertion-patterns

"Show me how to convert a T2 call-only assertion to result verification."

"I have a test mocking node-fetch. What's the T3 fix pattern?"
```

### Auto-invocation

`assertion-patterns` is loaded as a context reference by two other skills:

- **test-audit** loads it during Step 7 rewrite stages. When the audit determines a test file needs rewriting, assertion-patterns provides the transformation rules Claude uses to convert each violation type.
- **bulwark-verify** loads it during script generation. When generating runnable verification scripts, bulwark-verify uses the patterns here to choose the right real-system verification approach per component type.

You rarely need to invoke this directly. It runs as background context for the skills above.

## Who is it for

- Developers rewriting mock-heavy tests flagged by test-audit who want to understand the fix patterns before applying them.
- Teams learning the T1-T4 distinction and what "real output verification" means in practice.
- Anyone writing net-new tests who wants to avoid common mock abuse patterns from the start.

## How it works

The skill is a pattern library, not a pipeline. It contains no sub-agents and produces no pipeline output on its own.

The library is organized into two layers. The first layer covers prerequisite checks (T0): whether the test file imports from real production modules, whether test files contain production logic that belongs in `src/`, and whether function naming follows test/helper conventions. Violations here mean the test is "testing nothing real" regardless of assertion style.

The second layer maps each violation type to a concrete transformation. T1 violations (mocking the system under test) are fixed by removing the mock and calling the real function. T2 violations (call-only assertions like `expect(fn).toHaveBeenCalled()`) are fixed by adding a result assertion after the call. T3 violations (mocking integration boundaries in integration tests) are fixed by substituting real infrastructure: MSW for HTTP, test database instances for DB calls, actual process spawning for child processes. T3+ violations (broken integration chains using mock data instead of real upstream output) are fixed by chaining real function outputs through the pipeline.

Each category includes before/after code examples in JavaScript and a quick-reference table mapping violation type to fix strategy.
