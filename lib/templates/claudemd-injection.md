
## Binding Contract

The following commitments are **sacrosanct** and non-negotiable:

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

## Mandatory Rules

### Read Rules.md

**YOU MUST READ `Rules.md` AT THE START OF EVERY SESSION.**

This is not optional. This is not advisory. This is a binding requirement.

`Rules.md` contains the immutable rules that govern all work in this project, including:
- **SC1-SC3: Skill Compliance Rules** - When a skill is loaded, ALL instructions within it are BINDING. You MUST spawn sub-agents when instructed. You MUST NOT substitute your judgment for skill instructions.
- **T1-T4: Testing Rules** - Real behavior verification, no mock-only tests
- **V1-V4: Verification Rules** - No fix without verification
- **CS1-CS4: Coding Standards** - Atomic principles, no magic, fail fast, clean code

**Failure to read and follow Rules.md is a contract violation.**

If you find yourself thinking "I can handle this directly without following the skill instructions" - STOP. That thought pattern is explicitly prohibited by SC1-SC2 in Rules.md.

