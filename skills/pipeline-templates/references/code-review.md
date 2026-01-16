# Code Review Pipeline

## Purpose

Review code for quality, security, and correctness before merge or deployment.

## When to Use

- PR reviews
- Code audits
- Pre-deployment verification
- Security assessments

## Pipeline Definition

```fsharp
// Code Review Pipeline
// Trigger: Code changes requiring review
// Output: Review report with findings and severity

SecurityAuditor (identify security issues)      // Sonnet - nuanced judgment
|> TypeSafetyAuditor (check type safety)        // Sonnet - nuanced judgment
|> (if critical_issues > 0
    then CodeReviewer (comprehensive review)    // Sonnet - synthesis
    else QuickReviewer (summary only))          // Haiku - quick pass
|> (if actionable_findings > 0
    then FixWriter (apply fixes)                // Opus - write code
    else Done)
```

## Stage Details

### Stage 1: SecurityAuditor

**Model**: Sonnet (nuanced judgment required)

**GOAL**: Identify security vulnerabilities in the code changes.

**CONSTRAINTS**:
- Do NOT modify any files
- Focus on OWASP Top 10 patterns
- Flag severity: critical, high, medium, low

**CONTEXT**:
- Files changed in PR/commit
- Project security requirements (if any)

**OUTPUT**: Security findings in YAML format
```yaml
findings:
  - file: path/to/file.ts
    line: 42
    severity: high
    pattern: SQL_INJECTION
    description: User input not sanitized
    recommendation: Use parameterized queries
```

### Stage 2: TypeSafetyAuditor

**Model**: Sonnet (nuanced judgment required)

**GOAL**: Identify type safety issues that could cause runtime errors.

**CONSTRAINTS**:
- Do NOT modify any files
- Focus on `any` usage, null handling, unsafe assertions
- Consider TypeScript strict mode violations

**CONTEXT**:
- Files changed in PR/commit
- Project TypeScript configuration

**OUTPUT**: Type safety findings in YAML format
```yaml
findings:
  - file: path/to/file.ts
    line: 15
    severity: medium
    pattern: ANY_USAGE
    description: Using 'any' bypasses type checking
    recommendation: Define proper interface
```

### Stage 3: CodeReviewer / QuickReviewer

**Model**: Sonnet (comprehensive) or Haiku (quick pass)

**Conditional**: Run comprehensive review only if critical issues found.

**GOAL**: Synthesize all findings into actionable review.

**CONSTRAINTS**:
- Do NOT modify any files
- Prioritize findings by impact
- Provide clear fix guidance

**OUTPUT**: Review report
```yaml
review:
  status: changes_requested | approved
  summary: "3 issues found: 1 critical, 2 medium"
  priority_fixes:
    - "Fix SQL injection in auth.ts:42"
    - "Add null check in user.ts:15"
```

### Stage 4: FixWriter (Conditional)

**Model**: Opus (code writing required)

**Conditional**: Only run if actionable findings exist.

**GOAL**: Apply fixes for identified issues.

**CONSTRAINTS**:
- Only fix issues from the review
- Maintain existing code style
- Do NOT refactor unrelated code

**OUTPUT**: Applied fixes with verification plan

## Example Invocation

```markdown
## Pipeline: Code Review

### Stage 1: SecurityAuditor
Task: subagent_type=general-purpose, model=sonnet
Prompt: [4-part prompt with files to review]

### Stage 2: TypeSafetyAuditor
Task: subagent_type=general-purpose, model=sonnet
Prompt: [4-part prompt, reads Stage 1 output]

### Stage 3: CodeReviewer
Condition: critical_issues > 0 from Stage 1+2
Task: subagent_type=general-purpose, model=sonnet
Prompt: [4-part prompt, synthesizes findings]

### Stage 4: FixWriter
Condition: actionable_findings > 0 from Stage 3
Task: subagent_type=general-purpose, model=opus
Prompt: [4-part prompt, applies fixes]
```

## Success Criteria

- All security patterns checked
- All type safety issues identified
- Review report generated with clear priorities
- Fixes applied (if requested and needed)

## Related Pipelines

- **Fix Validation**: For fixing issues found in review
- **Test Audit**: For reviewing test quality specifically
