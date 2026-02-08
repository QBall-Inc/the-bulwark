---
name: pipeline-templates
description: Pre-defined F# pipe workflows for multi-agent orchestration. Provides code review, fix validation, test audit, new feature, research & planning, and test execution pipelines. Triggered via PostToolUse hook after significant code changes.
user-invocable: false
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

When triggered by PostToolUse hook after Write/Edit, select pipeline based on file modified:

| File Pattern | Extension | Recommended Pipeline |
|--------------|-----------|---------------------|
| Code files | `.ts`, `.js`, `.py`, `.go`, `.rs`, `.java` | Code Review |
| Test files | `*.test.ts`, `*.spec.js`, `test_*.py` | Test Audit |
| Config files | `.json`, `.yaml`, `.toml`, `.env` | Code Review (security focus) |
| Script files | `.sh`, `.bash`, `.ps1` | Code Review (security focus) |
| Documentation | `.md`, `.txt`, `.rst` | Light review or skip |
| Data files | `.xlsx`, `.csv`, `.pdf` | Manual review suggested |

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
    else Skip)
|> FixValidator (bulwark-fix-validator, validates against debug_report)
|> CodeReviewer (reviews all, approves/rejects)
|> (if !approved then IssueAnalyzer else Done)
|> LOOP(max=3)

// Test Audit (Main Context Orchestration - skill-based)
TestClassifier |> MockDetector |> AuditSynthesizer
|> (if REWRITE_REQUIRED then TestRewriter else Done)
|> LOOP(max=2)

// New Feature
Researcher |> Architect |> Implementer (bulwark-implementer) |> TestWriter |> CodeReviewer

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
