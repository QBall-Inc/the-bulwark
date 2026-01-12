# The Bulwark - Master Plan Document

*Version 2.0 - January 8, 2026*
*Updated for Claude Code 2.1.1 capabilities*

---

## Document History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-04 | Initial plan |
| 2.0 | 2026-01-08 | Claude Code 2.1.1 integration: agents as skills with `context: fork`, Ralph Wiggum loops, diagnostic testing |

---

## 1. Project Overview

### 1.1 Problem Statement

AI coding agents suffer from fundamental quality issues:

1. **Entropy Drift**: Code quality degrades as context fills and complexity increases
2. **Semantic vs Engineering Compliance**: Agents satisfy requests literally but fail engineering requirements
3. **Self-Review Bias**: Agents cannot objectively review code they generated in the same context
4. **Mock-Heavy Testing**: Agents write tests that verify mocks, not actual system behavior
5. **Fix-Declare-Done Pattern**: Fixes declared complete without verification

### 1.2 Solution

The Bulwark is a Claude Code plugin implementing "Defense-in-Depth" quality governance:

- **Hooks**: Deterministic enforcement via PostToolUse (Exit 2 blocking)
- **Sub-Agents**: Isolated context specialists with structured output
- **Skills**: Progressive disclosure of heuristics and patterns
- **Pipeline Orchestration**: F# pipe syntax for complex workflows
- **`just`**: Deterministic command interface with log-based output

### 1.3 Design Principles

1. **Externalized Quality Assurance**: QA happens outside the generating context
2. **Atomic Principles**: Single responsibility, self-contained, independently verifiable
3. **Deterministic Enforcement**: Scripts and validators don't hallucinate
4. **Log-Based Output**: Full output to logs, summaries to context
5. **Pipeline Orchestration**: Declarative F# syntax for multi-agent workflows
6. **Anthropic Compliance**: All implementations match official guidelines

---

## 2. Architecture

### 2.1 Defense-in-Depth Model

```
┌─────────────────────────────────────────────────────────────┐
│                    OUTER RING: HOOKS                        │
│  PostToolUse enforcement - lint/typecheck errors blocked    │
│  Exit Code 2 = blocking error injected into agent context   │
├─────────────────────────────────────────────────────────────┤
│                  MIDDLE RING: SUB-AGENTS                    │
│  Specialists review in isolated context, return via logs    │
│  Pipeline orchestration via F# pipe syntax                  │
├─────────────────────────────────────────────────────────────┤
│                   INNER RING: SKILLS                        │
│  Heuristics loaded on-demand via progressive disclosure     │
│  Composite skills orchestrate atomic skills                 │
├─────────────────────────────────────────────────────────────┤
│                    CORE: EXECUTION                          │
│  `just` command runner for deterministic invocation         │
│  Output to logs, summary to agent context                   │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Sub-Agents (Implemented as Skills)

**Claude Code 2.1.1 Update:** Agents are implemented as skills with `context: fork` for isolated execution. This directly supports Design Principle #1 (Externalized Quality Assurance) - the agent operates in an isolated context, reviews code it didn't generate, and returns findings.

| Agent | Purpose | Skills Used | Model |
|-------|---------|-------------|-------|
| `bulwark-test-auditor` | Reviews tests for real behavior verification | test-audit | sonnet |
| `bulwark-issue-debugger` | Holistic debugging with validation loops | issue-debugging | sonnet |
| `bulwark-code-auditor` | Reviews code for quality, security, SOLID | code-review, security-heuristics | sonnet |
| `bulwark-implementer` | Executes plans following Bulwark standards | component-patterns | sonnet |

**Agent Frontmatter Pattern:**
```yaml
---
name: bulwark-agent-name
description: What this agent does
context: fork                    # Isolated execution (2.1.1)
agent: sonnet                    # Model selection (2.1.1)
skills:
  - skill1
  - skill2
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
hooks:                           # Agent-scoped hooks (2.1.1)
  - event: Stop
    command: "${CLAUDE_PLUGIN_ROOT}/scripts/agents/finalize.sh"
user-invocable: true
---
```

### 2.3 Pipeline Orchestration

Sub-agents cannot invoke other sub-agents. Main thread orchestrates using F# pipe syntax:

```fsharp
// Code Review Pipeline
CodeAuditor (security)
|> CodeAuditor (architecture)
|> TestAuditor (coverage)
|> (if findings > 0 then IssueDebugger else Done)

// Fix Validation Pipeline
IssueDebugger (root cause)
|> Implementer (fix)
|> CodeAuditor (review)
|> TestAuditor (verify)
|> (if issues > 0 then IssueDebugger else Done)

// Test Audit Pipeline
TestAuditor (classify)
|> (if mock_heavy > 0 then VerificationScriptCreator else Done)
|> Implementer (rewrite)
|> TestAuditor (re-verify)
```

### 2.4 Skills Architecture

**Claude Code 2.1.1 Frontmatter Fields:**

| Field | Purpose | Values |
|-------|---------|--------|
| `context` | Execution context | `fork` (isolated) or omit (main) |
| `agent` | Model selection | `haiku` (simple), `sonnet` (complex) |
| `user-invocable` | Slash menu visibility | `true` (user-facing), `false` (internal) |
| `hooks` | Lifecycle hooks | Array of hook objects |

#### Phase 0 Skills (Foundational Workflow) - Internal

| Skill | Purpose | Model | User-Invocable |
|-------|---------|-------|----------------|
| `subagent-prompting` | 4-part template (GOAL/CONSTRAINTS/CONTEXT/OUTPUT) | - | `false` |
| `subagent-output-templating` | Structured log output, task completion reports | - | `false` |
| `pipeline-templates` | Pre-defined F# pipe workflows | - | `false` |
| `issue-debugging` | Holistic fix with validation loop | - | `false` |
| `anthropic-validator` | Validate against official guidelines (2.1.1 updated) | - | `false` |

#### Test Audit Skills (Phase 0) - Pattern Matching

| Skill | Purpose | Model | User-Invocable |
|-------|---------|-------|----------------|
| `test-classification` | Criteria for real vs mock-based tests | `haiku` | `false` |
| `mock-detection` | Patterns indicating mock-heavy tests | `haiku` | `false` |
| `test-audit` | Audit tests, produce YAML inventory | `sonnet` | `true` |

#### Verification Skills (Phase 2)

| Skill | Purpose | Model | User-Invocable |
|-------|---------|-------|----------------|
| `assertion-patterns` | Real output verification patterns | - | `false` |
| `component-patterns` | Per-component-type verification | - | `false` |
| `verification-script` | Create runnable verification scripts | `sonnet` | `true` |

#### Review Skills (Phase 4)

| Skill | Purpose | Model | User-Invocable |
|-------|---------|-------|----------------|
| `security-heuristics` | OWASP checks, injection patterns | `sonnet` | `false` |
| `type-safety` | Type safety review patterns | `sonnet` | `false` |
| `bug-magnet-data` | Edge case data for test injection | `haiku` | `false` |
| `code-review` | Comprehensive code review | `sonnet` | `true` |

#### Evolution Skills (Phase 5)

| Skill | Purpose | Model | User-Invocable |
|-------|---------|-------|----------------|
| `continuous-feedback` | Skill enhancement from learnings | - | `false` |
| `skill-creator` | Create new skills following Bulwark patterns | `sonnet` | `true` |
| `agent-creator` | Create new agents as skills with `context: fork` | `sonnet` | `true` |

---

## 3. Phase Plan

**Schedule Rationale**: "Both" rules (T1-T4, SA1-SA5, ID1-ID4) are scheduled early so their encoded skills/agents are available during development.

### Phase 0: Foundation & Test Audit Skills

**Goal**: Create workflow skills + test audit skills (T1-T4 rules encoded here)

| Task | Deliverable | Dependencies |
|------|-------------|--------------|
| P0.1 | `subagent-prompting` skill | None |
| P0.2 | `subagent-output-templating` skill | P0.1 |
| P0.3 | `pipeline-templates` skill | P0.1, P0.2 |
| P0.4 | `issue-debugging` skill | P0.1, P0.2 |
| P0.5 | `anthropic-validator` skill | None |
| P0.6 | `test-classification` skill | None |
| P0.7 | `mock-detection` skill | P0.6 |
| P0.8 | `test-audit` composite skill | P0.6, P0.7 |

**Exit Criteria**:
- Sub-agent invocations follow 4-part template
- Output goes to logs with structured format
- Pipeline workflows can be defined and executed
- Issue fixes go through validation loop
- Implementations can be validated against Anthropic guidelines
- Can audit test suites and produce YAML inventory

### Phase 1: Early Agents (as Skills with `context: fork`)

**Goal**: Test auditor and issue debugger available for rest of development

**2.1.1 Update:** Agents implemented as skills in `skills/` directory with `context: fork` frontmatter.

| Task | Deliverable | Dependencies |
|------|-------------|--------------|
| P1.1 | `skills/bulwark-test-auditor/SKILL.md` | P0.8, P0.1 |
| P1.2 | `skills/bulwark-issue-debugger/SKILL.md` | P0.4 |

**Exit Criteria**:
- Test auditor runs in forked context (`context: fork`)
- Test auditor can classify tests and produce YAML inventory
- Issue debugger runs in forked context
- Issue debugger enforces validation loop
- Both write diagnostic output for behavioral testing

### Phase 2: Verification Scripts

**Goal**: Skills for creating verification scripts

| Task | Deliverable | Dependencies |
|------|-------------|--------------|
| P2.1 | `assertion-patterns` skill | None |
| P2.2 | `component-patterns` skill | None |
| P2.3 | `verification-script` composite skill | P2.1, P2.2 |

**Exit Criteria**:
- Can create verification scripts for components
- Scripts report pass/fail

### Phase 3: Enforcement Infrastructure

**Goal**: Create hooks and `just` integration

| Task | Deliverable | Dependencies |
|------|-------------|--------------|
| P3.1 | Justfile templates (Node, Python, Rust) | None |
| P3.2 | `/bulwark:scaffold` command | P3.1 |
| P3.3 | `enforce-quality.sh` script | P3.1 |
| P3.4 | PostToolUse hook configuration (global) | P3.3 |
| P3.5 | SessionStart protocol injection (`once: true`) | None |

**2.1.1 Hook Strategy:**
- **Global hooks** (hooks.json): PostToolUse enforcement, SessionStart protocol
- **Agent-scoped hooks** (frontmatter): Stop hooks for individual agents

**Exit Criteria**:
- PostToolUse blocks on typecheck/lint failures
- SessionStart fires exactly once per session (`once: true`)
- Sessions start with governance protocol
- `just` commands work with log-based output

### Phase 4: Review Skills & Remaining Agents (as Skills)

**Goal**: Review skills and code auditor/implementer agents

**2.1.1 Update:** Remaining agents implemented as skills with `context: fork`.

| Task | Deliverable | Dependencies |
|------|-------------|--------------|
| P4.1 | `skills/security-heuristics/SKILL.md` | None |
| P4.2 | `skills/type-safety/SKILL.md` | None |
| P4.3 | `skills/bug-magnet-data/SKILL.md` | None |
| P4.4 | `skills/code-review/SKILL.md` | P4.1, P4.2 |
| P4.5 | `skills/bulwark-code-auditor/SKILL.md` | P4.4, P0.1 |
| P4.6 | `skills/bulwark-implementer/SKILL.md` | P0.1 |

**Exit Criteria**:
- Code auditor runs in forked context (`context: fork`)
- Code auditor reviews code, returns findings (never fixes)
- Implementer runs in forked context with agent-scoped PostToolUse hook
- Implementer follows Bulwark standards
- Both write diagnostic output for behavioral testing

### Phase 5: Commands, Evolution, and Polish

**Goal**: User-facing commands and evolution tools

| Task | Deliverable | Dependencies |
|------|-------------|--------------|
| P5.1 | `/bulwark:audit` command | P0.8 |
| P5.2 | `/bulwark:verify` command | P2.3 |
| P5.3 | `continuous-feedback` skill | P0.2 |
| P5.4 | `skill-creator` skill | P5.3 |
| P5.5 | `agent-creator` skill | P5.3 |
| P5.6 | Plugin manifest finalization | All above |
| P5.7 | Rollout documentation | All above |

**Exit Criteria**:
- Plugin installable via Claude Code mechanism
- Can create new skills and agents
- Documentation complete

---

## 4. Skill Specifications

### 4.1 subagent-prompting (P0.1)

**Purpose**: Template for invoking sub-agents with deterministic inputs

**Content Structure**:
```markdown
# Sub-Agent Prompting Template

## 4-Part Template (Required)

### GOAL (What Success Looks Like)
[High-level objective, NOT just the action]
Example: "Refactor authentication for maintainability"
NOT: "Refactor the auth file"

### CONSTRAINTS (What You Cannot Do)
- [Boundary 1: dependency policy]
- [Boundary 2: compatibility requirements]
- [Boundary 3: performance thresholds]

### CONTEXT (What You Need to Know)
- Relevant files and their purpose
- Architecture decisions that apply
- Current state from previous agents (if pipeline)

### OUTPUT (What to Deliver)
- Primary artifact (code/docs/tests)
- Log file location
- Summary format for main thread

## Pipeline Syntax (F#)
AgentA |> AgentB |> (if condition then AgentC else Done)
```

### 4.2 subagent-output-templating (P0.2)

**Purpose**: Structured output format for sub-agent results

**Content Structure**:
```markdown
# Sub-Agent Output Template

## Log File Format
Location: logs/{agent-name}-{timestamp}.md

### Task Completion Report

#### WHY (Problem & Solution Rationale)
- Problem: [What was broken/missing]
- Root Cause: [Why it happened]
- Solution: [What we implemented]

#### WHAT (Changes Made)
| File | Lines | Change |
|------|-------|--------|
| path | range | description |

#### TRADE-OFFS
- Gained: [benefits]
- Cost: [drawbacks]

#### RISKS
- Risk: [description]
- Mitigation: [how addressed]

#### NEXT STEPS
- [ ] Follow-up action 1
- [ ] Follow-up action 2

## Summary for Main Thread
[200 tokens max - key findings only]
```

### 4.3 pipeline-templates (P0.3)

**Purpose**: Pre-defined F# pipe workflows for common scenarios

**Content Structure**:
```markdown
# Pipeline Templates

## Code Review Pipeline
CodeAuditor (security)
|> CodeAuditor (architecture)
|> TestAuditor (coverage)
|> (if findings > 0 then IssueDebugger else Done)

## Fix Validation Pipeline
IssueDebugger (analyze)
|> Implementer (fix)
|> CodeAuditor (review)
|> TestAuditor (verify)
|> (if issues > 0 then IssueDebugger else Done)

## Test Audit Pipeline
TestAuditor (classify)
|> (if mock_heavy > 0 then VerificationScriptCreator else Done)
|> Implementer (rewrite)
|> TestAuditor (re-verify)

## New Feature Pipeline
Investigation
|> Implementer (code)
|> TestAuditor (gaps)
|> Implementer (tests)
|> CodeAuditor (final)
```

**Development Hooks (P0.3):**

Pipeline validation requires global hooks for deterministic skill loading:

| Hook | Script | Purpose |
|------|--------|---------|
| PreToolUse (Task) | `scripts/hooks/validate-pipeline.sh` | Validate pipeline usage, inject guidance |
| SubagentStart | `scripts/hooks/track-pipeline-start.sh` | Track pipeline stage start |
| SubagentStop | `scripts/hooks/track-pipeline-stop.sh` | Track completion, support branching |

- Configured in `.claude/settings.json` for development
- Migrated to `hooks/hooks.json` in P3.4 for plugin deployment
- Single-agent tasks (explore, lookup) bypass validation silently

### 4.4 anthropic-validator (P0.5)

**Purpose**: Validate implementations against official Anthropic guidelines

**Content Structure**:
```markdown
# Anthropic Guidelines Validator

## Hooks Validation
- [ ] hooks.json follows documented schema
- [ ] Exit codes used correctly (0/1/2)
- [ ] CLAUDE_PROJECT_DIR / CLAUDE_PLUGIN_ROOT handled correctly
- [ ] Timeout specified
- [ ] `once: true` used for one-time hooks (SessionStart)
- [ ] Agent-scoped hooks in frontmatter, global hooks in hooks.json

## Skills Validation (Updated for 2.1.1)
- [ ] SKILL.md has proper frontmatter
- [ ] Description is semantic-match friendly
- [ ] `context: fork` used if isolated execution needed
- [ ] `agent:` field specifies appropriate model (haiku/sonnet)
- [ ] `user-invocable:` set appropriately (false for internal skills)
- [ ] `hooks:` in frontmatter only for self-contained behaviors
- [ ] No undocumented features used
- [ ] Diagnostic output included for behavioral testing

## Agents Validation (Now Skills with context: fork)
- [ ] Agent implemented as skill with `context: fork`
- [ ] `agent: sonnet` specified (agents need complex reasoning)
- [ ] Skills listed exist
- [ ] Stop hook defined for finalization
- [ ] `user-invocable: true` for user-facing agents

## Plugin Validation
- [ ] plugin.json schema correct
- [ ] All paths resolve
- [ ] No circular dependencies
- [ ] No nested directories under skills/ (flat structure)

## Reference Docs
- Hooks: https://docs.anthropic.com/en/docs/claude-code/hooks
- Skills: https://docs.anthropic.com/en/docs/claude-code/skills
- Plugins: https://docs.anthropic.com/en/docs/claude-code/plugins
```

---

## 5. Implementation Guidelines

### 5.1 Skill File Format

**Plugin Distribution:** Flat structure under `skills/` - no nesting like `atomic/` or `composite/`.

```
skills/skill-name/
├── SKILL.md          # Main skill content (required)
├── references/       # Optional supporting files (same level as SKILL.md)
│   ├── examples.md   # Usage examples
│   └── patterns.md   # Pattern documentation
└── data/             # Optional heuristic data (same level as SKILL.md)
    └── heuristics.json
```

**Standard Skill Frontmatter (2.1.1):**
```yaml
---
name: skill-name
description: What this skill does (semantic-match friendly)
agent: haiku                    # or sonnet for complex tasks
user-invocable: false           # true for user-facing skills
---
```

### 5.2 Agent File Format (Now Skills with `context: fork`)

**2.1.1 Update:** Agents are implemented as skills with `context: fork` frontmatter. No separate `agents/` directory.

```yaml
# skills/bulwark-agent-name/SKILL.md
---
name: bulwark-agent-name
description: What this agent does
context: fork                    # REQUIRED for agents - isolated execution
agent: sonnet                    # Agents need complex reasoning
skills:
  - dependency-skill-1
  - dependency-skill-2
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
hooks:
  - event: Stop
    command: "${CLAUDE_PLUGIN_ROOT}/scripts/agents/finalize.sh"
user-invocable: true
---

# Agent Name

## Identity
[Who this agent is]

## Mission
[What it does and doesn't do]

## Protocol
[Step-by-step procedure]

## Output Format
[How it returns results - MUST write to logs/]

## Diagnostic Output
[Required: Write diagnostic metadata for behavioral testing]
```

### 5.3 Hook Requirements

- Handle `CLAUDE_PROJECT_DIR` environment variable
- Use Exit 2 for blocking errors
- Truncate output to prevent context bloat
- POSIX-compliant for cross-platform

### 5.4 Log Output Pattern

All sub-agent work writes to `logs/`:
```
logs/
├── code-auditor-20260104-143022.md
├── test-auditor-20260104-143156.md
├── debugging-issue-007.md
└── learnings/
    └── pattern-discovered-20260104.md
```

### 5.5 Plugin Packaging & Development Workflow

The Bulwark has **two contexts** for skills:

| Context | Location | Purpose |
|---------|----------|---------|
| **Development Source** | `skills/` | Where we write and maintain (flat structure) |
| **Immediate Use** | `.claude/skills/` | For use during Bulwark development |

**2.1.1 Update:** No separate `agents/` directory. Agents are skills with `context: fork`.

#### Plugin Directory Structure

**Critical:** Only `plugin.json` goes inside `.claude-plugin/`. Skills are flat (no nesting).

```
the-bulwark/                    # Plugin root
├── .claude-plugin/
│   └── plugin.json             # ONLY file here - manifest
├── skills/                     # FLAT - each folder is a skill
│   ├── subagent-prompting/SKILL.md
│   ├── test-classification/SKILL.md
│   ├── test-audit/SKILL.md
│   ├── bulwark-test-auditor/SKILL.md    # Agent (context: fork)
│   ├── bulwark-issue-debugger/SKILL.md  # Agent (context: fork)
│   ├── bulwark-code-auditor/SKILL.md    # Agent (context: fork)
│   ├── bulwark-implementer/SKILL.md     # Agent (context: fork)
│   └── ... (all other skills)
├── commands/                   # At plugin root
├── hooks/
│   └── hooks.json              # Global hooks (uses ${CLAUDE_PLUGIN_ROOT})
├── scripts/                    # Hook execution scripts
│   ├── enforce-quality.sh
│   ├── inject-protocol.sh
│   └── agents/                 # Agent-specific scripts
│       └── finalize.sh
├── logs/                       # Output directory
│   └── diagnostics/            # Behavioral test diagnostics
└── .claude/                    # For immediate dev use (NOT in plugin)
    └── skills/                 # Symlinked/copied from skills/
```

#### Development Workflow

1. **Create skill** in `skills/` (source of truth)
2. **Copy to `.claude/skills/`** for immediate use during Bulwark development
3. **Test** using the skill in current session (hot-reload in 2.1.1)
4. **Final plugin** references `skills/` via `plugin.json`

#### Hook Path Differences

| Context | Path Variable | Example |
|---------|---------------|---------|
| Project hooks (`.claude/settings.json`) | `$CLAUDE_PROJECT_DIR` | `$CLAUDE_PROJECT_DIR/scripts/lint.sh` |
| Plugin hooks (`hooks/hooks.json`) | `${CLAUDE_PLUGIN_ROOT}` | `${CLAUDE_PLUGIN_ROOT}/scripts/lint.sh` |

#### Command Namespacing

- **Project commands:** `/audit`
- **Plugin commands:** `/bulwark:audit`

Commands are namespaced with plugin name when distributed.

### 5.6 Command Script Requirements

Commands that perform **actions** (not just instructions) require backing scripts:

| Command | Actions | Required Script |
|---------|---------|-----------------|
| `/bulwark:audit` | Run test-audit, write YAML | `scripts/audit.sh` |
| `/bulwark:verify` | Run verification scripts | `scripts/verify.sh` |
| `/bulwark:scaffold` | Generate Justfile | `scripts/scaffold.sh` |

#### Command + Script Pattern

```
commands/
├── audit.md              # Instructions for Claude
└── ...

scripts/
├── audit.sh              # Execution script called by hook or command
└── ...
```

The command `.md` file provides instructions; the script performs deterministic actions.

### 5.7 Ralph Wiggum Loop Integration

**Purpose:** Iterative refinement for skill/agent creation using Stop hook loops.

**Reference:** https://github.com/anthropics/claude-code/blob/main/plugins/ralph-wiggum/README.md

#### When to Use Ralph Loops

- Creating new skills (4 iterations recommended)
- Creating new agents (4 iterations recommended)
- Creating verification scripts
- Any artifact requiring iteration and refinement

#### Ralph Loop Pattern for Skill Creation

```bash
/ralph-loop "Create the {skill-name} skill following Bulwark patterns.

Requirements:
- SKILL.md with proper frontmatter (user-invocable: {true/false}, agent: {haiku/sonnet})
- {specific requirements for this skill}
- Validate against anthropic-validator checklist
- Include diagnostic output section

Iteration guidance:
- Iteration 1: Create initial structure
- Iteration 2: Validate and fix frontmatter issues
- Iteration 3: Test invocation, verify outputs
- Iteration 4: Polish and ensure completion

Output <promise>SKILL_COMPLETE</promise> when done." --max-iterations 4
```

#### Embedding Ralph in skill-creator/agent-creator

The `skill-creator` (P5.4) and `agent-creator` (P5.5) skills should guide users through a 4-iteration refinement loop:

1. **Iteration 1:** Initial creation with structure
2. **Iteration 2:** Structural validation via anthropic-validator
3. **Iteration 3:** Behavioral testing (invoke and verify)
4. **Iteration 4:** Polish and completion

### 5.8 Diagnostic Testing

**Purpose:** Enable automated behavioral testing without mocking.

#### Diagnostic Output Format

Every skill and agent MUST write diagnostic metadata to `logs/diagnostics/`:

```yaml
# logs/diagnostics/{skill-name}-{timestamp}.yaml
skill: skill-name
timestamp: 2026-01-08T14:30:22Z
diagnostics:
  model_requested: sonnet
  model_actual: sonnet           # What actually ran
  context_type: forked           # forked or main
  parent_vars_accessible: false  # For context: fork verification
  hooks_fired:
    - Stop
  execution_time_ms: 2340
  completion_status: success     # success, error, timeout
```

#### Diagnostic Output in Skills

Include this section in every skill that supports diagnostics:

```markdown
## Diagnostic Output

When executing, write diagnostic metadata to:
`logs/diagnostics/{skill-name}-{timestamp}.yaml`

Include:
- Model requested vs actual
- Context type (forked/main)
- Hooks that fired
- Execution time
- Completion status
```

#### Automated Test Script

```bash
#!/bin/bash
# tests/run-diagnostic-tests.sh

PASS=0
FAIL=0

echo "=== Bulwark Behavioral Tests ==="

# Test 1: context: fork isolation
echo -n "Test context:fork isolation... "
claude -p "Invoke bulwark-test-auditor skill on ./tests/fixtures/"
DIAG_FILE=$(ls -t logs/diagnostics/bulwark-test-auditor-*.yaml | head -1)
CONTEXT=$(grep "context_type" "$DIAG_FILE" | awk '{print $2}')
if [ "$CONTEXT" == "forked" ]; then
  echo "PASS"
  ((PASS++))
else
  echo "FAIL (expected: forked, got: $CONTEXT)"
  ((FAIL++))
fi

# Test 2: model selection
echo -n "Test agent:sonnet model... "
MODEL=$(grep "model_actual" "$DIAG_FILE" | awk '{print $2}')
if [ "$MODEL" == "sonnet" ]; then
  echo "PASS"
  ((PASS++))
else
  echo "FAIL (expected: sonnet, got: $MODEL)"
  ((FAIL++))
fi

# Test 3: once:true SessionStart hook
echo -n "Test once:true SessionStart... "
HOOK_COUNT=$(grep -c "SessionStart" logs/hooks.log 2>/dev/null || echo "0")
if [ "$HOOK_COUNT" -eq 1 ]; then
  echo "PASS"
  ((PASS++))
else
  echo "FAIL (expected: 1, got: $HOOK_COUNT)"
  ((FAIL++))
fi

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
```

### 5.9 Manual Testing Protocol

**Purpose:** Human validation of behavioral features that require observation.

#### Test Project Setup

Create a test project at `tests/fixtures/` with:
- Sample code files with known issues
- Sample test files (real and mock-heavy)
- Known security vulnerabilities for auditor testing

#### Manual Test Checklist

```markdown
# Bulwark Manual Test Protocol

## Pre-requisites
- [ ] Test project exists at tests/fixtures/
- [ ] Bulwark plugin installed
- [ ] logs/ directory exists

## Test 1: Skill Hot-Reload (2.1.1)
1. Modify a skill's description
2. Verify change is immediately visible (no restart)
3. Result: [ ] PASS / [ ] FAIL

## Test 2: context: fork Isolation
1. In main context, set: MY_SECRET='test123'
2. Invoke bulwark-test-auditor
3. Have agent try to access MY_SECRET
4. Verify agent cannot see the variable
5. Result: [ ] PASS / [ ] FAIL

## Test 3: once: true SessionStart
1. Start new session
2. Check logs/hooks.log for SessionStart entry
3. Force reload (if possible)
4. Verify SessionStart did NOT fire again
5. Result: [ ] PASS / [ ] FAIL

## Test 4: Agent Stop Hook
1. Invoke bulwark-test-auditor
2. Let it complete
3. Verify logs/diagnostics/ has entry
4. Result: [ ] PASS / [ ] FAIL

## Test 5: user-invocable: false
1. Type / to open command menu
2. Verify internal skills (subagent-prompting, etc.) do NOT appear
3. Verify user-facing skills (test-audit) DO appear
4. Result: [ ] PASS / [ ] FAIL

## Test 6: Model Selection
1. Invoke test-classification (agent: haiku)
2. Observe model indicator or check diagnostics
3. Verify Haiku was used
4. Result: [ ] PASS / [ ] FAIL

## Summary
- Tests passed: ___
- Tests failed: ___
- Notes: ___
```

---

## 6. Success Criteria

### Phase 0 Complete When:
- [ ] Sub-agents invoked with 4-part template
- [ ] Output goes to logs with structured format
- [ ] Pipeline templates defined and usable
- [ ] Issue debugging has validation loop
- [ ] Anthropic validator catches guideline violations (2.1.1 fields)
- [ ] All skills have correct frontmatter (`user-invocable`, `agent`)

### Phase 1 Complete When:
- [ ] Test auditor implemented as skill with `context: fork`
- [ ] Issue debugger implemented as skill with `context: fork`
- [ ] Test audit produces YAML inventory
- [ ] Tests classified as real vs mock-based
- [ ] Diagnostic output written for behavioral testing

### Phase 2 Complete When:
- [ ] Verification scripts created for components
- [ ] Scripts report pass/fail

### Phase 3 Complete When:
- [ ] PostToolUse blocks on failures (global hook)
- [ ] SessionStart fires exactly once (`once: true`)
- [ ] Sessions inject governance protocol
- [ ] `just` commands work with log output

### Phase 4 Complete When:
- [ ] Code auditor reviews code, returns findings (never fixes)
- [ ] Code auditor runs in forked context
- [ ] Implementer follows Bulwark standards
- [ ] Implementer has agent-scoped hooks
- [ ] Diagnostic output written for behavioral testing

### Phase 5 Complete When:
- [ ] Plugin fully installable
- [ ] skill-creator guides through Ralph loop (4 iterations)
- [ ] agent-creator creates skills with `context: fork`
- [ ] Documentation complete

### Testing Complete When:
- [ ] Automated diagnostic tests pass (`tests/run-diagnostic-tests.sh`)
- [ ] Manual test protocol executed and documented
- [ ] All 2.1.1 features validated

### Overall Success:
- Development workflow enforces quality deterministically
- Tests verify real behavior (no mocks)
- Fixes go through validation loops
- Skills evolve through continuous feedback
- All 2.1.1 features properly leveraged
