## Binding Contract

All work in this project is governed by @.claude/rules/rules.md. Compliance is mandatory and non-negotiable. Failure to follow any rule in Rules.md is a contract violation.

| Commitment | Requirement |
|------------|-------------|
| Rules Adherence | 100% compliance with Rules.md at all times |
| Reporting & Logging | All sub-agent outputs written to logs, all decisions documented |
| Coding Standards | Every implementation follows atomic principles and Anthropic guidelines |
| Testability | All code must be testable with real behavior verification |
| Real-World Testing | No mock-only tests for integration points |
| Verification Before Completion | No fix or feature declared complete without verification |
| Anthropic Compliance | All hooks, agents, skills, and plugins match official Anthropic guidelines |

---

## Session Startup Sequence

- Load @.claude/rules/rules.md
- Read previous session's handoff
- Read current project's tasks.yaml or project plan document [**IMPORTANT:** If unsure, ask the user to provide the file name or path]
- Read the tasklist
- Process the session handoff, overall tasks and tasks in scope for the session
- Outline the session plan to the user and ask for confirmation to begin

## In-Session Protocol

- The Bulwark governance protocol and Rules.md dictate in-session governance and need to be followed without exception to ensure quality output
- **Always** prioritize **quality**, **accuracy** and **completeness** of the task at hand over speed

## Session End Sequence

- Once the user requests or confirms a session handoff, load the session-handoff skill and follow its instructions
- Ensure CRLF characters are removed from the session handoff (Use LF/Unix line endings only)
- Present a summary of the session to the user, outlining the priorities for the next session

---

## Project Assets

<!-- Populate this table with your project's key directories and files -->

| Asset | Location | Purpose |
|-------|----------|---------|
| Plans | `plans/` | Master plan and child plans for individual workpackages |
| Sessions | `sessions/` | Session handoff documents for context continuity |
| Scripts | `scripts/` | Build, init, and utility scripts |

---

## Modes of Operation

Throughout the session, you will operate in one of two modes:

- **Implementer Mode:** Primary model directly implements all deliverables
- **Orchestrator Mode:** Primary model orchestrates sub-agents or agent teams for review/edit/focused implementations (OR1-OR3, SA1-SA6)
