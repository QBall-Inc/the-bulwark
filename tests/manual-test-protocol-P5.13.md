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
| 1 | Skill loaded from `/plan-creation` invocation | PASS | |
| 2 | AskUserQuestion used to clarify scope (or noted as skipped with reason) | PASS | Mode detection + research warning asked via AskUserQuestion |
| 3 | Output directory created: `logs/plan-creation/{slug}/` | PASS | `webhook-notification-system` slug |
| 4 | subagent-prompting skill loaded | PASS | |
| 5 | Mode detected as Task tool (no AT env var prompt if var not set) | PASS | AT env var was set; user offered choice and selected Task tool |
| | **Product Owner (Stage 2)** | | |
| 6 | PO spawned as `plan-creation-po` subagent type | PASS | |
| 7 | PO explored codebase autonomously (used Glob/Grep/Read — no hardcoded paths) | PASS | |
| 8 | PO output written to `logs/plan-creation/{slug}/01-product-owner.md` | PASS | |
| 9 | PO output contains all 9 sections (Problem Statement through Open Questions) | PASS | |
| 10 | PO output references real files it discovered (not hallucinated paths) | PASS | Referenced plan/types.ts, plan-output.md template |
| | **Scrum Team (Stage 3A)** | | |
| 11 | Architect and Eng Lead spawned in **parallel** (single message, 2 Task tool calls) | PASS | |
| 12 | Both received PO output in their prompt context | PASS | |
| 13 | Architect output written to `logs/plan-creation/{slug}/02-technical-architect.md` | PASS | |
| 14 | Eng Lead output written to `logs/plan-creation/{slug}/03-eng-delivery-lead.md` | PASS | |
| 15 | Architect output covers: component decomposition, integration, design patterns, trade-offs | PASS | |
| 16 | Eng Lead output covers: WBS, effort estimates, dependency graph, milestones, risks | PASS | |
| | **QA/Critic (Stage 4)** | | |
| 17 | QA/Critic spawned with ALL 3 prior outputs (PO + Architect + Eng Lead) | PASS | |
| 18 | QA/Critic output written to `logs/plan-creation/{slug}/04-qa-critic.md` | PASS | |
| 19 | QA/Critic produced APPROVE/MODIFY/REJECT verdict | PASS | MODIFY verdict |
| 20 | QA/Critic challenged at least one assumption from a prior role | PASS | Challenged Stage 5 integration, fetch compatibility, DLQ atomicity |
| 21 | QA/Critic stress-tested Eng Lead's effort estimates | PASS | Stress-tested range: 33-43 sessions vs stated 27-29 |
| | **Synthesis & Plan (Stage 5)** | | |
| 22 | ALL 4 log files read before synthesis started | PASS | |
| 23 | Synthesis written to `logs/plan-creation/{slug}/synthesis.md` | PASS | |
| 24 | Plan draft presented to user via AskUserQuestion | PASS | |
| 25 | Final plan written to user-specified location (or default `plans/`) | PASS | `plans/webhook-notification-system-plan.md` |
| 26 | Plan has Markdown preamble (Executive Summary) + YAML body | PASS | |
| 27 | YAML body has: `version`, `project_name`, `created`, `phases[]`, `milestones[]` | PASS | |
| 28 | YAML body has: `dependency_graph` with `critical_path` and `parallel_opportunities` | PASS | |
| 29 | YAML body has: `risks[]` with severity ratings | PASS | 6 risks |
| 30 | YAML body has: `kill_criteria[]` | PASS | 3 kill criteria |
| 31 | Each phase has `workpackages[]` with id, name, description, estimated_sessions, dependencies | PASS | 13 WPs across 4 phases |
| 32 | Each milestone has id, name, phase, type (major/minor), requires[], status | PASS | 4 milestones |
| | **Diagnostics (Stage 6)** | | |
| 33 | Diagnostic YAML written to `logs/diagnostics/plan-creation-{timestamp}.yaml` | PASS | |
| 34 | Diagnostic records all 4 agents with status, model, output_file | PASS | |

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
| 1 | Agent Teams env var checked | PASS | |
| 2 | Task clarification via AskUserQuestion (or skipped with reason) | PASS | |
| 3 | Output directory created: `logs/dev-team/{slug}/` | PASS | |
| | **Task Breakdown (Stage 1)** | | |
| 4 | Tasks created on shared task list BEFORE spawning teammates | PASS | |
| 5 | Tasks have explicit dependencies (not all independent) | PASS | |
| 6 | 4-8 tasks created (not too few, not too many) | PASS | |
| | **Teammate Spawning (Stage 2)** | | |
| 7 | All 3 teammates spawned: Developer, Security Reviewer, Tester | PASS | |
| 8 | Teammates spawned using in-process mode | PASS | |
| 9 | All 3 teammates became ready before task assignment began | PASS | |
| | **Execution (Stage 3)** | | |
| 10 | Developer produced architecture plan BEFORE implementing | PASS | |
| 11 | Scrum Lead approved Developer's plan before implementation started | PASS | |
| 12 | Security Reviewer reviewed code and sent findings to Developer | PASS | |
| 13 | Tester wrote test plan and executed tests | PASS | |
| 14 | **PEER DEBATE**: Security Reviewer messaged Developer with specific issues | PASS | |
| 15 | **PEER DEBATE**: Developer acknowledged and addressed Security Reviewer findings | PASS | |
| 16 | **PEER DEBATE**: Tester messaged Security Reviewer about edge case coverage | PASS | |
| 17 | Scrum Lead intervened at least once to facilitate (prompt a teammate) | PASS | |
| 18 | Developer addressed findings from Security Reviewer and/or Tester | PASS | |
| | **Log Artifacts (SA2 Compliance)** | | |
| 19 | `01-developer-plan.md` exists and is non-empty | PASS | |
| 20 | `02-developer-summary.md` exists and is non-empty | PASS | |
| 21 | `03-security-review.md` exists with severity-rated findings | PASS | |
| 22 | `04-test-plan.md` exists with test cases | PASS | |
| 23 | `05-test-results.md` exists with pass/fail results | PASS | |
| | **Synthesis (Stage 4)** | | |
| 24 | All 5 log files read before synthesis | PASS | |
| 25 | Synthesis written to `logs/dev-team/{slug}/synthesis.md` | PASS | |
| 26 | Synthesis has "Peer Debate Highlights" section with actual debate examples | PASS | |
| 27 | Synthesis has "Observations" section on AT mechanics | PASS | |
| 28 | Synthesis presented to user | PASS | |
| | **Cleanup (Stage 5)** | | |
| 29 | Team cleaned up (all teammates shut down) | PASS | |
| 30 | Diagnostic YAML written to `logs/diagnostics/dev-team-{timestamp}.yaml` | PASS | |
| | **Code Quality** | | |
| 31 | Actual TypeScript files created (not just plans) | PASS | |
| 32 | Security Reviewer found at least 1 real vulnerability | PASS | |
| 33 | Tester found at least 1 real bug or edge case failure | PASS | |
| 34 | Final implementation addressed security findings | PASS | |

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

## TC3: Plan Creation — Agent Teams Mode

**Purpose**: Validate Stage 3B (AT mode) with the plan-creation skill. Tests AT confirmation flow, 3 mitigation patterns, shutdown gate, dual-output contract, plan versioning, and `plans/{slug}/plan_v1.md` output path. Also validates WP single-session sizing from updated Eng Lead agent.

**Prerequisites**:
1. `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set in environment
2. Plan-creation SKILL.md (with Stage 3B) synced to `.claude/skills/plan-creation/`
3. 4 agents in `.claude/agents/`
4. Fresh Claude Code session in Bulwark project

**Invocation** (same topic as TC1 for comparability):
```
/plan-creation "Add a webhook notification system that fires on plan phase transitions and milestone completions, with configurable delivery targets (Slack, email, generic HTTP POST) and retry logic for failed deliveries"
```

When prompted for mode, select **Agent Teams**. When prompted for model class, select **Opus** (or Sonnet if you want to save tokens — both are valid).

**Validation Checklist**:

| # | Check | Pass/Fail | Notes |
|---|-------|-----------|-------|
| | **Pre-Flight + AT Confirmation (Stage 1)** | | |
| 1 | Mode detection: AT env var detected, user offered AT choice | PASS | Env var detected, AskUserQuestion offered AT vs Task tool |
| 2 | RED warning banner displayed (ANSI #FF9A96 color) | PARTIAL | Banner content correct; ANSI color not rendered in terminal (cosmetic) |
| 3 | AskUserQuestion presents 3 options: Opus / Sonnet / Switch to Task tool | PASS | All 3 options presented |
| 4 | User selects Opus or Sonnet — skill proceeds with selected model class | PASS | User selected Sonnet |
| | **Product Owner (Stage 2 — same as TC1)** | | |
| 5 | PO spawned via Task tool (NOT as AT teammate) | PASS | |
| 6 | PO output written to `logs/plan-creation/{slug}/01-product-owner.md` | PASS | |
| | **Agent Teams Scrum Team (Stage 3B)** | | |
| 7 | Orchestrator reads 3 agent files from `.claude/agents/plan-creation-*.md` | PASS | |
| 8 | Orchestrator enters delegate mode (coordination only, no analysis) | PASS | |
| 9 | Shared task list created with initial tasks for all 3 roles | PASS | |
| 10 | 3 teammates spawned: Architect, Eng Lead, QA/Critic | PASS | |
| 11 | Teammates use correct model class (user's selection from step 4) | PASS | All Sonnet per diagnostics |
| 12 | In-process display mode active (no tmux) | PASS | |
| | **Dual-Output Contract** | | |
| 13 | Architect writes full analysis to `logs/plan-creation/{slug}/02-technical-architect.md` | PASS | |
| 14 | Eng Lead writes full analysis to `logs/plan-creation/{slug}/03-eng-delivery-lead.md` | PASS | |
| 15 | QA/Critic writes full analysis to `logs/plan-creation/{slug}/04-qa-critic.md` | PASS | |
| 16 | All 3 teammates sent coordination summaries to lead via mailbox | PASS | |
| | **AT Mitigation Patterns** | | |
| 17 | CC-to-lead: Lead received at least 1 summary of a peer DM exchange | PASS | |
| 18 | Task list coordination: At least 1 peer-dispatched task visible in shared list | PASS | |
| 19 | QA/Critic challenged Architect or Eng Lead via peer DM (AT quality advantage) | PASS | Challenged fetch, DLQ atomicity, config inheritance, no-caller gap |
| | **Shutdown Gate** | | |
| 20 | Lead waited for WORK COMPLETE from all 3 teammates before shutdown | PASS | Diagnostics: all 3 work_complete: true |
| 21 | No premature shutdown attempts observed | PASS | 0 stall checks sent |
| 22 | All shared tasks in terminal state before shutdown | PASS | shutdown_gate_respected: true |
| | **AT Completion + Synthesis (Stage 5)** | | |
| 23 | AMBER banner displayed after AT completion (ANSI #FFF4B0 color) | PARTIAL | Same cosmetic issue as RED banner — content correct, color not rendered |
| 24 | Stage 4 (separate QA/Critic) was SKIPPED (Critic already in AT) | PASS | |
| 25 | ALL 4 log files read before synthesis | PASS | |
| 26 | Synthesis written to `logs/plan-creation/{slug}/synthesis.md` | PASS | |
| | **Plan Versioning + Output Path** | | |
| 27 | Skill checked for existing `plans/{slug}/plan_v*.md` files | PASS | |
| 28 | Plan written to `plans/{slug}/plan_v1.md` (first plan for this topic) | PASS | `plans/webhook-notification-system/plan_v1.md` |
| 29 | Plan has Markdown preamble + YAML body | PASS | |
| 30 | YAML `version` field is `"v1"` | PASS | |
| | **WP Single-Session Sizing (Eng Lead update)** | | |
| 31 | Every WP has `estimated_sessions: 1` | PASS | All 12 WPs = 1 session |
| 32 | WPs have `confidence` field (high/medium/low) | PASS | |
| 33 | No WP description suggests multi-session scope | PASS | |
| | **Diagnostics (Stage 6)** | | |
| 34 | Diagnostic YAML written to `logs/diagnostics/plan-creation-{timestamp}.yaml` | PASS | plan-creation-20260224-143600.yaml |
| 35 | Diagnostic includes `agent_teams` section with model_class, work_complete status | PASS | model_class: sonnet, all 3 work_complete: true |
| 36 | Diagnostic includes `plan_version: "v1"` | PASS | |

**AT Mechanics Observations** (fill during testing):

| Mechanic | Worked? | Notes |
|----------|---------|-------|
| Teammate spawning (in-process) | | |
| Shared task list visible | | |
| Mailbox: Architect ↔ Eng Lead | | |
| Mailbox: QA/Critic → Architect | | |
| Mailbox: QA/Critic → Eng Lead | | |
| CC-to-lead summaries received | | |
| WORK COMPLETE from all 3 | | |
| Shutdown gate respected | | |
| No stall/premature shutdown | | |

**Quality Comparison (TC1 vs TC3)**:

| Dimension | TC1 (Task tool) | TC3 (Agent Teams) |
|-----------|-----------------|-------------------|
| Critic independence | | |
| Cross-role coherence | | |
| Plan actionability | | |
| Novel insights (not in TC1) | | |
| Token cost | | |

**Kill Criteria** (any = FAIL):
- AT env var not detected when set
- RED banner not displayed before AT confirmation
- No model class choice offered
- Teammates spawned but no peer messaging observed
- QA/Critic only produces output at the end (same as Task tool — defeats AT purpose)
- Premature shutdown (lead shuts down teammate mid-work)
- Plan not written to `plans/{slug}/plan_v1.md`
- Any of the 4 log files missing
- Orchestrator performs analysis instead of delegating

---

## Overall Assessment

### Per Test Case

| TC | Status | Kill Criteria | Notes |
|----|--------|---------------|-------|
| TC1 | **PASS** (34/34) | All clear | Session 78. Task tool mode. 13 WPs, 4 phases, MODIFY verdict. |
| TC2 | **PASS** (34/34) | All clear | Session 78. Dev-team AT mode. Revealed 3 AT coordination issues (false stall, peer DM blindness, premature shutdown) → mitigations added. |
| TC3 | **PASS** (34/36, 2 PARTIAL) | All clear | Session 80. Plan-creation AT mode. 12 WPs, 6 phases, MODIFY verdict. 2 PARTIAL = ANSI color not rendered (cosmetic). |

### AT-Specific Learnings (from TC2 + TC3)

1. **Teammate spawning**: Reliable in both TC2 and TC3. No spawn failures.
2. **Mailbox delivery**: Messages arrived. 4 peer DMs observed in TC3.
3. **Peer debate quality**: Genuine challenge — Critic challenged Architect on fetch/tsconfig, DLQ atomicity, no-caller gap. Architect and Eng Lead updated their positions in response. This is the core AT value proposition vs Task tool.
4. **Shared task list**: Worked for coordination. Shutdown gate used task terminal state as a prerequisite.
5. **In-process mode UX**: Worked on WSL2. No tmux dependency.
6. **Token cost**: TC3 ended at ~60% context. Sonnet agents kept cost reasonable.
7. **Stall behavior**: 0 stall checks in TC3 (mitigation patterns worked). TC2 had false stall detection → fixed with task-list-based coordination.
8. **Cleanup**: Clean shutdown in TC3. All 3 WORK COMPLETE received. shutdown_gate_respected: true.

### Decision Gate

- **TC1 PASS + TC2 PASS + TC3 PASS**: All gates cleared. P5.13 complete.

### Empirical AT Value Finding

AT mode produced empirically better output than Task tool mode on the same problem statement. See `docs/AT-v-SequentialTask-comparison.md` for full analysis. Key finding: peer debate enabled structural plan changes (new WPs, changed libraries, reconciled contradictions) that sequential mode could not achieve without a looped execution model.

## Results

### TC1: PASS — Session 78 (2026-02-23)
- 34/34 checks passed
- Plan: 13 WPs, 4 phases, 19-22 sessions estimated
- Critic: MODIFY verdict, 8 gaps, stress-tested to 33-43 sessions

### TC2: PASS — Session 78 (2026-02-23)
- 34/34 checks passed
- Revealed 3 AT coordination issues → 3 mitigation patterns added to plan-creation SKILL.md
- AT mechanics validated: peer messaging, shared tasks, delegate mode all functional

### TC3: PASS — Session 80 (2026-02-24)
- 34/36 checks passed, 2 PARTIAL (ANSI color cosmetic — non-blocking)
- Plan: 12 WPs, 6 phases, 9-14 sessions estimated
- Critic: MODIFY verdict, 7 gaps, 8 modifications incorporated (vs 5 in TC1)
- AT coordination: 0 stall checks, 4 peer DMs, all 3 WORK COMPLETE, shutdown gate respected
- Mandatory execution checklist fix (added Session 80) resolved Stage 1 skip from Round 1 failure
- Sonnet agents used — confirmed viable for AT mode (not just Opus)
