---
name: pipeline-templates
description: Pre-defined F# pipe workflows for multi-agent orchestration. Provides code review, fix validation, test audit, new feature, research & planning, and test execution pipelines. Triggered via PostToolUse hook after significant code changes.
when_to_use: Loaded by the Stop hook (`suggest-pipeline-stop.sh`) when uncovered code/test/script changes accumulate this turn — provides the canonical F# pipe definitions the orchestrator follows when responding to the hook's `decision: block` reason text. Also loadable directly when the orchestrator needs to consult a pipeline definition (e.g., before running Code Review, Test Audit, Fix Validation, New Feature, or Research & Planning workflows).
user-invocable: false
version: 1.0.2
author: "Ashay Kubal @ Qball Inc."
---

# Pipeline Templates

## Overview

This skill provides pre-defined F# pipe workflows for common multi-agent scenarios. Pipelines ensure:

- **Deterministic orchestration**: Consistent agent sequencing
- **Hard validation**: Block incorrect pipeline usage
- **Progress tracking**: Log all pipeline stages
- **Model optimization**: Right model for each stage

**When to use**: Multi-agent work requiring more than simple exploration.

**When NOT to use**: Single-agent tasks (explore, search, lookup) bypass pipeline validation automatically.

## Pipeline Selection Guide

Choose the appropriate pipeline based on your task:

```
Is this a multi-agent task?
├─ No → No pipeline needed (single-agent bypass)
└─ Yes → What type of work?
    ├─ Reviewing existing code → Code Review Pipeline
    ├─ Fixing a bug/issue → Fix Validation Pipeline
    ├─ Auditing test quality → Test Audit Pipeline
    ├─ Implementing new functionality → New Feature Pipeline
    ├─ Research before implementation → Research & Planning Pipeline
    └─ Running tests and fixing failures → Test Execution & Fix Pipeline
```

## Available Pipelines

| Pipeline | Use Case | Model Pattern | Reference |
|----------|----------|---------------|-----------|
| Code Review | PR review, code audit | Sonnet (role-based, 4 sections) | `references/code-review.md` |
| Fix Validation | Bug fixes, issue resolution | Sonnet (analyze) → Opus (fix) → Sonnet (validate) → Sonnet (review) | `references/fix-validation.md` |
| Test Audit | Test quality assessment | Haiku (classify) → Sonnet (detect) → Sonnet (audit) | `references/test-audit.md` |
| New Feature | Feature implementation | Haiku (research) → Opus (write) → Sonnet (review) | `references/new-feature.md` |
| Research & Planning | Pre-implementation research | Haiku (lookup) → Sonnet (review) → loop(min=3) | `references/research-planning.md` |
| Test Execution & Fix | Run tests, fix failures | Haiku (execute) → Sonnet (analyze) → Opus (fix) | `references/test-execution-fix.md` |
| **Code Change Workflow** | **Full automation after code edit** | **Composite: chains multiple pipelines** | `references/code-change-workflow.md` |

### Pipeline Architecture Notes

**Role-Based Agents**: Code Review pipeline uses general-purpose sub-agents with specific roles. Each agent loads the `code-review` skill and references a specific section (Security, Type Safety, Linting, Coding Standards).

**Custom Sub-Agents**: Fix Validation pipeline uses custom sub-agents (`bulwark-issue-analyzer`, `bulwark-fix-validator`) that encapsulate stage behavior and load relevant skills via frontmatter.

**Code-Writing Agent**: Fix Validation and New Feature pipelines use `bulwark-implementer` (custom sub-agent, Opus) for code-writing stages with built-in quality enforcement.

## Model Selection

Reference `subagent-prompting` skill for the task-type rubric:

| Task Type | Model | Examples |
|-----------|-------|----------|
| **Lookups & Execute** | Haiku | Web fetch, run tests, file search, lint |
| **Review & Analyze** | Sonnet | Code review, failure analysis, audits |
| **Write & Fix** | Opus | Write code, write tests, apply fixes |

**Override rule**: If a custom agent specifies `model:` in frontmatter, use that model instead.

## Validation Rules

### Valid Pipeline Invocation

A pipeline invocation is valid when:

1. Uses a defined pipeline template from this skill
2. Specifies model for each stage (or uses default from task-type rubric)
3. Includes 4-part prompt for each Task (GOAL/CONSTRAINTS/CONTEXT/OUTPUT)
4. Reads previous stage output before invoking next stage

### Invalid Invocation (Warning/Block)

The following patterns trigger validation warnings:

| Pattern | Issue | Resolution |
|---------|-------|------------|
| Ad-hoc multi-agent with no pipeline | Unpredictable orchestration | Choose appropriate pipeline |
| Missing model specification | May use wrong model | Specify model or use rubric |
| Skipping stages without justification | Incomplete workflow | Document skip reason |
| Using Opus for simple tasks | Wasteful | Use Haiku for lookups |

### Hook Behavior (PostToolUse)

The PostToolUse hook on Write|Edit:
- **Skips silently**: Small changes below threshold
- **Suggests pipeline**: Significant changes inject `additionalContext` with pipeline recommendation
- **Blocks**: Never (suggestion only, not blocking)

## File Type to Pipeline Mapping

When triggered by the Stop hook after Write/Edit/MultiEdit, select pipeline based on file modified. The hook (`suggest-pipeline-stop.sh`) emits ALL applicable pipelines for the turn — Code Review and Test Audit can both fire when a turn touches both production code and test files.

### Test detection (path-based, takes priority)

Files under any of these directory components are classified as **test** regardless of filename:

| Directory pattern | Stack | Examples |
|-------------------|-------|----------|
| `tests/`, `*/tests/` | Bulwark, generic | `tests/hooks/test-foo.sh` |
| `test/`, `*/test/` | Ruby Minitest, Elixir, generic | `test/foo_test.rb`, `test/foo_test.exs` |
| `__tests__/` | Jest convention | `__tests__/Component.test.tsx` |
| `spec/`, `specs/` | Ruby RSpec, generic | `spec/models/user_spec.rb` |
| `src/test/` | JVM (Maven/Gradle) | `src/test/java/FooTest.java` |

### Test detection (filename-based)

| Filename pattern | Stack | Examples |
|------------------|-------|----------|
| `test_*`, `test-*` | Python (pytest), Bulwark hooks | `test_models.py`, `test-foo.sh` |
| `*_test.*`, `*-test.*` | Go, Ruby Minitest, generic | `models_test.go`, `foo-test.sh` |
| `*_spec.*`, `*-spec.*` | Ruby RSpec, generic | `user_spec.rb` |
| `*.test.*`, `*.spec.*` | Jest, Vitest, Jasmine | `Component.test.tsx`, `service.spec.js` |

### Test detection (PascalCase, JVM/.NET)

Case-sensitive match on basename suffix:

| Filename pattern | Stack | Examples |
|------------------|-------|----------|
| `*Test.{java,kt,scala}` | JUnit, Kotest, ScalaTest | `UserServiceTest.java` |
| `*Tests.{cs,vb}` | xUnit, NUnit (C#/.NET) | `UserServiceTests.cs` |
| `*Spec.{kt,scala}` | Kotest, Specs2 | `UserServiceSpec.kt` |
| `*Specs.cs` | NSpec | `UserSpecs.cs` |
| `*IT.java` | JUnit integration tests | `UserServiceIT.java` |

### Code, script, config detection

| File Pattern | Extension | Recommended Pipeline |
|--------------|-----------|---------------------|
| Production code | `.ts`, `.tsx`, `.js`, `.jsx`, `.mjs`, `.cjs`, `.py`, `.go`, `.rs`, `.java`, `.kt`, `.scala`, `.cs`, `.fs`, `.vb`, `.rb`, `.exs`, `.ex`, `.cpp`, `.c`, `.php`, `.swift` | Code Review |
| Scripts | `.sh`, `.bash`, `.zsh`, `.fish`, `.ps1` | Code Review (security focus) |
| Config | `.json`, `.yaml`, `.yml`, `.toml`, `.ini`, `.env` | Code Review (security focus) |
| Documentation | `.md`, `.txt`, `.rst` | Light review or skip |
| Data files | `.xlsx`, `.csv`, `.pdf` | Manual review suggested |

### Out of scope (path-only detection limits)

Path-based classification cannot detect tests embedded in production source files:

- **Rust inline `#[test]`** — annotation-only signal, no path convention. `src/foo.rs` always classifies as code; if it contains inline tests, they'll be reviewed under Code Review, not Test Audit.
- **Python doctests** — same rationale; `foo.py` with doctests classifies as code.
- **Inline test directives in any language** — content-only signal, undetectable from path.

If a project relies heavily on inline tests, a future version may add content-based detection. For now, conventional `tests/` or `test_*` placement triggers Test Audit; inline tests don't.

### Small Change Bypass

Skip pipeline for small changes (threshold by file type):

| File Type | Threshold | Rationale |
|-----------|-----------|-----------|
| Code | < 5 lines | Minor fixes don't need full review |
| Tests | < 10 lines | Single test additions are low risk |
| Config | < 3 lines | Single value changes are quick to verify |
| Documentation | <= 10 lines | Typo fixes and small updates |
| Scripts | < 3 lines | Security-sensitive, low threshold |
| Data | Any change | Always significant, suggest review |

Changes at or below threshold are skipped silently. Changes above threshold trigger pipeline suggestion.

## Pipeline Execution Pattern

All pipelines follow this execution pattern:

```fsharp
// F# pipe syntax for workflow orchestration

// Sequential execution (each stage reads previous stage's output)
Stage1 (task)     // First agent runs
|> Stage2 (task)  // Reads Stage1 output, runs
|> Stage3 (task)  // Reads Stage2 output, runs
|> (if condition  // Conditional branching
    then StageA
    else StageB)
|> LOOP(max=N)    // Optional iteration

// Parallel execution (agents run concurrently, results merged)
[Stage1a, Stage1b, Stage1c]  // Array notation = parallel
|> Stage2 (reads all Stage1 outputs)
```

**Key principles**:
- **Sequential** (`|>`): Each stage reads the previous stage's log output
- **Parallel** (`[]`): Stages in array notation run concurrently via multiple Task calls in a single message
- Conditional branches based on stage results
- Loops have explicit iteration limits
- All output logged to `logs/`

## Progress Tracking

Pipeline progress is tracked via hooks:

| Event | Hook | Log Entry |
|-------|------|-----------|
| Stage start | SubagentStart | `[timestamp] SubagentStart: agent_id (type)` |
| Stage end | SubagentStop | `[timestamp] SubagentStop: agent_id` |

Logs written to: `logs/pipeline-tracking.log`

## Related Skills

| Skill | Relationship |
|-------|--------------|
| `subagent-prompting` | 4-part template, model selection rubric |
| `subagent-output-templating` | Output format for pipeline stages |

## Quick Reference

```fsharp
// Code Review (role-based agents, parallel execution)
[SecurityReviewer (section: Security),          // Sonnet - role-based
 TypeSafetyReviewer (section: Type Safety),     // Sonnet - role-based
 LintReviewer (section: Linting),               // Sonnet - role-based
 StandardsReviewer (section: Coding Standards)] // Sonnet - role-based
|> ReviewSynthesizer (consolidates all findings)
|> (if critical_issues then FixWriter else Done)

// Fix Validation (custom sub-agents)
IssueAnalyzer (bulwark-issue-analyzer, produces debug_report)
|> FixWriter (bulwark-implementer, implements fix)
|> (if !tests_cover_scenario                              // Only if tests don't exist
    then TestWriter |> TestAudit (mock-detection only)    // Audit generated tests for T1-T4
    else TestAudit (if FixWriter wrote tests))            // Audit implementer tests for T1-T4
|> FixValidator (bulwark-fix-validator, validates against debug_report)
|> CodeReviewer (reviews all, approves/rejects)
|> (if !approved then IssueAnalyzer else Done)
|> LOOP(max=3)

// Test Audit (Main Context Orchestration - skill-based)
TestClassifier |> MockDetector |> AuditSynthesizer
|> (if REWRITE_REQUIRED then TestRewriter else Done)
|> LOOP(max=2)

// New Feature
Researcher |> Architect |> Implementer (bulwark-implementer) |> TestWriter |> TestAudit |> CodeReviewer

// Research & Planning (min 3 iterations)
Researcher |> PlanDraft |> PlanReviewer |> LOOP(min=3)

// Test Execution & Fix (orchestrator fixes, PostToolUse hook enforces quality)
TestRunner |> (if failures then FailureAnalyzer |> FixWriter (orchestrator) |> LOOP else Done)

// CODE CHANGE WORKFLOW (Composite - chains pipelines after code edit)
// See references/code-change-workflow.md for full details
CodeReviewPipeline
|> TestAuditPipeline (Main Context Orchestration)
|> TestExecutionPipeline
|> (if code_bugs then FixValidationPipeline else Done)
```
