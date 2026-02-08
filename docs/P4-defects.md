# P4 Defects and Enhancements

Defects and enhancements identified during P4 manual testing.

**Identifiers:**
- `DEF-P4-xxx` - Defects (bugs, incorrect behavior)
- `ENH-P4-xxx` - Enhancements (improvements, new features)
- `CLEANUP-P4-xxx` - Cleanup tasks (test artifact removal)

---

## Open Defects

### DEF-P4-001: code-review skill YAML parsing error on load

**Identified:** Session 33 (2026-01-31)
**Phase:** P4.1 Manual Testing
**Severity:** High
**Status:** Closed (Session 33)
**Symptom:** Skill fails to load with bash syntax error: `syntax error near unexpected token ')'`
**Root Cause:** Backticks in SKILL.md containing special characters (`!` operator, `db.query()`) were interpreted as bash command substitution during skill loading.
**Fixed:** Removed problematic backticks from lines 152 and 306 in code-review/SKILL.md.

---

### DEF-P4-002: code-review skill description used invalid YAML block scalar

**Identified:** Session 33 (2026-01-31)
**Phase:** P4.1 Manual Testing
**Severity:** Medium
**Status:** Closed (Session 33)
**Symptom:** Skill description format inconsistent with Anthropic guidelines.
**Root Cause:** Description used `>` (YAML folded block scalar) instead of single-line string. Also missing "Use when" trigger language.
**Fixed:** Updated to single-line description with "Use when" triggers:
```yaml
description: Comprehensive code review with Security, Type Safety, Linting, and Coding Standards sections. Use when reviewing code, checking for security issues, finding type safety problems, auditing code quality, or when user asks to review changes. Two-phase workflow runs static tools first, then LLM judgment.
```

---

### DEF-P4-003: code-review skill diagnostic log not written during execution

**Identified:** Session 33 (2026-01-31)
**Phase:** P4.1 Manual Testing
**Severity:** Critical
**Status:** Closed (Session 33)

**Symptom:** Skill executed successfully and delivered findings to console, but did not write the required diagnostic log to `logs/diagnostics/code-review-{timestamp}.yaml`.

**Root Cause Analysis:**
1. **Premature completion** - Claude treated delivering findings as "task complete" when the skill defines additional post-review steps
2. **User-focus bias** - Diagnostic log is for system observability, not direct user value. Claude prioritized visible output over operational requirement
3. **Document structure** - Diagnostic section appears after main workflow sections. Claude processed "Two-Phase Workflow" as complete procedure when it wasn't

**Proposed Fix:** Update skill instructions to make diagnostic logging more prominent and mandatory:

1. **Add to workflow section explicitly:**
```
Phase 1: Static Analysis
Phase 2: LLM Review
Phase 3: Write Diagnostic Log  ← Make it a numbered phase
```

2. **Use MUST/REQUIRED language:**
```markdown
## Diagnostic Output (REQUIRED)
You MUST write diagnostic output after every review...
```

3. **Add a completion checklist:**
```markdown
## Before Returning to User
- [ ] Findings delivered
- [ ] Diagnostic log written to logs/diagnostics/
```

4. **Place critical steps earlier** or repeat them in the workflow section rather than only at the end.

**Impact:** Without diagnostic logs, pipeline orchestration cannot collect sub-agent outputs, breaking the observability chain required for multi-agent workflows.

**Fixed:** Updated skill with:
1. Renamed to "Three-Phase Workflow" with Phase 3 explicitly for diagnostic logging
2. Added "Why Phase 3 is Required" explanation
3. Changed "Diagnostic Output" to "Diagnostic Output (REQUIRED)" with MUST language
4. Added "Completion Checklist" section at end requiring all phases complete before returning

---

### DEF-P4-004: Unclear mandatory vs optional dependencies in code-review skill

**Identified:** Session 33 (2026-02-01)
**Phase:** P4.1 Manual Testing
**Severity:** Medium
**Status:** Closed (Session 33)

**Symptom:** Claude executing code-review skill did not load `frameworks/{detected}.md` or `examples/` files. Unclear whether these are required dependencies or optional enhancements.

**Root Cause:** The skill references these files without clarifying their requirement level:
- Line 69: "Load framework patterns from frameworks/{detected}.md"
- Lines 123, 126-127, 162-163, 197-198, 241-242: Section references to examples/
- Line 257: "Auto-detect framework... Loads framework-specific patterns"

**Files that exist but weren't loaded:**
```
frameworks/react.md, express.md, angular.md, vue.md, django.md, flask.md, generic.md
examples/anti-patterns/{security,type-safety,linting,standards}.ts
examples/recommended/{security,type-safety,linting,standards}.ts
```

**Unclear behaviors:**
1. Is loading framework patterns required or an enhancement?
2. What if no framework is detected - skip or use generic.md?
3. Are examples for Claude's reference or must they be loaded for calibration?

**Proposed Fix:** Add explicit labels and clarify behaviors:

1. **Add dependency section to frontmatter comments:**
```markdown
# Dependencies:
# - references/*.md - REQUIRED (pattern definitions)
# - frameworks/*.md - OPTIONAL (load if framework detected, else skip)
# - examples/*.ts - OPTIONAL (reference for calibration, not required to load)
```

2. **Update workflow steps with labels:**
```markdown
├── Load references/{section}-patterns.md (REQUIRED)
├── Load frameworks/{detected}.md (OPTIONAL - skip if no framework detected)
├── Review examples/ for calibration (OPTIONAL - for ambiguous cases)
```

3. **Add explicit fallback behavior:**
```markdown
Framework Detection:
- If framework detected: Load frameworks/{name}.md
- If no framework detected: Skip framework patterns (do not use generic.md as default)
```

**Impact:** Without clarity, Claude may skip loading useful calibration data, or waste tokens loading unnecessary files.

**Fixed:** Updated skill with explicit requirement levels:
- `references/*.md` → REQUIRED (always load)
- `frameworks/*.md` → CONDITIONALLY REQUIRED (if framework detected, MUST load)
- `examples/*.ts` → OPTIONAL (kept for model portability to non-Claude models)

Added Dependencies section, updated Three-Phase Workflow, and Framework Detection sections.

---

### DEF-P4-005: Claude ignores skill instructions and performs ad-hoc analysis

**Identified:** Session 37 (2026-02-02)
**Phase:** P4.2 Manual Testing
**Severity:** Critical
**Status:** Fixed (Session 37) - Pending verification

**Symptom:** When invoking test-audit skill with explicit instruction to "Load the appropriate skill or sub-agents for this", Claude:
- Loaded the test-audit skill
- Did NOT spawn any sub-agents (Haiku for classification, Sonnet for detection/synthesis)
- Did NOT write any outputs to logs/
- Did NOT follow the orchestration instructions
- Performed direct ad-hoc analysis instead

**Root Cause Analysis:**

1. **Rules.md not loaded in session** - The governance-protocol injected at SessionStart does NOT instruct Claude to read Rules.md. It contains a condensed summary of T1-T4 rules but NOT SC1-SC3 (Skill Compliance Rules).

2. **CLAUDE.md mentions but doesn't force read** - CLAUDE.md references Rules.md in "Quick References" section with note "READ BEFORE ANY WORK", but this is a reference, not an executable instruction. Without the starter-prompt explicitly commanding "Read Rules.md", the file is never read.

3. **Completion checklists at END of skills** - Skills have completion checklists at the bottom. Claude shortcuts before reaching them, treating user-visible output as "task complete".

4. **Model behavioral pattern** - As the model itself admitted: "I prioritized perceived efficiency over following the defined process... The issue isn't comprehension - it's compliance."

**Evidence:**

| Session Type | Has Starter Prompt | Rules.md Read | Skill Followed |
|--------------|-------------------|---------------|----------------|
| Orchestrator (this session) | Yes | Yes | N/A |
| Test session | No | No | No |

**Proposed Fix:**

1. **Update governance-protocol/SKILL.md** to include explicit instruction that following every single rule in Rules.md throughout the session is a contract which is binding, mandatory and non-negotiable

2. **Update CLAUDE.md** with exactly same instructions - make it clear that Rules.md MUST be read and followed, not just referenced

3. **Move completion checklists to FRONT of skills** as "Pre-Flight Gate" sections:
   - test-audit: Move checklist from end to beginning
   - bug-magnet-data: Move checklist from end to beginning
   - Other P4 assets: Apply same pattern

**Impact:** Without these fixes, any session without the starter-prompt will have Claude ignoring skill instructions entirely, defeating the purpose of the Bulwark quality enforcement system.

**Files to Update:**
- `skills/governance-protocol/SKILL.md`
- `CLAUDE.md`
- `.claude/skills/test-audit/SKILL.md`
- `.claude/skills/bug-magnet-data/SKILL.md`
- (sync to skills/ source directory after .claude/ updates)

**Fixed (Session 37):**
1. Updated `CLAUDE.md` with "MANDATORY: Read Rules.md" section including SC1-SC3 summary
2. Updated `skills/governance-protocol/SKILL.md` with "MANDATORY: Rules.md is Binding" section
3. Added "Pre-Flight Gate (BLOCKING)" section to `skills/test-audit/SKILL.md` (moved checklist to front)
4. Added "Pre-Flight Gate (BLOCKING)" section to `skills/bug-magnet-data/SKILL.md` (moved checklist to front)
5. Synced all updates to `.claude/skills/` directory

**Verification:** Requires re-testing in fresh session to confirm compliance.

---

### DEF-P4-006: Sub-agents write duplicate .md log files alongside specified YAML outputs

**Identified:** Session 38 (2026-02-06)
**Phase:** P4.2 Manual Testing
**Severity:** Medium
**Status:** Closed (Session 38)

**Symptom:** During P4.2-3 testing, both `bulwark-issue-analyzer` and `bulwark-fix-validator` sub-agents wrote extra `.md` files to `logs/` in addition to their specified YAML outputs:
- `logs/debugging-whitespace-username.md` (issue analyzer - not specified)
- `logs/fix-validation-whitespace-username.md` (fix validator - not specified)

The correct YAML outputs were also written:
- `logs/debug-reports/whitespace-username-20260206-081500.yaml` (correct)
- `logs/validations/fix-validation-whitespace-username-20260206-082215.yaml` (correct)
- `logs/diagnostics/bulwark-issue-analyzer-20260206-081500.yaml` (correct)
- `logs/diagnostics/bulwark-fix-validator-20260206-082215.yaml` (correct)

**Root Cause:** Conflicting instructions between SA2 in `Rules.md` and agent-specific output specs:
- **SA2 (generic rule)**: "Sub-agent output written to `logs/{agent-name}-{timestamp}.md`"
- **Agent definitions**: Specify YAML files at specific paths (e.g., `logs/debug-reports/`, `logs/validations/`)

Sub-agents followed BOTH instructions, producing duplicate outputs: the correct YAML to the specified path AND an extra `.md` to `logs/` per the generic SA2 pattern.

**Fixed:** Updated SA2 in `Rules.md` with closed-loop language:
- When agent definition specifies output paths/format → MUST use those exact paths, no additional files
- When no output path specified → MUST fall back to `logs/{agent-name}-{timestamp}.md`
- "Every sub-agent MUST produce exactly the artifacts specified - no more, no fewer"

**Files Updated:**
- `Rules.md` (SA2 rule updated)

**Verification:** Requires re-testing in fresh session to confirm agents produce only specified outputs.

---

### DEF-P4-007: subagent_type always "unknown" in SubagentStart/SubagentStop hook JSON

**Identified:** Session 45 (2026-02-08)
**Phase:** P4.4 Manual Testing
**Severity:** Medium
**Status:** Open (investigation needed)

**Symptom:** Both `track-pipeline-start.sh` and `track-pipeline-stop.sh` log `(unknown)` for every sub-agent's type. The log verification feature added in T-033 (track-pipeline-stop.sh) is effectively dead code — it only runs when `SUBAGENT_TYPE != "unknown"`, which never happens.

**Evidence:** Every SubagentStart and SubagentStop entry in hooks.log since January 12, 2026 (hundreds of entries across 40+ sessions) shows `(unknown)`:
```
[2026-02-08T16:04:01Z] SubagentStart: a50a53d (unknown)
[2026-02-08T16:07:55Z] SubagentStop: a50a53d (unknown)
```

**Root Cause (suspected):** Both scripts use `jq -r '.subagent_type // "unknown"'` to extract the type from stdin JSON. Either:
1. The field name in the actual Claude Code JSON payload differs from `subagent_type` (e.g., `type`, `agent_type`, `subagent_name`)
2. The field is not present in the payload at all
3. The JSON structure is nested differently than expected

**Investigation needed:** Dump the raw stdin JSON from a SubagentStart or SubagentStop hook to determine the actual payload structure and field names. Add to `track-pipeline-start.sh`:
```bash
echo "$INPUT" > "$LOGS_DIR/debug-subagent-start-payload.json"
```

**Impact:**
- `track-pipeline-stop.sh` log verification (T-033) never executes — all custom agents skip verification
- Pipeline tracking logs lack agent type information, making debugging harder
- This is a pre-existing issue (since project inception) but only became visible when T-033 added a consumer that depends on the parsed type

**Files Affected:**
- `scripts/hooks/track-pipeline-start.sh` (logs unknown)
- `scripts/hooks/track-pipeline-stop.sh` (log verification dead code)

**Potential Framework Observation:** If the field genuinely doesn't exist in Claude Code's hook JSON payload, this should be logged as FW-OBS-004 in `docs/fw-observations.md`.

---

## Open Enhancements

### ENH-P4-002: Clarify test-audit summary with distinct Verification Quality vs Test Coverage metrics

**Identified:** Session 37 (2026-02-02)
**Phase:** P4.2 Manual Testing
**Severity:** Low (UX improvement)
**Status:** Open

**Problem:** The test-audit summary output conflates two distinct metrics:
- "Test Effectiveness: 100%" (T1-T4 compliance - quality of written tests)
- "Coverage: 40%" (edge case/boundary coverage - completeness of test scenarios)

Users may confuse "100% effectiveness" as meaning tests are complete when coverage is actually poor.

**Current Output:**
```
Overall test effectiveness: 100%
...
Coverage Gap Analysis: 27 Issues Found
...coverage gaps (~40% coverage of realistic scenarios)
```

**Proposed Output:**
```
Verification Quality: 100% (written tests are T1-T4 compliant)
Test Coverage: 40% (edge cases/boundaries covered)
Coverage Gap: Critical (target: >80%)
```

**Industry Standard Reference:**
- 80% - Generally accepted "good enough" target
- 90%+ - High-quality production code
- 100% - Critical systems (medical, financial, aerospace)

**Files to Update:**
- `skills/test-audit/SKILL.md` - Update summary output template
- Update "Output Schema" section with distinct metrics

---

### ENH-P4-003: Agent-scoped quality enforcement for bulwark-verify script generation

**Identified:** Session 38 (2026-02-06)
**Phase:** P4.2 Manual Testing (hook investigation)
**Severity:** Medium (architectural gap)
**Status:** Open (deferred to P6.8)

**Problem:** When `bulwark-verify` is invoked (e.g., `/bulwark-verify src/cli.ts`), Step 4 spawns a `general-purpose` Sonnet sub-agent to generate a verification script. This sub-agent writes to `tmp/verification/` using the Write tool. However:

1. **PostToolUse hooks do not fire for sub-agent tool calls** - only main agent tool calls trigger PostToolUse
2. **No SubagentToolUse hook exists** in Claude Code's hook system
3. **`enforce-quality.sh` explicitly skips `tmp/`** paths (to prevent infinite loops on log writes)
4. **The sub-agent uses ad-hoc npx commands** instead of Justfile recipes for syntax validation

This means verification scripts are the **only code-writing path** in The Bulwark that bypasses quality enforcement entirely. All other paths are covered:

| Code-Writing Path | Quality Enforcement |
|-------------------|-------------------|
| Main agent writes code | PostToolUse → enforce-quality.sh |
| bulwark-implementer (P4.4) | Agent-scoped PostToolUse in frontmatter |
| Pipeline stages (general-purpose) | Next pipeline stage validates |
| **bulwark-verify sub-agent** | **None - GAP** |

**Root Cause:** `bulwark-verify` uses `subagent_type="general-purpose"` which has no agent markdown file and therefore no mechanism to attach PostToolUse hooks. Agent-scoped hooks can only be defined in custom agent markdown files (`agents/*.md`).

**Proposed Fix (3 deliverables):**

1. **Create custom agent `agents/bulwark-verify-scriptgen.md`**
   - Frontmatter: `agent: sonnet`
   - Frontmatter: `skills: [assertion-patterns, component-patterns, bug-magnet-data]`
   - Frontmatter: PostToolUse hook referencing `enforce-quality-tmp.sh` (matcher: `Write|Edit`)
   - Agent instructions: Generate verification scripts following 4-part prompt from bulwark-verify skill
   - Output to `tmp/verification/` and `logs/bulwark-verify-*.yaml`

2. **Create `scripts/hooks/enforce-quality-tmp.sh`**
   - Clone of `enforce-quality.sh` scoped specifically to `tmp/` folder
   - Key differences from `enforce-quality.sh`:
     - Does NOT skip `tmp/` paths (inverted from main script's exclusion)
     - ONLY processes files in `tmp/` (rejects everything else - safety boundary)
     - Runs same Justfile recipes: `just typecheck`, `just lint`, `just build`
     - Exit 2 on failure (blocks the sub-agent's tool call, forcing correction)
     - Does NOT chain to `suggest-pipeline.sh` (not applicable for sub-agent context)
   - Note: `tsconfig.json` may need `tmp/verification/**/*.ts` added to `include` for typecheck to work on generated scripts. Evaluate during implementation.

3. **Update `skills/bulwark-verify/SKILL.md` Step 4**
   - Change from: `Task(subagent_type="general-purpose", model="sonnet", ...)`
   - Change to: `Task(subagent_type="bulwark-verify-scriptgen", ...)`
   - Model selection moves to agent frontmatter (no longer specified in Task call)

**Architecture:**
```
/bulwark-verify src/cli.ts
    → Orchestrator loads skill, analyzes component (Steps 1-3)
    → Step 4: Task(subagent_type="bulwark-verify-scriptgen")
        → Agent starts with PostToolUse hook active
        → Sub-agent writes to tmp/verification/
        → enforce-quality-tmp.sh fires on Write
        → just typecheck / just lint / just build
        → Exit 2 blocks if quality fails → sub-agent self-corrects
    → Step 5-6: Orchestrator validates and reports
```

**Why not modify enforce-quality.sh directly?**
- `enforce-quality.sh` MUST skip `tmp/` to prevent infinite loops when writing logs and other infrastructure files
- Creating a separate script maintains clean separation of concerns
- Each script has a clear, bounded scope: one for project files, one for generated scripts

**Impact:** Closes the last unguarded code-writing path in The Bulwark. All generated code (production or ephemeral) passes through Justfile-enforced quality gates.

**Files to Create/Update:**
- `agents/bulwark-verify-scriptgen.md` (NEW)
- `scripts/hooks/enforce-quality-tmp.sh` (NEW)
- `skills/bulwark-verify/SKILL.md` (UPDATE Step 4)
- `tsconfig.json` (EVALUATE - may need tmp/ include for typecheck)
- `.claude/agents/bulwark-verify-scriptgen.md` (SYNC)

---

### ENH-P4-001: Add UserPromptSubmit hook to prefer skills over direct actions

**Identified:** Session 33 (2026-01-31)
**Phase:** P4.1 Manual Testing
**Severity:** Low (non-blocking)
**Status:** Open

**Problem:** Claude does not automatically load skills based on conversational prompts that match skill trigger patterns. Even when user request matches "When to Use This Skill" patterns exactly, Claude defaults to direct implementation instead of invoking the skill.

**Example:**
- Prompt: "Please perform a code review of scripts/components/user-service.ts"
- Expected: Claude invokes `/code-review` skill
- Actual: Claude reads file directly and performs manual review

**Proposed Fix:** Add a `UserPromptSubmit` hook that injects context reminding Claude to prefer skills/agents/commands.

**Hook Configuration:**
```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PROJECT_DIR}/scripts/hooks/prefer-skills.sh",
            "timeout": 5000
          }
        ]
      }
    ]
  }
}
```

**Hook Script (`scripts/hooks/prefer-skills.sh`):**
```bash
#!/bin/bash
# Reminds Claude to prefer skills, agents, and commands over direct actions

cat << 'EOF'
WORKFLOW PREFERENCE: Before taking direct action on this request, check if any available skills, agents, or commands match the user's intent. Prefer invoking the appropriate skill/agent/command over implementing the solution directly. Only use direct implementation when no matching skill, agent, or command exists.
EOF

exit 0
```

**Rationale:** Per Anthropic documentation, `UserPromptSubmit` "runs when the user submits a prompt, before Claude processes it" and "any text your hook script prints to stdout is added as context." This ensures Claude sees the reminder with every user message.

---

## Closed Enhancements

(None)

---

## Pending Cleanup Tasks

### CLEANUP-P4-001: Remove code-review test fixtures

**Status:** Pending (after P4.1 testing complete)
**Phase:** P4.1

**Direct invocation fixtures:**
```bash
rm -rf scripts/components/
```

**Pipeline integration fixtures:**
```bash
rm -rf scripts/services/
```

**Supporting stubs:**
```bash
rm -f scripts/lib/database.ts
rm -f scripts/lib/logger.ts
rmdir scripts/lib/ 2>/dev/null || true
```

**Verification:**
```bash
just typecheck
just lint
git status
```

---

## Completed Cleanup Tasks

(None yet)
