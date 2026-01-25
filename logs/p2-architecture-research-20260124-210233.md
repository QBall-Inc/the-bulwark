# P2 Architecture Research - Verification Scripts Phase

**Date**: 2026-01-24
**Researcher**: Claude Opus 4.5
**Phase**: P2 (Verification Scripts)
**Tasks Analyzed**: P2.1 (assertion-patterns), P2.2 (component-patterns), P2.3 (verification-script)

---

## Executive Summary

P2 (Verification Scripts) represents a **deferred capability** in the Bulwark architecture - skills designed to generate runnable bash scripts that verify component behavior without mocks. However, **no current pipeline actively uses P2 skills**, and there is **no immediate consumer** blocking on their completion.

The architecture documents describe P2's purpose, but evidence suggests P2 is:
1. **Speculative**: Created for future test rewriting workflows
2. **Non-blocking**: No dependency chains waiting on P2
3. **Potentially redundant**: Overlaps with existing test-audit rewrite workflow

---

## Question 1: What is the stated purpose of P2.1-P2.3?

### From tasks.yaml

| Task | Deliverable | Purpose |
|------|-------------|---------|
| **P2.1** | `skills/assertion-patterns/SKILL.md` | Document forbidden/required assertion patterns, transformation examples |
| **P2.2** | `skills/component-patterns/SKILL.md` | Document per-component verification approaches (CLI, HTTP, files, processes) |
| **P2.3** | `skills/verification-script/SKILL.md` | Orchestrate P2.1 + P2.2 to produce runnable bash scripts that report pass/fail |

**Frontmatter**:
- P2.1 and P2.2: `user-invocable: false` (internal skills)
- P2.3: `user-invocable: true`, `agent: sonnet` (user-facing composite)

### From architecture.md

> **Foundation Skills (Internal)**: `assertion-patterns` - Real output verification vs mock calls

> **Composite Skills (User-Facing)**: `verification-script` - Uses component-patterns, assertion-patterns. Create runnable verification scripts. `agent: sonnet`, `user-invocable: true`

### From the-bulwark-plan.md

**Phase 2 Goal**: "Skills for creating verification scripts"

**Exit Criteria**:
- Can create verification scripts for components
- Scripts report pass/fail

**Use Cases Mentioned**:
- Ralph Wiggum loop skill-creator guidance: "Creating verification scripts"
- Commands: `/bulwark:verify` (P5.2) will "invoke verification-script skill" and "run generated scripts"

---

## Question 2: What depends on P2.1-P2.3?

### Direct Dependencies (from tasks.yaml)

```
P2.3 (verification-script) depends on: [P2.1, P2.2]
P5.2 (/bulwark:verify command) depends on: [P2.3]
```

**Chain**: P2.1 + P2.2 → P2.3 → P5.2

### No Current Pipeline Blockers

**Critical Finding**: No currently defined pipeline is blocked by P2:

| Pipeline | P0 Status | P1 Status | P2 Status | Blocked? |
|----------|-----------|-----------|-----------|----------|
| Code Review | ✓ Complete (P0.3) | ✓ Complete | - | **NO** |
| Fix Validation | ✓ Complete (P0.4, P0.1) | ✓ Complete (P1.2, P1.3) | - | **NO** |
| Test Audit | ✓ Complete (P0.6-8) | N/A (Main Context Orchestration) | - | **NO** |
| New Feature | ✓ Complete (P0.3) | - | - | **NO** |
| Research & Planning | ✓ Complete (P0.3) | - | - | **NO** |
| Test Execution & Fix | ✓ Complete (P0.3) | - | - | **NO** |

**Analysis**: All pipelines in `skills/pipeline-templates/references/` are operational without P2.

---

## Question 3: Which pipelines reference verification-script?

### Search Results

**Pattern searched**: `VerificationScriptCreator|verification.*script` (case-insensitive)

**Files searched**:
- `skills/pipeline-templates/references/*.md` (all 7 pipeline files)
- `plans/the-bulwark-plan.md`
- `plans/tasks.yaml`
- `docs/architecture.md`

### Findings

#### Test Audit Pipeline (Historical Reference - Not Current)

**File**: `plans/the-bulwark-plan.md` (line 127, 431)

```fsharp
// Test Audit Pipeline
TestAuditor (classify)
|> (if mock_heavy > 0 then VerificationScriptCreator else Done)
|> Implementer (rewrite)
|> TestAuditor (re-verify)
```

**Status**: **OUTDATED**

The current Test Audit pipeline (`skills/pipeline-templates/references/test-audit.md`) does NOT include `VerificationScriptCreator`. Current workflow:

```fsharp
// ACTUAL Test Audit Pipeline (test-audit.md)
test-classification (Haiku sub-agent)
|> mock-detection (Sonnet sub-agent)
|> test-audit synthesis (Sonnet sub-agent, REWRITE_REQUIRED directive)
|> (if REWRITE_REQUIRED == true
    then Orchestrator (Opus) rewrites tests
    else Done)
|> LOOP(max=2)
```

**No verification script generation step exists in actual implementation.**

#### `/bulwark:verify` Command (P5.2 - Not Started)

**File**: `plans/the-bulwark-plan.md` (line 662)

| Command | Actions | Required Script |
|---------|---------|-----------------|
| `/bulwark:verify` | Run verification scripts | `scripts/verify.sh` |

**Status**: Not yet implemented. **Speculative future capability**.

#### No Other References

**Confirmation**:
- `skills/pipeline-templates/SKILL.md` - No mention
- All 7 pipeline reference files - No mention
- `docs/architecture.md` - Only definitional (what it is, not how it's used)

---

## Question 4: Is there a documentation gap about P2's integration?

### Documentation vs Reality Gap

| Document | Claim | Reality |
|----------|-------|---------|
| **the-bulwark-plan.md** (line 127) | Test Audit uses VerificationScriptCreator | Test Audit does NOT use it (confirmed in test-audit.md) |
| **architecture.md** | Lists verification-script as composite skill | True, but no integration path documented |
| **tasks.yaml** | P2.3 depends on P2.1 + P2.2 | True, but dependency chain terminates at P5.2 (future) |

### Integration Path Gap

**Question**: If a user has mock-heavy tests flagged by Test Audit, how do they use P2 skills?

**Expected Workflow (based on docs)**:
1. Run `/test-audit` → identifies mock-heavy tests
2. Run `/bulwark:verify` (P5.2) → generates verification scripts via P2.3
3. Run generated scripts → verify behavior without mocks
4. Rewrite tests based on verification script results

**Actual Workflow (current implementation)**:
1. Run `/test-audit` → identifies mock-heavy tests with REWRITE_REQUIRED directive
2. Orchestrator (Opus) rewrites tests directly (no script generation)
3. Re-run `/test-audit` to verify (LOOP max=2)

**Gap Identified**: P2 skills are **designed but not integrated** into any active workflow.

---

## Architectural Analysis

### P2's Original Intent

Based on the phase naming ("Verification Scripts") and skill descriptions, P2 was designed to support:

1. **Scriptable Verification**: Generate bash scripts to verify components
2. **Reusable Patterns**: Document how to verify different component types
3. **Manual/CI Testing**: Scripts could run outside Claude Code

**Use Case**: After Test Audit flags mock-heavy tests, developers could:
- Generate verification scripts
- Run them manually or in CI
- Use results to inform test rewrites

### Current Reality

The Test Audit pipeline evolved to use **direct rewriting** instead of **script-based verification**:

**Advantages of Direct Rewriting**:
- Faster: No intermediate script generation
- Simpler: Fewer steps in pipeline
- Integrated: Happens in same session

**Disadvantages**:
- No reusable verification artifacts
- Cannot run verification outside Claude Code session
- No CI integration path

### Hypothesis: P2 is a Vestigial Design

Evidence:
1. **P0.6-8 completed** without referencing P2 (Test Audit works without it)
2. **P1 completed** without referencing P2 (Fix Validation works without it)
3. **No pipeline file references P2** skills
4. **P5.2 is the only consumer** and it's marked "nice-to-have" implicitly

**Conclusion**: P2 may have been designed for a verification-script-first approach that was superseded by the direct-rewrite pattern in P0.8.

---

## Dependency Analysis

### Reverse Dependency Chain

```
P2.1 (assertion-patterns)  ─┐
                            ├──> P2.3 (verification-script) ──> P5.2 (/bulwark:verify)
P2.2 (component-patterns)  ─┘
```

**P5.2 Status**: Not started, estimated 1 session

**Blocking Impact**: If P2.1-P2.3 are skipped:
- P5.2 cannot be implemented as currently spec'd
- No other deliverable is affected

### Forward Dependency Chain

**Who needs P2 complete before they can start?**

| Task | Depends On | Can Start Without P2? |
|------|------------|----------------------|
| P3.1-P3.5 (Enforcement) | None | **YES** |
| P4.1-P4.4 (Review Skills) | None | **YES** |
| P5.1 (/audit) | P0.8 | **YES** |
| P5.2 (/verify) | P2.3 | **NO** - directly blocked |
| P5.3-P5.5 (Evolution) | P0.2 | **YES** |
| P5.6-P5.12 (Testing/Polish) | Various | **YES** |

**Analysis**: Only P5.2 is blocked. All other work can proceed.

---

## Recommendations

### Option 1: Implement P2 As-Is

**Rationale**: Fulfill original design, enable P5.2

**Effort**: 3 sessions (P2.1 + P2.2 + P2.3)

**Value**: Creates manual verification capability, CI integration potential

**Risks**: May not see actual use if direct-rewrite pattern dominates

### Option 2: Defer P2 Until After P5.2

**Rationale**: Validate demand before implementation

**Approach**:
1. Complete P3, P4, P5.1, P5.3-P5.12 first
2. Gather user feedback on test-audit workflow
3. If users request scriptable verification, implement P2 + P5.2
4. If not, mark P2 as "Future Enhancement"

**Advantage**: Evidence-based prioritization

### Option 3: Consolidate P2 Into P0.8 Enhancement

**Rationale**: If verification scripts are valuable, integrate into test-audit skill

**Approach**:
- Add optional `--generate-scripts` flag to `/test-audit`
- Output verification scripts alongside YAML audit report
- No separate P2.1-P2.3 skills needed

**Advantage**: Unified workflow, fewer skills to maintain

### Option 4: Redesign P2 for Different Use Case

**Observation**: P2 skills describe **how to verify components**, not just test assertions.

**Alternative Use**: Component verification for **Fix Validation pipeline**

**Hypothesis**: When fixing bugs, verification scripts could:
- Verify the fix works without running full test suite
- Provide minimal repro case
- Enable faster iteration

**Integration Point**: P1.3 (bulwark-fix-validator) could generate verification scripts as part of validation plan

**Advantage**: Active consumer (Fix Validation), not speculative

---

## Next Steps

### Immediate Action Required

**Decision Point**: Before implementing P2.1-P2.3, determine:

1. **Is P5.2 (/bulwark:verify) still desired?**
   - If yes → Implement P2 as planned
   - If no → Skip or redesign P2

2. **Should verification scripts integrate into existing pipelines?**
   - Test Audit: Add script generation to rewrite workflow?
   - Fix Validation: Add script generation to validation plan?

3. **Is there user demand for scriptable verification?**
   - Evidence: None yet (no users of the plugin)
   - Approach: Speculative design vs deferred implementation

### Recommended Path Forward

**Propose to user**:

1. **Skip P2 for now** - No active consumer blocks development
2. **Complete P3 (Enforcement)** - Higher value, enables quality gates
3. **Complete P4 (Review Skills)** - Completes Code Review pipeline
4. **Revisit P2 after user feedback** - Evidence-based prioritization

**Rationale**: P2 is well-designed but may be solving a problem the architecture no longer has. Direct rewriting (current approach) is simpler and faster. If users request scriptable verification, P2 can be implemented then.

---

## Appendix: Complete P2 Task Definitions

### P2.1 - assertion-patterns

**Deliverable**: `skills/assertion-patterns/SKILL.md`

**Acceptance Criteria**:
- Forbidden patterns documented
- Required patterns documented
- Transformation examples included
- Frontmatter: `user-invocable: false`

**Verification**:
- Identify forbidden pattern in sample
- Suggest correct replacement

**Estimated**: 1 session

### P2.2 - component-patterns

**Deliverable**: `skills/component-patterns/SKILL.md`

**Acceptance Criteria**:
- CLI command verification pattern
- HTTP server verification pattern
- File parser verification pattern
- Process spawner verification pattern
- Frontmatter: `user-invocable: false`

**Verification**:
- Generate verification approach for each type

**Estimated**: 1 session

### P2.3 - verification-script

**Deliverable**: `skills/verification-script/SKILL.md`

**Acceptance Criteria**:
- Orchestrates component-patterns and assertion-patterns
- Produces runnable bash scripts
- Scripts report pass/fail
- Frontmatter: `agent: sonnet`, `user-invocable: true`

**Verification**:
- Create verification script for sample component
- Run script, verify it catches failures
- Verify skill appears in / menu

**Estimated**: 1 session

---

## References

- `plans/tasks.yaml` - Task definitions and dependencies
- `docs/architecture.md` - Architecture overview
- `plans/the-bulwark-plan.md` - Master plan document
- `skills/pipeline-templates/SKILL.md` - Pipeline definitions
- `skills/pipeline-templates/references/test-audit.md` - Actual Test Audit implementation
- `sessions/session_17_20260120.md` - P2 brainstorming mention
- `sessions/session_18_20260124.md` - Latest session handoff
