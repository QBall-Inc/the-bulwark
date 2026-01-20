---
name: fix-bug
description: Run the Fix Validation pipeline to investigate, fix, and validate a bug. Ensures deterministic pipeline execution with IssueAnalyzer, FixWriter, TestWriter (conditional), TestAudit (conditional), and FixValidator stages.
user-invocable: true
---

# Fix Bug Pipeline

This skill triggers the **Fix Validation pipeline** to systematically investigate, fix, and validate a bug.

## When to Use This Skill

**Load this skill when the user request matches ANY of these patterns:**

| Trigger Pattern | Example User Request |
|-----------------|---------------------|
| Bug fix requests | "Fix this bug", "Something is broken in X" |
| Error investigation | "Users report errors in X", "This feature isn't working" |
| Regression fixes | "This used to work", "Breaking after recent changes" |
| Production issues | "Login fails for new accounts", "API returns 500" |
| Flaky behavior | "Tests pass sometimes", "Intermittent failures" |

**DO NOT use this skill for:**

| Anti-Pattern | Use Instead |
|--------------|-------------|
| Ad-hoc fixes without investigation | Direct fix (skip pipeline) |
| Simple typo corrections | Direct edit |
| Refactoring without reported issues | Code Review pipeline |
| Adding new features | New Feature pipeline |
| Performance optimization | Research & Planning pipeline |

## Why This Skill Exists

Without this skill, conversational prompts like "please investigate and fix this bug" may cause Claude to skip pipeline stages and fix directly. This skill ensures **deterministic execution** of all Fix Validation pipeline stages.

## Usage

```
/fix-bug <path> [description]
```

**Arguments**:
- `$1` (required): Path to code with the bug
- `$2` and beyond (optional): Description of the issue - recommended for better analysis

**Examples**:
```
/fix-bug src/auth/login.ts "Users report login fails for new accounts"
/fix-bug tests/fixtures/fix-validator/simple-fix/ "Cannot read property displayName of undefined"
/fix-bug src/api/routes.ts
```

## Pipeline Stages

When invoked, follow the Fix Validation pipeline exactly:

```fsharp
IssueAnalyzer (bulwark-issue-analyzer)
|> FixWriter (you implement the fix)
|> (if !tests_cover_scenario
    then TestWriter |> TestAudit
    else Skip)
|> FixValidator (bulwark-fix-validator)
|> CodeReviewer (you review)
|> (if !approved then IssueAnalyzer else Done)
|> LOOP(max=3)
```

## Execution Instructions

### Stage 1: IssueAnalyzer

**MUST** spawn `bulwark-issue-analyzer` agent via Task tool:

```
Task(
  subagent_type="bulwark-issue-analyzer",
  model="sonnet",
  prompt="GOAL: Analyze the bug and produce a debug report..."
)
```

**Input**: Path from `$1`, description from `$2` onward

**Output**: Debug report at `logs/debug-reports/{issue-id}-{timestamp}.yaml`

**Do NOT** skip this stage. The debug report is required for subsequent stages.

### Stage 2: FixWriter

**Actor**: You (orchestrator)

**Input**: Read the debug report from Stage 1

**Action**: Implement the fix following the `fix_approach` from the debug report

**Constraints**:
- Only fix the identified issue
- Follow existing code patterns
- Do NOT refactor unrelated code

### Stage 3: TestWriter (Conditional)

**Condition**: Check debug report's `validation_plan.recommendation.new_tests_needed`

**If tests needed**:
1. Write tests that verify the fix
2. Cover the specific bug scenario
3. Follow T1-T4 rules (no mocking system under test)

**If tests exist**: Skip to Stage 3b or Stage 4

### Stage 3b: TestAudit (Conditional)

**Condition**: Only if TestWriter created/modified tests

**Action**: Run mock-detection on new tests to verify T1-T4 compliance

**If T1 violation**: Return to TestWriter, request rewrite

**If T2-T4 violations**: Log warning, proceed

### Stage 4: FixValidator

**MUST** spawn `bulwark-fix-validator` agent via Task tool:

```
Task(
  subagent_type="bulwark-fix-validator",
  model="sonnet",
  prompt="GOAL: Validate the fix against the debug report...

  CONTEXT:
  Debug Report: logs/debug-reports/{issue-id}-{timestamp}.yaml
  Fix Applied: {description of changes}
  Tests Added: {if any}
  ..."
)
```

**Input**: Debug report path, fix details, test details

**Output**: Validation report at `logs/validations/fix-validation-{issue-id}-{timestamp}.yaml`

### Stage 5: CodeReviewer

**Actor**: You (orchestrator)

**Action**: Review the fix considering:
- Does it address root cause from debug report?
- Are tests adequate?
- What is the FixValidator confidence level?
- Any regressions?

**Decision**: Approve or reject

### Loop Handling

If rejected and iterations < 3:
- Return to Stage 1 with feedback
- Include previous validation results

If rejected and iterations >= 3:
- Escalate to user
- Summarize all attempts

## Progress Reporting

After each stage, report progress to user:

```
Stage 1 (IssueAnalyzer): Complete
  - Debug report: logs/debug-reports/AUTH-001-20260120.yaml
  - Root cause: {summary}
  - Complexity: {low|medium|high}

Stage 2 (FixWriter): Complete
  - Files modified: {list}
  - Fix: {brief description}

Stage 3 (TestWriter): {Complete|Skipped}
  - Tests added: {count or "existing tests sufficient"}

Stage 4 (FixValidator): Complete
  - Confidence: {HIGH|MEDIUM|LOW}
  - Recommendation: {proceed|revise}

Stage 5 (CodeReviewer): Complete
  - Decision: {Approved|Rejected}
```

## Error Handling

| Error | Action |
|-------|--------|
| IssueAnalyzer fails to identify root cause | Report to user, ask for more context |
| Tests cannot be executed | FixValidator uses manual validation strategy |
| FixValidator confidence is LOW | Escalate to user with details |
| Max iterations reached | Summarize attempts, ask user for guidance |

## Related Resources

| Resource | Location |
|----------|----------|
| Pipeline definition | `pipeline-templates/references/fix-validation.md` |
| IssueAnalyzer agent | `agents/bulwark-issue-analyzer.md` |
| FixValidator agent | `agents/bulwark-fix-validator.md` |
| Issue debugging skill | `issue-debugging/SKILL.md` |

**Note**: Paths are relative to your skills/agents directory (either `skills/` or `.claude/skills/`).
