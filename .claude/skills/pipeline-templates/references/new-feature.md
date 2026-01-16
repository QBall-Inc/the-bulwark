# New Feature Pipeline

## Purpose

Implement new functionality with proper research, implementation, testing, and review.

## When to Use

- Adding new features
- Implementing new modules
- Creating new components
- Building new integrations

## Pipeline Definition

```fsharp
// New Feature Pipeline
// Trigger: Feature request, new capability needed
// Output: Implemented feature with tests and review

Researcher (gather requirements & patterns)      // Haiku - lookups
|> Architect (design approach)                   // Sonnet - analysis
|> Implementer (write code)                      // Opus - write code
|> TestWriter (write tests)                      // Opus - write tests
|> CodeReviewer (review implementation)          // Sonnet - review
|> (if !approved
    then Implementer                             // Loop back
    else Done)
|> LOOP(max=2)                                   // Max 2 revision rounds
```

## Stage Details

### Stage 1: Researcher

**Model**: Haiku (lookup task)

**GOAL**: Gather information needed for implementation.

**CONSTRAINTS**:
- Do NOT modify any files
- Focus on relevant patterns only
- Document sources

**CONTEXT**:
- Feature requirements
- Project structure
- Related existing code

**OUTPUT**: Research findings
```yaml
research:
  requirements:
    - "User can export data to CSV"
    - "Export includes all visible columns"
    - "Large exports should stream"
  existing_patterns:
    - file: src/utils/export.ts
      pattern: "Existing PDF export can be extended"
    - file: src/components/DataTable.tsx
      pattern: "Column visibility tracked in state"
  dependencies:
    - "csv-stringify for CSV generation"
    - "Existing streaming infrastructure"
  considerations:
    - "Memory usage for large datasets"
    - "Progress indication for user"
```

### Stage 2: Architect

**Model**: Sonnet (design/analysis task)

**GOAL**: Design implementation approach.

**CONSTRAINTS**:
- Do NOT modify any files
- Consider existing patterns
- Identify risks and trade-offs

**CONTEXT**:
- Research findings from Stage 1
- Project architecture
- Performance requirements

**OUTPUT**: Design document
```yaml
design:
  approach: "Extend existing export utility with CSV support"
  components:
    - name: CSVExporter
      location: src/utils/csv-export.ts
      responsibility: "Convert data to CSV format"
    - name: ExportButton
      location: src/components/ExportButton.tsx
      responsibility: "UI for triggering export"
  data_flow:
    - "User clicks export button"
    - "DataTable provides visible columns and data"
    - "CSVExporter streams data to download"
  trade_offs:
    - pro: "Reuses existing export infrastructure"
    - con: "Adds dependency on csv-stringify"
  risks:
    - "Memory pressure on large exports"
    - mitigation: "Use streaming with chunk size limit"
```

### Stage 3: Implementer

**Model**: Opus (code writing required)

**GOAL**: Implement the feature per design.

**CONSTRAINTS**:
- Follow the design from Stage 2
- Use existing patterns
- Do NOT over-engineer
- Keep changes minimal

**CONTEXT**:
- Design document from Stage 2
- Project coding standards
- Related existing code

**OUTPUT**: Implementation
```yaml
implementation:
  files_created:
    - path: src/utils/csv-export.ts
      purpose: "CSV export utility"
      lines: 45
  files_modified:
    - path: src/components/DataTable.tsx
      changes: "Added export button integration"
  dependencies_added:
    - name: csv-stringify
      version: "^6.0.0"
      reason: "CSV generation"
```

### Stage 4: TestWriter

**Model**: Opus (test writing required)

**GOAL**: Write tests for the new feature.

**CONSTRAINTS**:
- Tests verify real behavior (T1)
- No mocking system under test (T2)
- Cover happy path and edge cases
- Integration tests for component interaction

**CONTEXT**:
- Implementation from Stage 3
- Project test patterns
- Feature requirements

**OUTPUT**: Tests
```yaml
tests:
  unit_tests:
    - file: tests/utils/csv-export.test.ts
      cases:
        - "exports simple data correctly"
        - "handles special characters"
        - "streams large datasets"
  integration_tests:
    - file: tests/components/DataTable.export.test.ts
      cases:
        - "export button triggers download"
        - "respects column visibility"
```

### Stage 5: CodeReviewer

**Model**: Sonnet (review task)

**GOAL**: Review implementation quality and completeness.

**CONSTRAINTS**:
- Do NOT modify any files
- Check against requirements
- Verify tests are adequate
- Check for security issues

**CONTEXT**:
- Original requirements
- Design document
- Implementation
- Tests

**OUTPUT**: Review decision
```yaml
review:
  approved: true | false
  checklist:
    requirements_met: true
    tests_adequate: true
    security_checked: true
    performance_acceptable: true
  concerns: []
  recommendations:
    - "Consider adding rate limiting for exports"
```

### Loop Condition

If `approved: false`, loop back to Implementer with:
- Review feedback
- Specific concerns to address

**Max iterations**: 2 (prevent scope creep)

## Example Invocation

```markdown
## Pipeline: New Feature

### Stage 1: Researcher
Task: subagent_type=general-purpose, model=haiku
Prompt: [4-part prompt with feature requirements]

### Stage 2: Architect
Task: subagent_type=general-purpose, model=sonnet
Prompt: [4-part prompt, reads research]

### Stage 3: Implementer
Task: subagent_type=general-purpose, model=opus
Prompt: [4-part prompt, follows design]

### Stage 4: TestWriter
Task: subagent_type=general-purpose, model=opus
Prompt: [4-part prompt, tests implementation]

### Stage 5: CodeReviewer
Task: subagent_type=general-purpose, model=sonnet
Prompt: [4-part prompt, reviews all]

### Loop Check
If not approved and iterations < 2:
  Go to Stage 3 with feedback
```

## Success Criteria

- Requirements researched and understood
- Design documented before implementation
- Implementation follows design
- Tests verify real behavior
- Review approves or revisions complete

## Related Pipelines

- **Research & Planning**: For more extensive research phase
- **Code Review**: For reviewing without implementation
- **Fix Validation**: For fixing issues found in review
