---
name: plan-creation
description: Create structured implementation plans using a 4-role scrum team with optional Agent Teams peer debate
user-invocable: true
argument-hint: "<topic, filepath, or directory> [--research <synthesis-file>]"
skills:
  - subagent-prompting
---

# Plan Creation

Create structured implementation plans through a 4-role collaborative scrum team: Product Owner, Technical Architect, Engineering & Delivery Lead, and QA/Critic. The Product Owner explores the codebase first, then Architect and Eng Lead analyze in parallel, and the QA/Critic challenges everything last. The orchestrator synthesizes all outputs into a hybrid Markdown + YAML plan.

---

## When to Use This Skill

**Load this skill when the user request matches ANY of these patterns:**

| Trigger Pattern | Example User Request |
|-----------------|---------------------|
| Implementation planning | "Create an implementation plan for X" |
| Feature planning | "Plan how we'd build X" |
| Project scoping | "Break down X into phases and workpackages" |
| Post-research planning | "We've researched X, now create a plan" |
| Task brief creation | "Create a task brief for X" |

**DO NOT use for:**
- Initial topic research (use `bulwark-research` first)
- Feasibility brainstorming (use `bulwark-brainstorm`)
- Quick technical questions (ask directly)
- Code review or debugging (use `code-review` or `issue-debugging`)

---

## Dependencies

| Category | Files | Requirement | When to Load |
|----------|-------|-------------|--------------|
| **Plan output template** | `templates/plan-output.md` | **REQUIRED** | Load at Stage 4 for plan structure |
| **Critic output template** | `templates/critic-output.md` | **REQUIRED** | Include in QA/Critic agent prompt |
| **Synthesis template** | `templates/synthesis-output.md` | **REQUIRED** | Use when writing synthesis |
| **Diagnostic template** | `templates/diagnostic-output.yaml` | **REQUIRED** | Use at Stage 5 |
| **Role output reference** | `templates/role-output.md` | OPTIONAL | Reference for parsing agent outputs |
| **Subagent prompting** | `subagent-prompting` skill | **REQUIRED** | Load at Stage 1 for 4-part prompt template |
| **Research synthesis** | `--research <file>` | OPTIONAL | If provided, include in all agent prompts |

**Fallback behavior:**
- If an agent fails to spawn: Re-spawn once. If still fails, skip that role and document in synthesis under "Incomplete Coverage"
- If PO fails: STOP — all downstream agents depend on PO output. Inform user.
- If output template is missing: Use the schema from this SKILL.md directly
- If research synthesis not provided: Agents work from problem statement alone (warn user that quality may be lower)

---

## Usage

```
/plan-creation <topic-or-prompt> [--research <synthesis-file>]
/plan-creation --doc <path-to-document> [--research <synthesis-file>]
```

**Arguments:**
- `<topic-or-prompt>` - Free-text topic description or problem statement
- `--doc <path>` - Use a document as the topic source
- `--research <synthesis-file>` - Path to research synthesis (from bulwark-research or bulwark-brainstorm). Strongly recommended.

**Examples:**
- `/plan-creation "add user authentication" --research logs/research/auth/synthesis.md`
- `/plan-creation --doc plans/proposal.md`
- `/plan-creation "migrate database to PostgreSQL"`

---

## Stages

### Stage 1: Pre-Flight

```
Stage 1: Pre-Flight
├── Read problem statement / document
├── Load research synthesis if --research provided
├── AskUserQuestion if ambiguous (iterative, 2-3 questions per round)
├── Slugify topic for output directory
├── Create output directory: $PROJECT_DIR/logs/plan-creation/{slug}/
├── Load subagent-prompting skill
├── Detect mode: Task tool (default) or Agent Teams (opt-in)
└── Token budget check (warn if >30% consumed)
```

**AskUserQuestion Protocol (Pre-Spawn):**

If the problem statement is ambiguous, under-specified, or could benefit from scope boundaries:

1. Ask 2-3 clarifying questions using AskUserQuestion
2. Assess whether the answers provide sufficient clarity to construct high-quality prompts
3. If not, ask up to 3 more questions in a follow-up round
4. Repeat until clarity is achieved (no hard cap on rounds, but each round is 2-3 questions max)
5. If the problem statement is clear and well-scoped from the start, skip this step and note in diagnostics: `pre_flight_interview: skipped (problem statement sufficient)`

If `--research` was not provided, warn the user: "No research synthesis provided. Plan quality is significantly higher when preceded by `/bulwark-research` or `/bulwark-brainstorm`. Proceed without research?"

**Mode Detection:**

1. Check `$CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` env var
2. If env var is SET: offer user choice via AskUserQuestion — "Agent Teams enhanced mode is available. Use Agent Teams or Task tool?" Default to Task tool if user doesn't specify.
3. If env var is NOT SET: use Task tool mode. If user explicitly requested Agent Teams, notify: "Agent Teams requires CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1. Using Task tool mode."

### Stage 2: Product Owner (Opus, Sequential — First)

```
Stage 2: Product Owner
├── Construct prompt using 4-part template
│   ├── GOAL: Explore codebase and produce requirements analysis for {topic}
│   ├── CONSTRAINTS: Do not make architectural decisions or estimate effort
│   ├── CONTEXT: Problem statement + research synthesis (if available)
│   └── OUTPUT: $PROJECT_DIR/logs/plan-creation/{slug}/01-product-owner.md
├── Spawn plan-creation-po agent via Task tool
│   ├── subagent_type: plan-creation-po
│   ├── model: opus (specified in agent frontmatter)
│   ├── Agent autonomously explores codebase (Glob, Grep, Read)
│   └── NO hardcoded document paths — agent discovers what's relevant
├── Read PO output from logs/plan-creation/{slug}/01-product-owner.md
└── Token budget check
```

**CRITICAL — PO Autonomy**: The PO agent MUST NOT receive hardcoded project document paths. Instead:

- PO receives the problem statement and (optionally) research synthesis
- PO is spawned as `plan-creation-po` subagent type
- PO autonomously explores the codebase using Glob, Grep, Read
- PO output documents which files it read and why

This makes the skill portable across any project.

### Stage 3A: Scrum Team — Task Tool Mode

```
Stage 3A: Scrum Team (Task Tool Mode)
├── Read PO output in full
├── Construct 2 prompts using 4-part template:
│   ├── Technical Architect:
│   │   ├── GOAL: Analyze system design, components, integration, trade-offs for {topic}
│   │   ├── CONSTRAINTS: Do not estimate effort or sequence work
│   │   ├── CONTEXT: Problem statement + research synthesis + PO output (full text)
│   │   └── OUTPUT: $PROJECT_DIR/logs/plan-creation/{slug}/02-technical-architect.md
│   └── Engineering & Delivery Lead:
│       ├── GOAL: Produce WBS, estimates, dependencies, milestones, risk register for {topic}
│       ├── CONSTRAINTS: Do not redesign architecture — work with Architect's design
│       ├── CONTEXT: Problem statement + research synthesis + PO output (full text)
│       └── OUTPUT: $PROJECT_DIR/logs/plan-creation/{slug}/03-eng-delivery-lead.md
├── Spawn BOTH agents in parallel via Task tool (single message, 2 Task tool calls)
│   ├── subagent_type: plan-creation-architect (opus)
│   └── subagent_type: plan-creation-eng-lead (sonnet)
├── Read both outputs
└── Token budget check (checkpoint if >55%)
```

**CRITICAL**: Spawn both agents in a single message with 2 Task tool calls. Do NOT spawn sequentially.

**Note**: Both Architect and Eng Lead receive the PO output directly in their prompt CONTEXT. They do NOT read each other's output — they work independently in parallel. The QA/Critic cross-references their outputs in Stage 4.

### Stage 4: QA / Critic (Sonnet, Sequential — Last)

```
Stage 4: QA / Critic
├── Load templates/critic-output.md
├── Read ALL 3 prior output files:
│   ├── 01-product-owner.md
│   ├── 02-technical-architect.md
│   └── 03-eng-delivery-lead.md
├── Construct prompt using 4-part template
│   ├── GOAL: Adversarially review all prior analyses — challenge assumptions, identify gaps, stress-test estimates, produce APPROVE/MODIFY/REJECT verdict
│   ├── CONSTRAINTS: Do not redesign or re-plan — only challenge and validate
│   ├── CONTEXT: Problem statement + research synthesis + ALL 3 prior outputs (full text) + critic-output.md template
│   └── OUTPUT: $PROJECT_DIR/logs/plan-creation/{slug}/04-qa-critic.md
├── Spawn plan-creation-qa-critic agent via Task tool
│   ├── subagent_type: plan-creation-qa-critic
│   └── model: sonnet (specified in agent frontmatter)
├── Read Critic output
└── Token budget check
```

**CRITICAL**: The QA/Critic MUST receive ALL 3 prior outputs in full. This is the entire point — the Critic cross-references PO requirements against Architect components against Eng Lead workpackages to find gaps.

### Stage 5: Synthesis & Plan Output

```
Stage 5: Synthesis
├── Read ALL 4 agent output files (MANDATORY — do not skip any)
├── If any output is missing or empty → re-spawn that agent once (max 1 retry)
├── If retry fails → document gap in synthesis under "Incomplete Coverage"
├── Load templates/synthesis-output.md
├── Load templates/plan-output.md
├── Write synthesis to $PROJECT_DIR/logs/plan-creation/{slug}/synthesis.md
├── Compose plan draft:
│   ├── Executive Summary from synthesis consensus + PO problem statement
│   ├── YAML body from:
│   │   ├── Phases and workpackages: Eng Lead's WBS + Architect's component structure
│   │   ├── Milestones: Eng Lead's milestones
│   │   ├── Dependency graph: Eng Lead's dependency analysis + Architect's integration order
│   │   ├── Risks: Consolidated from all roles, prioritized by Critic
│   │   └── Kill criteria: From Critic's verdict
│   └── Apply Critic's MODIFY requirements (if verdict was MODIFY)
├── Present draft plan to user via AskUserQuestion approval gate
├── Critical Evaluation Gate (see below)
├── On approval: write final plan to user-specified location (default: plans/{slug}-plan.md)
└── Token budget check (must be <65% after synthesis)
```

**Enforcement**: Do NOT begin writing synthesis until ALL available agent outputs have been read. The orchestrator must reference every agent's output at least once in the synthesis.

#### Critical Evaluation Gate (Post-User Q&A)

After each AskUserQuestion round, do NOT blindly incorporate user responses. Instead:

**Step 1 — Classify each user response:**

| Classification | Definition | Action |
|---------------|------------|--------|
| **Preference** | Scope, priority, or UX choice (e.g., "I'd prefer v1 to focus on X", "Let's defer Y") | Incorporate directly. These are user decisions — no validation needed. |
| **Technical Claim** | Assertion about a technology, library, or API (e.g., "Library X supports this", "That API has rate limits") | **Do NOT incorporate.** Trigger Step 2. |
| **Architectural Suggestion** | Proposed structural approach (e.g., "What if we structure it as a plugin?", "We could use event sourcing") | **Do NOT incorporate.** Trigger Step 2. |

**Step 2 — For Technical Claims and Architectural Suggestions, present to user:**

> "Your suggestion about [X] involves a technical claim / architectural approach that hasn't been validated against the codebase and research. I recommend a targeted follow-up with 2 focused agents (Technical Architect + QA/Critic) to verify feasibility and stress-test the approach.
>
> This will spawn 2 agents and consume additional token budget.
>
> [Run follow-up validation / Incorporate as-is with LOW confidence caveat]"

**Step 3 — If follow-up validation approved:**

1. Spawn 2 agents in parallel (single message, 2 Task tool calls):
   - **Technical Architect** (`plan-creation-architect`) — validates the suggestion against the codebase and research
   - **QA/Critic** (`plan-creation-qa-critic`) — stress-tests the suggestion
2. Use the same 4-part prompt template (GOAL/CONSTRAINTS/CONTEXT/OUTPUT)
3. Provide both agents with: original research synthesis, PO output, and the specific user suggestion
4. Output to: `$PROJECT_DIR/logs/plan-creation/{slug}/followup-{NN}-architect.md` and `followup-{NN}-critic.md`
5. Read both outputs, then update plan with validated findings
6. Tag follow-up findings in plan with: `[Follow-up: validated]` or `[Follow-up: refuted]` or `[Follow-up: mixed — see details]`

**Step 4 — If user declines follow-up:**

Incorporate the user's suggestion into the plan with an explicit caveat:
> **[Unvalidated — user suggestion, not verified against codebase or research]**: {suggestion}

**Repeat**: After updating the plan, ask if user has additional input. Apply the same classification gate to each round. Each round with Technical Claim / Architectural Suggestion input that triggers validation consumes ~10-15% token budget (2 agents) — warn user if approaching 55%.

### Stage 6: Diagnostics (REQUIRED)

```
Stage 6: Diagnostics
├── Write diagnostic YAML to $PROJECT_DIR/logs/diagnostics/plan-creation-{YYYYMMDD-HHMMSS}.yaml
└── Verify completion checklist
```

---

## Execution Flow (F# Pipeline)

```fsharp
// Task tool mode (default)
ProductOwner(topic, research?)
|> [Architect, EngDeliveryLead](po_output)
|> QACritic(all_prior_outputs)
|> Synthesis
|> ApprovalGate
|> PlanOutput

// Agent Teams mode (enhanced, opt-in) — see Stage 3B (future)
ProductOwner(topic, research?)            // Task tool (solo)
|> AgentTeam[Architect, EngDeliveryLead, QACritic](po_output)  // Peer debate
|> Synthesis
|> ApprovalGate
|> PlanOutput
```

---

## Token Budget Management

| Checkpoint | Threshold | Action |
|------------|-----------|--------|
| After constructing PO prompt | >30% consumed | Warn user: "4 agents will consume significant context" |
| After reading Stage 3A outputs | Running tally | If approaching 55%, checkpoint with user |
| After synthesis | Must be <65% | Leave room for plan approval + session closing |
| Synthesis complete at >65% | Immediate | Write plan as-is, create handoff, do not start additional work |

If token budget is insufficient to complete all 4 agents + synthesis, inform the user and suggest splitting (e.g., "PO + Architect/Eng Lead this session, Critic + synthesis next session").

---

## Error Handling

| Scenario | Action |
|----------|--------|
| Agent returns empty output | Re-spawn once. If still empty, document gap in synthesis. |
| Agent returns truncated output | Accept as-is, note in diagnostics. |
| Agent fails to spawn | Re-spawn once. If still fails, skip role, document. |
| PO fails | STOP — subsequent agents depend on PO. Inform user. |
| Token budget exceeded mid-session | Stop spawning, synthesize from available outputs, note incomplete. |
| Research synthesis not provided | Warn user, proceed with lower quality. |
| User rejects plan draft | Ask what needs to change, re-enter Critical Evaluation Gate. |

---

## Diagnostic Output (REQUIRED)

**MANDATORY**: You MUST write diagnostic output after every invocation. This is Stage 6 and cannot be skipped.

Write to: `$PROJECT_DIR/logs/diagnostics/plan-creation-{YYYYMMDD-HHMMSS}.yaml`

**Template**: Use `templates/diagnostic-output.yaml` for the schema. Fill in actual values from the session.

---

## Completion Checklist

**IMPORTANT**: Before returning to the user, verify ALL items are complete:

- [ ] Stage 1: Pre-flight complete (topic defined, directory created, skills loaded)
- [ ] Stage 1: AskUserQuestion used if topic was ambiguous
- [ ] Stage 1: User warned if --research not provided
- [ ] Stage 1: Mode detected (Task tool or Agent Teams)
- [ ] Stage 2: Product Owner spawned (`plan-creation-po`, Opus) and output read
- [ ] Stage 2: PO explored codebase autonomously (no hardcoded paths)
- [ ] Stage 3A: Architect + Eng Lead spawned in parallel (single message, 2 Task tool calls)
- [ ] Stage 3A: Both outputs written to `$PROJECT_DIR/logs/plan-creation/{slug}/`
- [ ] Stage 4: QA/Critic spawned with ALL 3 prior outputs
- [ ] Stage 4: Critic output read, verdict noted
- [ ] Stage 5: ALL 4 outputs read before writing synthesis
- [ ] Stage 5: Synthesis written using `templates/synthesis-output.md`
- [ ] Stage 5: Plan draft composed using `templates/plan-output.md`
- [ ] Stage 5: Plan presented to user via AskUserQuestion approval gate
- [ ] Stage 5: Critical Evaluation Gate applied to all user responses
- [ ] Stage 5: Final plan written to user-specified location
- [ ] Stage 6: Diagnostic YAML written to `$PROJECT_DIR/logs/diagnostics/`

**Do NOT return to user until all checkboxes can be marked complete.**
