# bulwark-implementer

Code-writing agent that implements fixes and features following Bulwark standards, with quality gates enforced after every file write.

## Model

Claude Opus (specified in agent frontmatter).

## Invocation guidance

Best used through its parent skill, [fix-bug](../skills/fix-bug.md).

When invoked standalone, the agent requires you to supply context that the parent skill generates automatically: a debug report from the issue analyzer (fix mode) or a design document (feature mode). Without a structured debug report, the agent has no root cause to act on and no validation plan to write tests against. It will still execute, but the output will lack the precision and traceability that the pipeline provides.

Direct invocation is possible if you have a pre-existing debug report or design document:

```bash
claude -p --agent bulwark-implementer "CONTEXT: {debug_report_path: logs/issue-analyzer-T001-20250301-120000.yaml, root_cause: '...', affected_files: [src/api/orders.ts]}"
```

Run the parent skill instead when starting from scratch:

```
/the-bulwark:fix-bug
```

## What it does

The agent operates in two modes. In fix mode, it reads the debug report produced by the issue analyzer, traces the root cause through affected files, and writes the minimum change needed to address it. In feature mode, it reads a design document or inline requirements and produces an implementation with tests.

After every `Write` or `Edit` on a code file, the agent invokes `implementer-quality.sh` directly via Bash. That script runs typecheck, lint, and build checks on the modified file and returns either `QUALITY: PASSED` or `QUALITY: FAILED` with the specific gate that failed. The agent reads the output, self-corrects if needed, and retries up to three times before escalating. After all files are written, a final `just typecheck && just lint` run catches anything the per-file checks missed. Tests are written alongside implementation using patterns from the `component-patterns` skill.

## Output

| File | Contents |
|------|----------|
| `logs/implementer-{id}-{YYYYMMDD-HHMMSS}.yaml` | Implementation report: files created/modified, tests added, quality gate results, retry count, and any pipeline suggestions from `implementer-quality.sh` |
| `logs/diagnostics/bulwark-implementer-{YYYYMMDD-HHMMSS}.yaml` | Execution metadata: files read/written, hook failures, escalation status, report path |
