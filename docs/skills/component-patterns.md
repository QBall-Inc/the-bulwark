# component-patterns

Per-component-type verification approaches for CLIs, HTTP servers, parsers, databases, process spawners, and external APIs.

## Invocation and usage

`component-patterns` is a reference skill. It is not invoked directly. Load it when you need verification strategy guidance for a specific component type:

```
/the-bulwark:component-patterns
```

### Auto-invocation

`bulwark-verify` loads `component-patterns` automatically during verification script generation. The skill detects the component type from import patterns and exports, then reads the matching pattern reference file to select a verification strategy and script template for the target language.

You do not need to invoke this skill manually when using `bulwark-verify`.

## Who is it for

- Anyone extending `bulwark-verify` with a new component type.
- Developers writing verification scripts by hand who want a consistent strategy and ready-made templates.
- Teams implementing Step 7 test-audit rewrites who need per-type verification approaches.

## How it works

The skill provides two things: a detection table and a set of pattern reference files.

**Detection.** Six component types are recognized: CLI Command, HTTP Server, File Parser, Process Spawner, Database, and External API. Type is inferred from import patterns in the target file. For example, a file that imports `express` or `fastify` and calls `listen()` is classified as an HTTP Server. A file that imports `pg`, `mysql`, or `prisma` is classified as Database.

**Pattern references.** Each type maps to a reference file under `skills/component-patterns/references/`. Each reference file contains three things: a verification strategy (the approach for testing that component type), script templates in Bash, Node/Jest, and Python/pytest, and a placeholder table for substituting component-specific values.

All patterns follow the same principle: verify observable output, not mock calls. A CLI test spawns the binary and checks exit code and stdout. An HTTP server test starts the server, issues a real HTTP request, and checks the response. A database test executes operations and queries state directly. No `toHaveBeenCalled()` assertions.

| Component type | Verification strategy | Key assertion |
|---|---|---|
| CLI Command | Spawn, capture stdout/stderr | Exit code + output text |
| HTTP Server | Start, request, verify response | Status code + response body |
| File Parser | Create input, parse, check structure | Parsed fields + values |
| Process Spawner | Spawn, check port/pid, verify behavior | Process alive + responds |
| Database | Setup, execute ops, query state | Records exist or modified |
| External API | Intercept via MSW/responses, real fetch | Response data matches |
