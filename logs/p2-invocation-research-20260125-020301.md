# P2 Skills Invocation Research

**Timestamp**: 2026-01-25T02:03:01Z
**Researcher**: Opus 4.5
**Task**: Research invocation mechanisms for P2.1-P2.3 skills (assertion-patterns, component-patterns, verification-script)

---

## Executive Summary

The P2 skills follow the **composite skill pattern** where:
- **P2.1** (`assertion-patterns`) and **P2.2** (`component-patterns`) are foundation skills loaded by the composite skill
- **P2.3** (`verification-script`) is a user-invocable composite skill that orchestrates the foundation skills
- **Recommended invocation**: Direct user invocation via `/verification-script` (already defined in architecture)
- **No hooks or Justfile recipes needed** - these are skill-based knowledge templates, not enforcement mechanisms

---

## Research Questions Answered

### 1. Should P2 skills be loaded via PostToolUse hooks?

**Answer: No**

**Rationale**:
- Hooks are for **enforcement** (P3.3 `enforce-quality.sh`, P3.4 hooks.json)
- P2 skills are **knowledge templates** for creating verification scripts
- Hook pattern is used for:
  - Quality enforcement (P3.4: PostToolUse → enforce-quality.sh)
  - Pipeline suggestion (P0.3: PostToolUse → suggest-pipeline.sh)
  - Pipeline tracking (P0.3: SubagentStart/Stop → track-pipeline-*.sh)
- Verification script creation is **on-demand**, not automatic

**Evidence**:
```yaml
# tasks.yaml P3.4
acceptance_criteria:
  - "PostToolUse (Edit|Write): Quality enforcement, calls enforce-quality.sh"
  - "PreToolUse (Task): Pipeline validation (from P0.3)"
```

### 2. Should P2 skills be included in sub-agent definitions?

**Answer: Yes, for P2.1 and P2.2 as dependencies of P2.3**

**Rationale**:
- Foundation skills (P2.1, P2.2) are loaded via `skills:` frontmatter in P2.3
- Pattern established in existing composite skills:
  - `test-audit` loads `test-classification` and `mock-detection`
  - `bulwark-issue-analyzer` loads `issue-debugging`, `subagent-output-templating`, `subagent-prompting`
  - `verification-script` loads `component-patterns` and `assertion-patterns`

**Evidence from architecture.md**:
```markdown
| Skill | Uses | Purpose | Frontmatter |
|-------|------|---------|-------------|
| `verification-script` | component-patterns, assertion-patterns | Create runnable verification scripts | `agent: sonnet`, `user-invocable: true` |
```

**Evidence from agent definitions**:
```yaml
# agents/bulwark-issue-analyzer.md
skills:
  - issue-debugging
  - subagent-output-templating
  - subagent-prompting
```

### 3. Should P2 skills be invoked via Justfile recipes?

**Answer: No (but generated verification scripts may USE Justfile)**

**Rationale**:
- Justfile recipes are for **project-level execution** (P3.1: lint, test, typecheck, fix)
- P2.3 `verification-script` **creates** runnable bash scripts
- Those generated scripts may call `just test` or other recipes
- But P2 skills themselves are not Justfile targets

**Evidence**:
```yaml
# tasks.yaml P3.1
deliverables:
  - "lib/templates/justfile-node.just"
acceptance_criteria:
  - "Each has lint, test, typecheck, fix recipes"
```

**From P2.3 architecture**:
```markdown
| `verification-script` | component-patterns, assertion-patterns | Create runnable verification scripts | `agent: sonnet`, `user-invocable: true` |
```

### 4. Is there a gap in the architecture for verification script invocation?

**Answer: No - P5.2 defines the invocation path**

**Rationale**:
- P5.2 creates `/bulwark:verify` command
- This command invokes P2.3 `verification-script` skill
- Same pattern as P5.1 `/bulwark:audit` → `test-audit` skill

**Evidence**:
```yaml
# tasks.yaml P5.2
- id: P5.2
  name: "Create verify command"
  dependencies: [P2.3]
  implementation_plan: "plans/task-briefs/P5.2-verify-command.md"
  deliverables:
    - "commands/verify.md"
  acceptance_criteria:
    - "Invokes verification-script skill"
    - "Runs generated scripts"
    - "Reports pass/fail"
```

### 5. What does P5.2 (/bulwark:verify command) tell us about intended invocation?

**Answer: User-facing command wrapper around composite skill**

**Rationale**:
- P5.2 is a **command** that wraps P2.3 **skill**
- Same pattern as:
  - P5.1 `/bulwark:audit` wraps `test-audit` skill
  - `/fix-bug` wraps Fix Validation pipeline
- Commands provide user-friendly entry points to skills

**Pattern comparison**:
| Command | Wraps Skill | Pattern |
|---------|-------------|---------|
| `/bulwark:audit` (P5.1) | `test-audit` (P0.8) | Command → Composite Skill |
| `/bulwark:verify` (P5.2) | `verification-script` (P2.3) | Command → Composite Skill |
| `/fix-bug` (P1.3) | Fix Validation pipeline | Command → Pipeline |

---

## Invocation Mechanisms Analyzed

### Option A: PostToolUse Hook
**Pros:**
- Automatic enforcement after code changes
- No user action required

**Cons:**
- Verification scripts are on-demand artifacts, not quality gates
- Creates friction - not every code change needs verification script generation
- Hooks are for enforcement (lint/typecheck), not artifact creation

**Verdict:** ❌ Not appropriate

---

### Option B: Justfile Recipes
**Pros:**
- Consistent project execution interface
- Easy to integrate into CI/CD

**Cons:**
- Justfile is for running existing tools (lint, test), not generating artifacts
- P2.3 creates scripts, doesn't run them directly
- Wrong abstraction level

**Verdict:** ❌ Not appropriate (but generated scripts may call Justfile recipes)

---

### Option C: Sub-Agent Inclusion
**Pros:**
- Foundation skills (P2.1, P2.2) loaded via frontmatter in P2.3
- Established pattern in codebase
- Clean separation of concerns

**Cons:**
- Only applies to foundation skills, not P2.3 itself

**Verdict:** ✅ **Correct for P2.1 and P2.2**

**Implementation:**
```yaml
# skills/verification-script/SKILL.md
name: verification-script
description: Create runnable verification scripts
user-invocable: true
agent: sonnet
skills:
  - component-patterns
  - assertion-patterns
```

---

### Option D: Direct User Invocation (Composite Skill)
**Pros:**
- User controls when to generate verification scripts
- P2.3 has `user-invocable: true`
- Can be wrapped in command (P5.2) for better UX
- Same pattern as `test-audit` and `anthropic-validator`

**Cons:**
- Requires user to know about the skill (mitigated by P5.2 command)

**Verdict:** ✅ **Correct for P2.3**

**Implementation:**
```bash
# Direct invocation
/verification-script src/api/handler.ts

# Or via P5.2 command wrapper
/bulwark:verify src/api/handler.ts
```

---

### Option E: Pipeline Integration
**Pros:**
- Could be part of Fix Validation or New Feature pipelines
- Ensures verification scripts exist for new code

**Cons:**
- Not every code change needs verification scripts
- Pipeline stages are for review/validation, not artifact generation
- Creates unnecessary pipeline complexity

**Verdict:** ❌ Not appropriate (but skills can be invoked FROM pipelines if needed)

---

## Recommended Invocation Architecture

### P2.1 `assertion-patterns`
- **Type**: Foundation skill (knowledge template)
- **user-invocable**: `false`
- **Invocation**: Loaded via frontmatter in P2.3
- **Usage**: Provides patterns for real output verification vs mock calls

### P2.2 `component-patterns`
- **Type**: Foundation skill (knowledge template)
- **user-invocable**: `false`
- **Invocation**: Loaded via frontmatter in P2.3
- **Usage**: Provides per-component-type verification approaches

### P2.3 `verification-script`
- **Type**: Composite skill (orchestrator)
- **user-invocable**: `true`
- **Invocation**:
  1. Direct: `/verification-script path/to/code`
  2. Via command: `/bulwark:verify path/to/code` (P5.2)
- **Behavior**:
  - Loads P2.1 and P2.2 via frontmatter
  - Analyzes target code
  - Generates runnable bash script to `tmp/verify-{component}-{timestamp}.sh`
  - Optionally runs script and reports pass/fail
- **Model**: `agent: sonnet` (pattern analysis + script generation)

---

## Architecture Patterns Observed

### Main Context Orchestration
**Used by**: `test-audit`, `anthropic-validator`

**Pattern**:
```
User invokes skill → Orchestrator (Opus) loads skill → Follows instructions → Spawns sub-agents → Synthesizes results
```

**P2.3 alignment**:
- P2.3 likely follows this pattern
- Orchestrator loads P2.1 and P2.2 knowledge
- Generates verification script based on component type
- May spawn Sonnet sub-agent for complex analysis

### Composite Skill with Dependencies
**Used by**: All composite skills

**Pattern**:
```yaml
name: composite-skill
user-invocable: true
skills:
  - foundation-skill-1
  - foundation-skill-2
```

**P2.3 implementation**:
```yaml
name: verification-script
user-invocable: true
agent: sonnet
skills:
  - component-patterns
  - assertion-patterns
```

### Command Wrapper
**Used by**: `/fix-bug`, `/test-audit`, `/anthropic-validator`

**Pattern**:
```markdown
# commands/command-name.md
Invokes: skill-name or pipeline
Arguments: path, options
```

**P2.3 wrapper (P5.2)**:
```markdown
# commands/verify.md
Invokes: verification-script
Arguments: $1 (path to component)
```

---

## Comparison with Similar Skills

### test-audit (P0.8)
**Similarities to P2.3**:
- Composite skill (`user-invocable: true`)
- Loads foundation skills (`test-classification`, `mock-detection`)
- Has command wrapper (`/bulwark:audit` in P5.1)
- Main Context Orchestration pattern

**Differences**:
- `test-audit` analyzes existing artifacts (tests)
- `verification-script` generates new artifacts (bash scripts)

### anthropic-validator (P0.5)
**Similarities to P2.3**:
- User-invocable composite skill
- Main Context Orchestration
- Analyzes code and produces actionable output

**Differences**:
- Validates against standards (read-only)
- `verification-script` creates executable scripts (write)

### fix-bug (P1.3 deliverable)
**Similarities to P2.3**:
- Has slash command invocation
- Triggers multi-stage workflow

**Differences**:
- `fix-bug` triggers pipeline (multiple agents)
- `verification-script` is single skill (may spawn 1 sub-agent)

---

## Implementation Guidance for P2

### Task Brief Structure
**Recommendation**: Create **consolidated task brief** for P2.1-P2.3

**Rationale**:
- P2.1 and P2.2 are small knowledge templates (pattern lists)
- P2.3 orchestrates them tightly
- Easier to ensure consistency across all three
- Pattern used successfully in P0.6-8 (test-audit skills)

**Brief structure**:
```markdown
# P2.1-2.3 Verification Script Skills

## Overview
Three skills working together to generate verification scripts

## P2.1: assertion-patterns
- Forbidden patterns (mock calls)
- Required patterns (real output verification)
- Transformation examples

## P2.2: component-patterns
- CLI command verification
- HTTP server verification
- File parser verification
- Process spawner verification

## P2.3: verification-script
- Loads P2.1 and P2.2
- Analyzes component type
- Generates bash script
- Optionally executes and reports
```

### Skill Dependencies
```yaml
# P2.1 assertion-patterns
user-invocable: false
# (no dependencies)

# P2.2 component-patterns
user-invocable: false
# (no dependencies)

# P2.3 verification-script
user-invocable: true
agent: sonnet
skills:
  - component-patterns
  - assertion-patterns
  - subagent-output-templating  # For diagnostic output
```

### Command Wrapper (P5.2)
```markdown
# commands/verify.md
---
name: verify
description: Create and run verification scripts for components
---

# Verify Command

## Usage
/bulwark:verify <path> [--run]

## Behavior
1. Invokes verification-script skill
2. Generates script to tmp/
3. If --run flag: executes script and reports results
4. Otherwise: outputs script path for manual execution
```

---

## Anti-Patterns to Avoid

### ❌ Don't: Create hook for automatic verification script generation
**Why**: Verification scripts are on-demand, not enforcement

### ❌ Don't: Add Justfile recipe for verification script generation
**Why**: Justfile is for execution, not generation

### ❌ Don't: Make P2.1/P2.2 user-invocable
**Why**: They're knowledge templates, not standalone tools

### ❌ Don't: Separate P2.1-P2.3 into 3 task briefs
**Why**: They're tightly coupled; consolidated brief ensures consistency

### ❌ Don't: Add verification-script to pipeline stages
**Why**: Pipelines are for review/validation, not artifact generation (unless explicitly needed)

---

## Open Questions for Task Brief Creation

### Q1: Should verification-script execute the generated script automatically?
**Options**:
- A: Always execute (report pass/fail immediately)
- B: Never execute (just generate script, user runs manually)
- C: Optional flag `--run` (default: don't execute)

**Recommendation**: Option C (matches `/fix-bug` pattern of user control)

### Q2: Where should generated scripts be written?
**Options**:
- A: `tmp/verify-{component}-{timestamp}.sh` (ephemeral)
- B: `scripts/verify-{component}.sh` (persistent, versioned)
- C: User-specified path via argument

**Recommendation**: Option A for initial generation, with option to save to project if useful

### Q3: Should verification-script spawn a sub-agent?
**Options**:
- A: Orchestrator (Opus) does all work directly
- B: Spawn Sonnet sub-agent for pattern analysis + script generation

**Recommendation**: Option A (simpler, script generation is straightforward template work)

### Q4: What file types should verification-script support?
**Scope**:
- CLI commands (scripts with CLI args)
- HTTP servers (Express, FastAPI, etc.)
- File parsers (read file → transform → output)
- Process spawners (child_process, subprocess)
- Database queries?
- Background workers?

**Recommendation**: Start with P2.2's 4 component types (CLI, HTTP, parser, spawner), defer others to P5+ if needed

---

## Conclusion

**Recommended Invocation Mechanism**: **Composite Skill with Command Wrapper**

**Architecture**:
1. **P2.1 and P2.2**: Foundation skills (`user-invocable: false`), loaded via P2.3 frontmatter
2. **P2.3**: Composite skill (`user-invocable: true`), direct invocation or via P5.2 command
3. **P5.2**: Command wrapper (`/bulwark:verify`) for better UX
4. **No hooks or Justfile recipes** - on-demand tool, not enforcement

**Next Steps**:
1. Create consolidated task brief for P2.1-P2.3
2. Define component type detection logic
3. Create script templates for each component type
4. Implement P2.3 orchestration logic
5. Create P5.2 command wrapper

**Confidence**: High - pattern is well-established in existing codebase and aligns with architecture.md specification.
