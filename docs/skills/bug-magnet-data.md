# bug-magnet-data

Curated edge case test data for boundary testing, verification scripts, and test generation.

## Invocation & usage

```
/the-bulwark:bug-magnet-data
```

This skill is a reference resource loaded automatically by other skills. It is not invocable as a standalone pipeline. Direct invocation is possible but atypical: it loads the data catalog as active context so you can ask for specific edge case sets by data type or component.

**Example invocations:**

```
# Most common: loaded automatically during test-audit, bulwark-verify, or bulwark-fix-validator

# Direct: request string boundary cases for an HTTP handler
/the-bulwark:bug-magnet-data
What edge cases apply to an HTTP request body parser?

# Direct: request date edge cases for a scheduling component
/the-bulwark:bug-magnet-data
What date/time edge cases should I test for a booking API?
```

### Auto-invocation

Three skills load bug-magnet-data automatically. During test-audit rewrite stages (Step 7, edge case gap detection), it supplies pre-curated boundary inputs for identifying missing coverage. During bulwark-verify, edge cases are injected into verification scripts for the component under test. During bulwark-fix-validator, the fix is tested against boundary conditions to confirm it holds.

In all three cases, the skill maps the component type under test (CLI, HTTP, file, database, process) to a context file that determines which data categories apply. T0 data (boundaries, nulls, booleans, collections) and T1 data (unicode, special characters, injection, numeric edges) are loaded for every injection. T2 data (dates, encoding, formats, concurrency) is loaded when the context file specifies it. Patterns marked as unsafe or manual-only are excluded from automated runs.

## Who is it for

- Developers writing tests for input-handling components who want a systematic set of boundary cases rather than improvising from memory.
- Test pipelines that need deterministic, reproducible edge case sets across runs.
- Teams using bulwark-verify or fix-bug who want edge cases injected into verification scripts automatically.

## How it works

The data is organized into tiers and loaded based on component type. A component detection step maps the code under test to one of five types: CLI argument parsing, HTTP request/response, file I/O, database queries, or process spawning. Each type has a corresponding context file that lists which data categories apply.

Data is grouped into four tiers. T0 covers boundaries (empty, single, max-length), null handling, booleans, and collections. These load for every request. T1 covers injection patterns, unicode edge cases, special characters, and numeric extremes (NaN, Infinity, integer overflow). These also load every time. T2 covers dates, encoding, formats (email, URL, JSON), and concurrency patterns. These load when the context file specifies them. T3 patterns are marked `manual_only: true` and are never used in automated runs.

Each data entry carries a `safe_for_automation` flag. Destructive patterns, such as path traversal payloads or process-killing inputs, are flagged false and excluded from automated injection. They remain in the catalog for manual test design.

The catalog covers strings, numbers, booleans, collections, dates, encoding, formats, concurrency, and language-specific gotchas for JavaScript, Python, and Rust. Each entry documents which bug class it targets, so results explain why each case matters, not just what the value is.
