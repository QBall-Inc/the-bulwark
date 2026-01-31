# Code Review Pipeline

## Purpose

Review code for quality, security, and correctness before merge or deployment.

## When to Use

- PR reviews
- Code audits
- Pre-deployment verification
- Security assessments

## Two-Phase Workflow

**CRITICAL**: The code-review skill enforces a two-phase workflow:

```
Phase 1: Static Analysis (Deterministic)
├── Run: just typecheck → capture output
├── Run: just lint → capture output
└── If failures: STOP, return to user (fail fast)

Phase 2: LLM Review (Judgment-Based)
└── Each pipeline stage applies its section
```

Each stage assumes Phase 1 passed before running Phase 2 for its section.

## Architecture: Role-Based Agents

This pipeline uses **role-based general-purpose agents**. Each agent:
1. Loads the `code-review` skill via frontmatter (`skills: code-review`)
2. References a specific section using `--section=<name>`
3. Outputs findings using templates from `skills/code-review/templates/`

**Severity Tiers**: critical (must fix) | important (should fix) | suggestion (optional)

**Confidence Levels**: verified (data flow traced) | suspected (pattern match, needs validation)

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

**OUTPUT**: Security findings using `skills/code-review/templates/output-pipeline.yaml`
```yaml
security_review:
  section: security
  findings:
    - severity: critical
      confidence: verified
      file: path/to/file.ts
      line: 42
      pattern: sql_injection
      owasp: "A03:2021-Injection"
      evidence: "User input from req.query.id flows to db.query()"
      description: User input not sanitized
      fix: Use parameterized queries
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

**OUTPUT**: Type safety findings using `skills/code-review/templates/output-pipeline.yaml`
```yaml
type_safety_review:
  section: type_safety
  findings:
    - severity: important
      confidence: verified
      file: path/to/file.ts
      line: 15
      pattern: any_explicit
      evidence: "Explicit 'any' type annotation at line 15"
      description: Using 'any' bypasses type checking
      fix: Define proper interface
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

**OUTPUT**: Linting findings using `skills/code-review/templates/output-pipeline.yaml`
```yaml
lint_review:
  section: linting
  findings:
    - severity: suggestion
      confidence: verified
      file: path/to/file.ts
      line: 100
      pattern: deep_nesting
      metrics:
        nesting_depth: 5
        function_length: 85
      evidence: "Function has cyclomatic complexity of 15"
      description: Function has high complexity
      fix: Split into smaller functions
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

**OUTPUT**: Standards findings using `skills/code-review/templates/output-pipeline.yaml`
```yaml
standards_review:
  section: standards
  findings:
    - severity: suggestion
      confidence: suspected
      file: path/to/file.ts
      line: 5
      pattern: cs1_single_responsibility
      principle: "CS1"
      evidence: "Function handles validation, persistence, and notification"
      description: Function has multiple responsibilities
      fix: Split into validateOrder, saveOrder, notifyOrder
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

**OUTPUT**: Consolidated review report (uses `skills/code-review/templates/output-direct.yaml` format)
```yaml
code_review:
  mode: comprehensive
  static_analysis:
    typecheck: passed
    lint: passed
  findings:
    critical:
      - {file: auth.ts, line: 42, section: security, pattern: sql_injection}
    important:
      - {file: user.ts, line: 15, section: type_safety, pattern: any_explicit}
      - {file: config.ts, line: 30, section: type_safety, pattern: null_gap}
    suggestions:
      - {file: processor.ts, line: 100, section: linting, pattern: deep_nesting}
      - {file: service.ts, line: 5, section: standards, pattern: cs1_single_responsibility}
  summary:
    critical_count: 1
    important_count: 2
    suggestion_count: 2
    recommendation: "Fix critical SQL injection before merge"
  gate:
    passed: false
    blocking_findings: 1
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
