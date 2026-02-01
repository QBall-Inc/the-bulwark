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

## Open Enhancements

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
