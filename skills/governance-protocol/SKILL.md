---
name: governance-protocol
description: Session governance protocol injected at startup via SessionStart hook
user-invocable: false
---

## Bulwark Governance Protocol

This session is governed by The Bulwark quality enforcement system.

### How This Works

This skill is automatically injected into Claude's context at session start via the SessionStart hook configured in `hooks/hooks.json`. It does not need to be manually invoked. The `inject-protocol.sh` script reads this file and outputs its content to Claude's context.

### Quality Gates (Automatic)

PostToolUse hooks run after every Write/Edit operation on code files:

1. **Typecheck** - Code must pass type checking (`just typecheck`)
2. **Lint** - Code must pass linting (`just lint`)
3. **Build** - Code must compile/build (`just build`)

Failures **BLOCK** the operation. You will see error messages if quality checks fail.

### Before Declaring Complete

**Never declare implementation complete without verification:**

1. All code MUST pass quality gates (typecheck, lint, build)
2. Tests MUST verify real behavior (T1-T4 rules - no mock-only tests)
3. Changes MUST be verified by running them, not just implementing
4. If you cannot verify, say: "I've made changes but cannot verify without running [command]. Please run and confirm."

### T1-T4 Testing Rules

| Rule | Requirement |
|------|-------------|
| T1 | Never mock the system under test |
| T2 | Verify observable output, not function calls |
| T3 | Integration tests use real systems |
| T4 | Run tests before declaring complete |

### Pipeline Orchestration

For significant changes, you may be prompted to run review pipelines:
- **Code Review** - Security, type safety, coding standards
- **Test Audit** - T1-T4 compliance verification
- **Fix Validation** - Root cause analysis and fix verification

Follow pipeline instructions when prompted.

### Your Role

- Write production-grade code that passes quality checks
- Use real behavior verification in tests
- Verify implementations before declaring complete

---

## Project-Specific Rules

<!--
Users can add project-specific governance rules below.
These will be injected into Claude's context at session start.

NOTE: The core governance rules above should not be modified.
This section is for project-specific additions only.

Examples:
- Always use atomic commits with descriptive messages
- Test coverage must exceed 80%
- Security-sensitive changes require manual review
- Reference docs/architecture.md for design decisions
-->
