# session-handoff

Creates a structured handoff document at the end of a session, capturing progress, decisions, and next steps for seamless context transfer to the next session.

## Invocation and usage

```
/the-bulwark:session-handoff          # Create a handoff for the current session
```

Invoke this when closing a session, when token consumption reaches 75%, or when the user requests a handoff. No arguments required. The skill prompts for any information it cannot infer from context.

Typical examples:

```
/the-bulwark:session-handoff          # End of session wrap-up
/the-bulwark:session-handoff          # Mid-session handoff at token budget threshold
```

## Who is it for

- Anyone running multi-session projects with Claude Code who needs continuity between sessions.
- Teams where different people (or different Claude sessions) pick up work mid-task.
- Users following the Bulwark session protocol, where handoffs are part of the governance loop.

## How it works

The skill writes a Markdown file to `sessions/session_{N}_{YYYYMMDD}.md` using LF line endings only. File naming is strict: no leading zeros on the session number, no date separators.

The output follows a fixed template with these sections:

- **YAML header.** Required for metrics collection. Records session number, date, phase, task, status, and token consumption at close.
- **Session summary.** Two to three sentences on outcomes. Focused on what was delivered, not on process.
- **What was accomplished.** Checklist of completed and incomplete items, each with a file path.
- **Files created/modified.** Table of every file touched: action, line count, and purpose.
- **Verification status.** Pass/fail for typecheck, lint, and tests.
- **Technical decisions.** Key decisions made during the session with rationale and downstream impact.
- **What's next.** Numbered list of specific, actionable steps for the next session.
- **Blockers and learnings.** Always included. Written as "None" if empty, never omitted.

Every section is required. A handoff with missing sections does not give the next session enough context to continue without additional lookup.
