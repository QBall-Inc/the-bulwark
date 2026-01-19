# Code Review Pipeline

## Purpose

Review code for quality, security, and correctness before merge or deployment.

## When to Use

- PR reviews
- Code audits
- Pre-deployment verification
- Security assessments

## Architecture: Role-Based Agents

This pipeline uses **role-based general-purpose agents**. Each agent:
1. Loads the `code-review` skill via frontmatter (`skills: code-review`)
2. References a specific section of the skill based on its role
3. Outputs findings in a standardized YAML format

**Standalone alternative**: For ad-hoc code auditing outside pipelines, use `bulwark-code-auditor` which runs all sections.

## Pipeline Definition

```fsharp
// Code Review Pipeline
// Trigger: Code changes requiring review
// Output: Review report with findings and severity

SecurityReviewer (section: Security)            // Sonnet - role-based
|> TypeSafetyReviewer (section: Type Safety)    // Sonnet - role-based
|> LintReviewer (section: Linting)              // Sonnet - role-based
|> StandardsReviewer (section: Coding Standards) // Sonnet - role-based
|> ReviewSynthesizer (consolidate all findings) // Sonnet - synthesis
|> (if critical_issues > 0
    then FixWriter (apply fixes)                // Opus - write code
    else Done)
```

## Stage Details

### Role-Based Agent Pattern

Each review stage uses a general-purpose agent with:
- **Frontmatter**: `skills: code-review`
- **Prompt**: Specifies which section to reference
- **Output**: Standardized YAML findings format

### Stage 1: SecurityReviewer

**Type**: General-purpose agent with role

**Model**: Sonnet (nuanced judgment required)

**Skill Section**: Security

**GOAL**: Identify security vulnerabilities using the Security section of code-review skill.

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
  section: security
  items:
    - file: path/to/file.ts
      line: 42
      severity: high
      pattern: SQL_INJECTION
      description: User input not sanitized
      recommendation: Use parameterized queries
```

### Stage 2: TypeSafetyReviewer

**Type**: General-purpose agent with role

**Model**: Sonnet (nuanced judgment required)

**Skill Section**: Type Safety

**GOAL**: Identify type safety issues using the Type Safety section of code-review skill.

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
  section: type_safety
  items:
    - file: path/to/file.ts
      line: 15
      severity: medium
      pattern: ANY_USAGE
      description: Using 'any' bypasses type checking
      recommendation: Define proper interface
```

### Stage 3: LintReviewer

**Type**: General-purpose agent with role

**Model**: Sonnet (nuanced judgment required)

**Skill Section**: Linting

**GOAL**: Identify code style and formatting issues using the Linting section of code-review skill.

**CONSTRAINTS**:
- Do NOT modify any files
- Check complexity metrics
- Identify formatting violations

**CONTEXT**:
- Files changed in PR/commit
- Project linting configuration (if any)

**OUTPUT**: Linting findings in YAML format
```yaml
findings:
  section: linting
  items:
    - file: path/to/file.ts
      line: 100
      severity: low
      pattern: HIGH_COMPLEXITY
      description: Function has cyclomatic complexity of 15
      recommendation: Split into smaller functions
```

### Stage 4: StandardsReviewer

**Type**: General-purpose agent with role

**Model**: Sonnet (nuanced judgment required)

**Skill Section**: Coding Standards

**GOAL**: Check coding standards using the Coding Standards section of code-review skill.

**CONSTRAINTS**:
- Do NOT modify any files
- Check naming conventions
- Verify documentation requirements
- Check pattern compliance

**CONTEXT**:
- Files changed in PR/commit
- Project coding standards (if any)

**OUTPUT**: Standards findings in YAML format
```yaml
findings:
  section: coding_standards
  items:
    - file: path/to/file.ts
      line: 5
      severity: low
      pattern: NAMING_CONVENTION
      description: Function name doesn't follow camelCase
      recommendation: Rename to camelCase
```

### Stage 5: ReviewSynthesizer

**Type**: General-purpose agent

**Model**: Sonnet (synthesis task)

**GOAL**: Consolidate all findings into actionable review report.

**CONSTRAINTS**:
- Do NOT modify any files
- Prioritize findings by severity and impact
- Provide clear fix guidance
- Determine overall approval status

**CONTEXT**:
- Findings from all previous stages (Security, Type Safety, Linting, Standards)

**OUTPUT**: Consolidated review report
```yaml
review:
  status: changes_requested | approved
  summary: "5 issues found: 1 critical, 2 high, 2 low"
  findings_by_severity:
    critical: 1
    high: 2
    medium: 0
    low: 2
  priority_fixes:
    - "Fix SQL injection in auth.ts:42 (critical)"
    - "Add null check in user.ts:15 (high)"
    - "Remove any usage in config.ts:30 (high)"
  all_findings:
    - {from: security, count: 1}
    - {from: type_safety, count: 2}
    - {from: linting, count: 1}
    - {from: coding_standards, count: 1}
```

### Stage 6: FixWriter (Conditional)

**Type**: Orchestrator action (Opus)

**Model**: Opus (code writing required)

**Conditional**: Only run if critical or high severity findings exist.

**GOAL**: Apply fixes for identified issues.

**CONSTRAINTS**:
- Only fix issues from the review
- Maintain existing code style
- Do NOT refactor unrelated code

**OUTPUT**: Applied fixes with verification plan

## Example Invocation

```markdown
## Pipeline: Code Review

### Stage 1: SecurityReviewer
Task: subagent_type=general-purpose, model=sonnet
Skills: code-review
Prompt:
  GOAL: Review code for security issues using the Security section of code-review skill
  CONSTRAINTS: Do not modify files, focus on OWASP Top 10
  CONTEXT: [files to review]
  OUTPUT: YAML findings with section: security

### Stage 2: TypeSafetyReviewer
Task: subagent_type=general-purpose, model=sonnet
Skills: code-review
Prompt:
  GOAL: Review code for type safety using the Type Safety section of code-review skill
  CONSTRAINTS: Do not modify files, focus on any, null, unsafe assertions
  CONTEXT: [files to review]
  OUTPUT: YAML findings with section: type_safety

### Stage 3: LintReviewer
Task: subagent_type=general-purpose, model=sonnet
Skills: code-review
Prompt:
  GOAL: Review code for linting issues using the Linting section of code-review skill
  CONSTRAINTS: Do not modify files, check complexity and formatting
  CONTEXT: [files to review]
  OUTPUT: YAML findings with section: linting

### Stage 4: StandardsReviewer
Task: subagent_type=general-purpose, model=sonnet
Skills: code-review
Prompt:
  GOAL: Review code for standards using the Coding Standards section of code-review skill
  CONSTRAINTS: Do not modify files, check naming and patterns
  CONTEXT: [files to review]
  OUTPUT: YAML findings with section: coding_standards

### Stage 5: ReviewSynthesizer
Task: subagent_type=general-purpose, model=sonnet
Prompt:
  GOAL: Consolidate all findings into actionable review
  CONTEXT: [all findings from stages 1-4]
  OUTPUT: Consolidated review report with approval status

### Stage 6: FixWriter (Conditional)
Condition: critical or high severity findings exist
Actor: Orchestrator (Opus)
Action: Apply fixes for priority issues
```

## Success Criteria

- All four review sections executed (Security, Type Safety, Linting, Coding Standards)
- Each section produces standardized YAML findings
- Findings consolidated with severity prioritization
- Review report generated with clear approval status
- Fixes applied for critical/high issues (if requested)

## Standalone Alternative

For ad-hoc code auditing outside the pipeline, use `bulwark-code-auditor`:
```
Task: subagent_type=bulwark-code-auditor, model=sonnet
```
This agent runs all four sections and produces a consolidated report.

## Related Pipelines

- **Fix Validation**: For fixing issues found in review
- **Test Audit**: For reviewing test quality specifically
