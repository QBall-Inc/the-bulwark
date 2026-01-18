# The Bulwark - Architecture

Reference document describing what The Bulwark delivers. For development guidelines, see `CLAUDE.md` and `Rules.md`.

---

## Problem Statement

AI-assisted code generation suffers from fundamental quality issues:

1. **Entropy Drift**: Code quality degrades as context fills and complexity increases
2. **Semantic vs Engineering Compliance**: Agents satisfy requests literally but fail engineering requirements
3. **Self-Review Bias**: Agents cannot objectively review code they generated in the same context
4. **Mock-Heavy Testing**: Agents write tests that verify mocks, not actual system behavior
5. **Fix-Declare-Done Pattern**: Fixes declared complete without verification, leading to repeated failures

These are not bugs to fix—they are fundamental characteristics of unconstrained agentic systems.

---

## Mission Statement

The Bulwark transforms stochastic AI output into deterministic, engineering-grade artifacts by:

1. **Externalizing Quality Assurance** - QA happens outside the generating context
2. **Enforcing Deterministic Gates** - Scripts and validators that don't hallucinate
3. **Encoding Testing Discipline** - Heuristics that ensure real behavior verification
4. **Enabling Pipeline Orchestration** - Declarative workflows with validation loops

---

## Core Premises

### 1. Externalized Quality Assurance

An AI agent cannot police itself within the same context it generates code. Quality must come from:
- **Deterministic Code**: Shell scripts and linters that don't hallucinate
- **Isolated Contexts**: Sub-agents that review without authorship bias
- **Heuristic Frameworks**: Skills encoding testing discipline and patterns

### 2. Atomic Principles

Every implementation must be:
- **Single Responsibility**: One purpose per function, skill, or agent
- **Self-Contained**: Minimal dependencies, explicit inputs/outputs
- **Independently Verifiable**: Can be tested in isolation

### 3. Testability & Real-World Testing

- Tests verify **observable output**, not mock calls
- Integration tests exercise **real systems** (processes, files, network)
- No mocking the system under test
- Verification scripts prove components work

### 4. Pipeline Orchestration

Complex workflows use declarative F# pipe syntax:
```fsharp
Investigation |> Implementation |> TestAudit |> Validation
|> (if findings > 0 then FixLoop else Done)
```

---

## Defense-in-Depth Model

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
│  Skills compose via dependencies and orchestration          │
├─────────────────────────────────────────────────────────────┤
│                    CORE: EXECUTION                          │
│  `just` command runner for deterministic invocation         │
│  Output to logs, summary to agent context                   │
└─────────────────────────────────────────────────────────────┘
```

---

## Sub-Agents (Skills with context: fork)

**Claude Code 2.1.x**: Sub-agents are implemented as skills with `context: fork` frontmatter, enabling isolated execution in a separate context window.

| Agent Skill | Purpose | Invocation Pattern |
|-------------|---------|-------------------|
| `bulwark-code-auditor` | Reviews code for quality, security, SOLID principles | `context: fork`, returns structured findings to logs |
| `bulwark-test-auditor` | Reviews tests for real behavior verification | `context: fork`, classifies tests, flags mock-heavy patterns |
| `bulwark-issue-debugger` | Holistic debugging with validation loops | `context: fork`, root cause analysis with verification |
| `bulwark-implementer` | Executes task implementation plans | `context: fork`, produces code + tests following standards |

**Key Constraint**: Sub-agents cannot spawn other sub-agents. Pipeline orchestration happens from the main thread.

---

## Skills

**Note**: All skills use a **flat directory structure** per Claude Code 2.1.x plugin requirements. The "Foundation" and "Composite" categorizations below are conceptual, not directory-based.

### Foundation Skills (Internal)

| Skill | Purpose | Frontmatter |
|-------|---------|-------------|
| `session-handoff` | Consistent session handoff format | `user-invocable: true` |
| `subagent-prompting` | 4-part template (GOAL/CONSTRAINTS/CONTEXT/OUTPUT) + pipeline syntax | `user-invocable: false` |
| `subagent-output-templating` | Structured log output, task completion reports | `user-invocable: false` |
| `pipeline-templates` | Pre-defined F# pipe workflows for common scenarios | `user-invocable: false` |
| `test-classification` | Prompt template for test classification (Haiku stage) | `user-invocable: false` |
| `mock-detection` | Prompt template for T1-T4 violation detection (Haiku stage) | `user-invocable: false` |
| `assertion-patterns` | Real output verification vs mock calls | `user-invocable: false` |
| `security-heuristics` | OWASP checks, injection patterns | `agent: sonnet`, `user-invocable: false` |
| `type-safety` | Type safety review patterns | `agent: sonnet`, `user-invocable: false` |
| `bug-magnet-data` | Edge case data for test injection | `agent: haiku`, `user-invocable: false` |
| `component-patterns` | Per-component-type verification approaches | `user-invocable: false` |
| `continuous-feedback` | Skill enhancement from learnings | `user-invocable: false` |
| `anthropic-validator` | Validate against official Anthropic guidelines | `user-invocable: true` |

### Composite Skills (User-Facing)

| Skill | Uses | Purpose | Frontmatter |
|-------|------|---------|-------------|
| `test-audit` | test-classification, mock-detection | Main Context Orchestration: audit tests, spawn Haiku/Sonnet sub-agents | `user-invocable: true` (no `agent:` field) |
| `code-review` | security-heuristics, type-safety | Comprehensive code review | `agent: sonnet`, `user-invocable: true` |
| `verification-script` | component-patterns, assertion-patterns | Create runnable verification scripts | `agent: sonnet`, `user-invocable: true` |
| `issue-debugging` | Multiple foundation skills | Holistic fix with validation loop | `user-invocable: false` |

**Note on Main Context Orchestration**: The `test-audit` skill uses the same pattern as `anthropic-validator` - the orchestrator (Opus) follows skill instructions and spawns general-purpose sub-agents with explicit model selection. This enables bias avoidance (Haiku/Sonnet audit, Opus implements fixes).

### Agent Skills (context: fork)

**Claude Code 2.1.x**: Agents are implemented as skills with `context: fork` for isolated execution.

| Skill | Purpose | Frontmatter |
|-------|---------|-------------|
| `bulwark-test-auditor` | Reviews tests for real behavior verification | `context: fork`, `agent: sonnet` |
| `bulwark-issue-debugger` | Holistic debugging with validation loops | `context: fork`, `agent: sonnet` |
| `bulwark-code-auditor` | Reviews code for quality, security, SOLID | `context: fork`, `agent: sonnet` |
| `bulwark-implementer` | Executes plans following Bulwark standards | `context: fork`, `agent: sonnet` |

---

## Pipeline Patterns

**Code Review Pipeline:**
```fsharp
CodeAuditor (security)
|> CodeAuditor (architecture)
|> TestAuditor (coverage)
|> (if findings > 0 then IssueDebugger else Done)
```

**Fix Validation Pipeline:**
```fsharp
IssueDebugger (root cause)
|> Implementer (apply fix)
|> CodeAuditor (verify quality)
|> TestAuditor (verify tests)
|> (if issues > 0 then IssueDebugger else Done)
```

**Test Audit Pipeline:**
```fsharp
// Main Context Orchestration pattern
// Orchestrator spawns general-purpose sub-agents with explicit model selection
test-classification (Haiku, prompt template)
|> mock-detection (Haiku, prompt template + classification context)
|> test-audit synthesis (Sonnet, analysis + REWRITE_REQUIRED directive)
|> (if REWRITE_REQUIRED then Orchestrator (Opus) rewrites else Done)
```

---

## Directory Structure

**Claude Code 2.1.x Plugin Structure**: All component directories (commands, skills, hooks) are at plugin root level, NOT inside `.claude-plugin/`. Skills use a flat structure (no nesting).

```
the-bulwark/                     # Plugin root
├── .claude/
│   └── skills/                  # ACTIVE skills (for hot-reload during development)
│       └── session-handoff/     # Copied from skills/ for testing
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest (ONLY file here)
├── CLAUDE.md                    # Development instructions
├── Rules.md                     # Immutable rules
├── starter-prompt.md            # Session sequences
├── commands/                    # Slash commands (at plugin root)
│   ├── scaffold.md              # /bulwark:scaffold
│   ├── audit.md                 # /bulwark:audit
│   └── verify.md                # /bulwark:verify
├── skills/                      # Skills (FLAT structure, at plugin root)
│   ├── session-handoff/         # Each skill is direct child
│   ├── subagent-prompting/
│   ├── bulwark-test-auditor/    # Agents are skills with context: fork
│   ├── bulwark-code-auditor/
│   └── ...                      # All other skills
├── hooks/
│   └── hooks.json               # Global hooks (uses ${CLAUDE_PLUGIN_ROOT})
├── scripts/                     # Hook execution scripts
│   ├── enforce-quality.sh
│   ├── inject-protocol.sh
│   └── agents/                  # Agent-specific scripts
│       └── finalize.sh
├── lib/
│   └── templates/               # Justfile templates
├── plans/
│   ├── the-bulwark-plan.md      # Master plan
│   ├── tasks.yaml               # Task status tracking
│   └── task-briefs/             # Implementation plans per task
├── sessions/                    # Session handoffs
├── logs/                        # Sub-agent output logs
│   └── diagnostics/             # Behavioral test diagnostics
└── docs/                        # Documentation
    └── architecture.md          # This file
```

**Development Workflow**:
1. Create skills in `skills/` (source of truth, plugin-ready)
2. Copy to `.claude/skills/` for hot-reload testing during development
3. Plugin distribution uses `skills/` directly via `plugin.json`

**Note**: There is no separate `agents/` directory. Per Claude Code 2.1.x, agents are implemented as skills with `context: fork` frontmatter.

---

## Technology Stack

- **Hooks**: Bash scripts with Exit 2 blocking
- **Skills**: Markdown with YAML frontmatter
- **Agents**: Markdown with structured prompts
- **Command Runner**: `just` for deterministic invocation
- **Output**: Log files for sub-agent results, summaries to context

---

## Deliverables

The Bulwark provides:

1. **Enforcement Hooks** - PostToolUse blocking on quality failures
2. **Specialist Agents** - Code auditor, test auditor, issue debugger, implementer
3. **Workflow Skills** - Prompting templates, output formatting, pipeline patterns
4. **Audit Skills** - Test classification, mock detection, verification scripts
5. **Evolution Tools** - Skill creator, agent creator for continuous improvement
6. **Continuous Feedback** - Learning capture and skill enhancement mechanism
