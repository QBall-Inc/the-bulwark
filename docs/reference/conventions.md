# Conventions

The Bulwark enforces a specific set of conventions through `Rules.md`. When you run `/the-bulwark:init`, it installs these rules into your project at `.claude/rules/rules.md`, where Claude Code automatically loads them every session. Init also creates a `CLAUDE.md` with project-specific instructions (backing up any existing one first) and lets you choose scope — project-level (checked into the repo, shared with your team) or user-level (local to your machine, not committed).

Rules are **not advisory.** They're injected as binding instructions at session start. Claude treats them as contract obligations, not suggestions. They span twelve rule families, grouped below into the **code-quality conventions** (what your code and tests must look like) and the **workflow and governance rules** (how a Bulwark-governed session operates).

## Coding Standards (CS1–CS4)

| Rule | Name | Requirement |
|------|------|-------------|
| **CS1** | Atomic Principles | Single responsibility (one purpose only), self-contained (explicit inputs/outputs, minimal dependencies), independently verifiable (testable in isolation). |
| **CS2** | No Magic | No implicit behaviors or hidden dependencies, no undocumented side effects, all configuration explicit. |
| **CS3** | Fail Fast | Validate inputs at boundaries, return errors early (no silent failures), all errors actionable. |
| **CS4** | Clean Code | No unused imports or variables, no commented-out code blocks. If something is removed, delete it completely. |

## Testing Rules (T1–T4)

These four rules alone eliminate the most common failure modes in AI-generated test suites.

| Rule | Name | Requirement |
|------|------|-------------|
| **T1** | Never mock the system under test | The thing you're testing runs for real. |
| **T2** | Verify observable output | Tests verify results, not that functions were called. |
| **T3** | Integration tests use real systems | No mocking at integration boundaries. Use a real test harness; if one can't be set up, say so and ask for manual verification. |
| **T4** | Run tests before declaring complete | Write tests with implementation, not after. Run them, check output, verify they catch failures. |

## Verification Rules (V1–V4)

| Rule | Name | Requirement |
|------|------|-------------|
| **V1** | Never declare a fix complete without verification | If you can't verify, say so and name the command to run. |
| **V2** | Use `just` for all execution | Not npm/npx directly. If a recipe doesn't exist, create it first. |
| **V3** | Always check logs for full output | Reference the full output of `just` runs from `logs/`, not the stdout summary, before attempting a fix. |
| **V4** | Verify compilation after changes | After any code edit: `just typecheck && just lint`. Don't proceed if either fails. |

## Issue Debugging (ID1–ID3)

| Rule | Name | Requirement |
|------|------|-------------|
| **ID1** | Holistic analysis before fixing | Understand the root cause, not just the symptom. Trace the execution path, rank complexity (low/medium/high) by affected areas and failing tests. |
| **ID2** | Fix validation loop | A fix isn't complete until the root cause is documented, the fix is reviewed, tests pass at the right tier for the complexity, and no new issues are introduced. |
| **ID3** | Document the journey | Log symptoms, hypotheses tested, root cause, fix applied, and verification results. |

---

The remaining families govern *how the work proceeds* — task tracking, sub-agent orchestration, skill compliance, and the session lifecycle. They matter most once Claude starts running multi-agent pipelines (code review, test audit, fix validation) on your behalf.

## Grounding Clause (GC)

| Rule | Name | Requirement |
|------|------|-------------|
| **GC** | Validate new assets | Every new Claude Code asset (hook, skill, agent, plugin, command, MCP server) is validated with the `/anthropic-validator` skill before it's trusted. |

## Task Rules (TR1–TR3)

| Rule | Name | Requirement |
|------|------|-------------|
| **TR1** | Implementation plan required | Every task in the task list traces back to an item in an implementation plan under `plans/`. |
| **TR2** | Task identification & dependencies | Unique sequential IDs, persistent across sessions, with explicit blocking dependencies — no missing blockers, no circular chains. |
| **TR3** | Task descriptions are durable | Each task carries enough context for a future session to execute without extra lookup. Completed tasks drop; active and pending tasks carry forward. |

## Orchestrator Rules (OR1–OR3)

| Rule | Name | Requirement |
|------|------|-------------|
| **OR1** | Sub-agent model selection | Match model to complexity — Haiku for simple lookups, Sonnet (default) for review/audit/research, Opus for architecture review, novel analysis, and implementation. |
| **OR2** | Custom agent model respect | A custom sub-agent may pin its own model in frontmatter; the orchestrator respects that choice. |
| **OR3** | Pipeline syntax | F# pipe syntax expresses workflow orchestration — sequential by default, parallel where documented. |

## Sub-Agent Rules (SA1–SA6)

| Rule | Name | Requirement |
|------|------|-------------|
| **SA1** | Structured invocation | Sub-agents are invoked through the subagent-prompting skill (4-part GOAL / CONSTRAINTS / CONTEXT / OUTPUT prompting). |
| **SA2** | Structured output | Sub-agent output follows the subagent-output-templating skill, written to logs (or the agent's own declared output path). |
| **SA3** | Summaries to main context | Sub-agents return only summaries — findings, severity, next actions. Full reasoning stays in the logs. |
| **SA4** | Pipeline chaining | In a chained workflow, each agent reads the previous agent's log output. |
| **SA5** | Foreground only | Sub-agents run in the foreground — never `run_in_background` — so summaries return and full output lands in logs. |
| **SA6** | Presumed execute | Pipeline suggestions from code-writing sub-agents execute by default; deferral requires explicit user approval, never silent skipping. |

## Spec Drift Rules (SD1)

| Rule | Name | Requirement |
|------|------|-------------|
| **SD1** | Pre-WP spec drift check | Before starting or resuming a work package, the spec-drift-check skill verifies the brief's claims (file paths, line refs, function names, behavior) against current code and emits a STOP / PROCEED verdict. HIGH drift stops for user sign-off; the verified plan supersedes the original brief. |

## Skill Compliance Rules (SC1–SC3)

| Rule | Name | Requirement |
|------|------|-------------|
| **SC1** | Skill instructions are binding | Steps marked MANDATORY or REQUIRED execute in order. No substituting judgment, no skipping steps because they seem unnecessary. |
| **SC2** | Sub-agent spawning is mandatory | When a skill specifies spawning a sub-agent, Claude spawns it rather than doing the work itself — the model choice is intentional. |
| **SC3** | Skill execution verification | After a skill runs, confirm every mandatory step ran and every required output exists; any skip is documented and re-attempted. |

## Code Navigation Rules (CN1–CN2)

| Rule | Name | Requirement |
|------|------|-------------|
| **CN1** | Prefer LSP for semantic operations | Use LSP for go-to-definition, find-references, type info, symbol search, and implementation tracing. Fall back to Grep only when LSP is unavailable, returns nothing, or the target is a non-code file. |
| **CN2** | Search tool hierarchy | Code navigation: LSP > Grep > Glob. Content search: Grep > Glob. File discovery: Glob. |

## Session Rules (SR1–SR4)

| Rule | Name | Requirement |
|------|------|-------------|
| **SR1** | Session startup | Follow the startup protocol in `CLAUDE.md` (load rules, read the prior handoff, read the plan and task list, outline the session). |
| **SR2** | Token checkpoints | Status check at 50% consumption, begin wrap-up at 65%, stop and create a handoff at 75%. |
| **SR3** | Token estimation | Size each task before starting; split anything estimated to exceed 50% of the budget. |
| **SR4** | Session end protocol | Follow the handoff protocol, update the plan, commit all changes before ending, and ask before pushing to a remote. |

## Coexistence with your own rules

The Bulwark installs its rules at `.claude/rules/rules.md`. If you already have rules in `.claude/rules/`, they aren't overwritten — both load at session start and coexist. If there's a conflict, your project-specific `CLAUDE.md` instructions take precedence since they load after the rules. See the [FAQ](../faq.md) for details.

## See also

- [How it works](../guides/how-it-works.md) — rules are Layer 1 of the defense-in-depth model
- [architecture.md](../architecture.md) — the design premises (externalized QA, atomic principles, testability) behind these conventions
