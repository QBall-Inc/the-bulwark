# Manual Test Protocol: P5.13 — Plan Creation + Dev Team (Agent Teams)

## Test Environment

| Test Case | Project | Skill Location | Reason |
|-----------|---------|----------------|--------|
| TC1 (plan-creation) | Bulwark (`/mnt/c/projects/the-bulwark`) | `.claude/skills/plan-creation/` (after dogfood sync) | Tests pipeline against real codebase with existing agents |
| TC2 (dev-team AT) | PM-Essentials (`/home/ashay/projects/PM-Essentials`) | `.claude/skills/dev-team/` | Clean environment, no governance hooks, isolates AT mechanics |

## Prerequisites

### TC1 — Plan Creation (Task Tool Mode)
1. Plan-creation SKILL.md + templates synced to `.claude/skills/plan-creation/` in Bulwark
2. 4 agents available in `.claude/agents/`: `plan-creation-po.md`, `plan-creation-architect.md`, `plan-creation-eng-lead.md`, `plan-creation-qa-critic.md`
3. `.claude/skills/subagent-prompting/` available (skill dependency)
4. Start a fresh Claude Code session in the Bulwark project

### TC2 — Dev Team (Agent Teams)
1. Dev-team SKILL.md present at `/home/ashay/projects/PM-Essentials/.claude/skills/dev-team/SKILL.md`
2. `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set in environment or PM-Essentials `.claude/settings.json`
3. Start a fresh Claude Code session in PM-Essentials
4. No prior team sessions active (clean state)

---

## TC1: Plan Creation — Task Tool Mode with Real Topic

**Purpose**: Validate the 4-agent sequential pipeline (PO → [Architect, Eng Lead] parallel → QA/Critic → Synthesis) produces a structured implementation plan with YAML body.

**Invocation**:
```
/plan-creation "Add a webhook notification system that fires on plan phase transitions and milestone completions, with configurable delivery targets (Slack, email, generic HTTP POST) and retry logic for failed deliveries"
```

**Why this topic**: Requires genuine codebase exploration (PO must discover existing plan infrastructure), has real architectural decisions (event system design, delivery abstraction), involves security surface (webhook URLs, auth headers, payload injection), and has enough complexity for the Eng Lead to produce a non-trivial WBS with dependencies.

**Validation Checklist**:

| # | Check | Pass/Fail | Notes |
|---|-------|-----------|-------|
| | **Pre-Flight (Stage 1)** | | |
| 1 | Skill loaded from `/plan-creation` invocation | | |
| 2 | AskUserQuestion used to clarify scope (or noted as skipped with reason) | | |
| 3 | Output directory created: `logs/plan-creation/{slug}/` | | |
| 4 | subagent-prompting skill loaded | | |
| 5 | Mode detected as Task tool (no AT env var prompt if var not set) | | |
| | **Product Owner (Stage 2)** | | |
| 6 | PO spawned as `plan-creation-po` subagent type | | |
| 7 | PO explored codebase autonomously (used Glob/Grep/Read — no hardcoded paths) | | |
| 8 | PO output written to `logs/plan-creation/{slug}/01-product-owner.md` | | |
| 9 | PO output contains all 9 sections (Problem Statement through Open Questions) | | |
| 10 | PO output references real files it discovered (not hallucinated paths) | | |
| | **Scrum Team (Stage 3A)** | | |
| 11 | Architect and Eng Lead spawned in **parallel** (single message, 2 Task tool calls) | | |
| 12 | Both received PO output in their prompt context | | |
| 13 | Architect output written to `logs/plan-creation/{slug}/02-technical-architect.md` | | |
| 14 | Eng Lead output written to `logs/plan-creation/{slug}/03-eng-delivery-lead.md` | | |
| 15 | Architect output covers: component decomposition, integration, design patterns, trade-offs | | |
| 16 | Eng Lead output covers: WBS, effort estimates, dependency graph, milestones, risks | | |
| | **QA/Critic (Stage 4)** | | |
| 17 | QA/Critic spawned with ALL 3 prior outputs (PO + Architect + Eng Lead) | | |
| 18 | QA/Critic output written to `logs/plan-creation/{slug}/04-qa-critic.md` | | |
| 19 | QA/Critic produced APPROVE/MODIFY/REJECT verdict | | |
| 20 | QA/Critic challenged at least one assumption from a prior role | | |
| 21 | QA/Critic stress-tested Eng Lead's effort estimates | | |
| | **Synthesis & Plan (Stage 5)** | | |
| 22 | ALL 4 log files read before synthesis started | | |
| 23 | Synthesis written to `logs/plan-creation/{slug}/synthesis.md` | | |
| 24 | Plan draft presented to user via AskUserQuestion | | |
| 25 | Final plan written to user-specified location (or default `plans/`) | | |
| 26 | Plan has Markdown preamble (Executive Summary) + YAML body | | |
| 27 | YAML body has: `version`, `project_name`, `created`, `phases[]`, `milestones[]` | | |
| 28 | YAML body has: `dependency_graph` with `critical_path` and `parallel_opportunities` | | |
| 29 | YAML body has: `risks[]` with severity ratings | | |
| 30 | YAML body has: `kill_criteria[]` | | |
| 31 | Each phase has `workpackages[]` with id, name, description, estimated_sessions, dependencies | | |
| 32 | Each milestone has id, name, phase, type (major/minor), requires[], status | | |
| | **Diagnostics (Stage 6)** | | |
| 33 | Diagnostic YAML written to `logs/diagnostics/plan-creation-{timestamp}.yaml` | | |
| 34 | Diagnostic records all 4 agents with status, model, output_file | | |

**Quality Dimensions**:

| Dimension | Question | Rating (1-5) |
|-----------|----------|---------------|
| **PO codebase exploration** | Did PO discover relevant files without hardcoded paths? | |
| **Role separation** | Did each role stay in its lane (PO=requirements, Architect=design, Eng Lead=scheduling)? | |
| **Critic independence** | Did Critic find issues not raised by other roles? | |
| **Plan actionability** | Could a developer use this plan to start implementing? | |
| **YAML structure** | Is the YAML well-formed and parseable? | |
| **Cross-role coherence** | Do Architect components map to Eng Lead workpackages? | |

**Kill Criteria** (any = FAIL):
- PO given hardcoded file paths in prompt (portability violation)
- Architect and Eng Lead spawned sequentially instead of parallel
- QA/Critic not given all 3 prior outputs
- No YAML body in plan output
- Orchestrator writes plan without presenting to user first
- Any agent output file missing from `logs/plan-creation/{slug}/`

---

## TC2: Dev Team — Agent Teams Peer Debate on Real Implementation

**Purpose**: Validate Agent Teams mechanics (teammate spawning, mailbox peer messaging, shared task list, in-process mode) using a real implementation task that exercises all 3 roles meaningfully.

**Task: URL Shortener CLI Tool**

A command-line URL shortener that stores mappings in a local file, generates short slugs, and resolves them back to original URLs.

**Why this task**:
- **Security surface**: open redirect vulnerabilities, URL validation (malformed URLs, javascript: schemes, data: URIs), slug injection, path traversal in storage file, SSRF if URL resolution is added
- **Genuine edge cases**: unicode/IDN domains, duplicate slug collisions, maximum URL length, empty/null inputs, concurrent access to storage file, expired links
- **Architectural decisions**: storage format (JSON vs SQLite vs flat file), slug algorithm (random vs hash vs sequential), URL normalization strategy, error handling approach — gives the Developer real choices for the Security Reviewer to challenge
- **Not a tutorial project**: Claude won't recognize this as a standard test fixture, reducing memorized-response bias

**Invocation**:
```
/dev-team Build a URL shortener CLI tool in TypeScript. It should support: creating short URLs with custom or auto-generated slugs, resolving short URLs back to originals, listing all stored mappings, and deleting expired links. Storage should be file-based (no external database). Include input validation and error handling.
```

**Validation Checklist**:

| # | Check | Pass/Fail | Notes |
|---|-------|-----------|-------|
| | **Pre-Flight** | | |
| 1 | Agent Teams env var checked | | |
| 2 | Task clarification via AskUserQuestion (or skipped with reason) | | |
| 3 | Output directory created: `logs/dev-team/{slug}/` | | |
| | **Task Breakdown (Stage 1)** | | |
| 4 | Tasks created on shared task list BEFORE spawning teammates | | |
| 5 | Tasks have explicit dependencies (not all independent) | | |
| 6 | 4-8 tasks created (not too few, not too many) | | |
| | **Teammate Spawning (Stage 2)** | | |
| 7 | All 3 teammates spawned: Developer, Security Reviewer, Tester | | |
| 8 | Teammates spawned using in-process mode | | |
| 9 | All 3 teammates became ready before task assignment began | | |
| | **Execution (Stage 3)** | | |
| 10 | Developer produced architecture plan BEFORE implementing | | |
| 11 | Scrum Lead approved Developer's plan before implementation started | | |
| 12 | Security Reviewer reviewed code and sent findings to Developer | | |
| 13 | Tester wrote test plan and executed tests | | |
| 14 | **PEER DEBATE**: Security Reviewer messaged Developer with specific issues | | |
| 15 | **PEER DEBATE**: Developer acknowledged and addressed Security Reviewer findings | | |
| 16 | **PEER DEBATE**: Tester messaged Security Reviewer about edge case coverage | | |
| 17 | Scrum Lead intervened at least once to facilitate (prompt a teammate) | | |
| 18 | Developer addressed findings from Security Reviewer and/or Tester | | |
| | **Log Artifacts (SA2 Compliance)** | | |
| 19 | `01-developer-plan.md` exists and is non-empty | | |
| 20 | `02-developer-summary.md` exists and is non-empty | | |
| 21 | `03-security-review.md` exists with severity-rated findings | | |
| 22 | `04-test-plan.md` exists with test cases | | |
| 23 | `05-test-results.md` exists with pass/fail results | | |
| | **Synthesis (Stage 4)** | | |
| 24 | All 5 log files read before synthesis | | |
| 25 | Synthesis written to `logs/dev-team/{slug}/synthesis.md` | | |
| 26 | Synthesis has "Peer Debate Highlights" section with actual debate examples | | |
| 27 | Synthesis has "Observations" section on AT mechanics | | |
| 28 | Synthesis presented to user | | |
| | **Cleanup (Stage 5)** | | |
| 29 | Team cleaned up (all teammates shut down) | | |
| 30 | Diagnostic YAML written to `logs/diagnostics/dev-team-{timestamp}.yaml` | | |
| | **Code Quality** | | |
| 31 | Actual TypeScript files created (not just plans) | | |
| 32 | Security Reviewer found at least 1 real vulnerability | | |
| 33 | Tester found at least 1 real bug or edge case failure | | |
| 34 | Final implementation addressed security findings | | |

**Agent Teams Mechanics Observations** (fill during testing):

| Mechanic | Worked? | Notes |
|----------|---------|-------|
| Teammate spawning (in-process) | | |
| Shared task list visible (Ctrl+T) | | |
| Task dependencies respected | | |
| Mailbox: Developer → Security Reviewer | | |
| Mailbox: Security Reviewer → Developer | | |
| Mailbox: Tester → Developer | | |
| Mailbox: Security Reviewer → Tester | | |
| Plan approval gate | | |
| Stall detection needed? | | |
| Team cleanup | | |
| In-process navigation (Shift+Down) | | |

**Kill Criteria** (any = FAIL):
- Agent Teams env var missing and skill proceeds anyway
- No peer messaging observed between any teammates (AT's core differentiator)
- Teammates spawned but never interact — just produce independent outputs (Task tool behavior, not AT)
- Any log artifact missing from `logs/dev-team/{slug}/`
- Scrum Lead implements code directly instead of delegating to Developer teammate
- Team not cleaned up after completion

---

## Overall Assessment

### Per Test Case

| TC | Status | Kill Criteria | Quality Avg | Notes |
|----|--------|---------------|-------------|-------|
| TC1 | | | | |
| TC2 | | | | |

### AT-Specific Learnings (from TC2)

Document these to inform T-010 (adding AT mode to plan-creation):

1. **Teammate spawning**: How reliable? Any failures?
2. **Mailbox delivery**: Did messages arrive? Any lag or drops?
3. **Peer debate quality**: Did teammates genuinely challenge each other, or just produce parallel outputs?
4. **Shared task list**: Did dependencies work? Did self-claiming work?
5. **In-process mode UX**: Usable on WSL2? Navigation smooth?
6. **Token cost**: Approximate total tokens for a 3-teammate session?
7. **Stall behavior**: Did any teammate stall? How was it resolved?
8. **Cleanup**: Was team cleanup smooth or did orphan processes remain?

### Decision Gate

- **TC1 PASS + TC2 PASS**: Proceed with T-010 (AT mode for plan-creation), T-011 (sync), T-012 (validator)
- **TC1 PASS + TC2 FAIL**: Ship plan-creation with Task tool mode only. Defer AT mode. Document AT failures for P5.15.
- **TC1 FAIL**: Fix plan-creation Task tool mode before any AT work. Re-test.
- **TC2 PARTIAL**: If AT mechanics work but peer debate is shallow, consider whether plan-creation AT mode adds enough value over Task tool mode to justify the complexity.

## Results

*To be filled during testing*
