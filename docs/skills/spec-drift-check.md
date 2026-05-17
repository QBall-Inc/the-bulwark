# spec-drift-check

Audits a work package brief, plan document, or memory entry for drift against current code state. Extracts every claim, verifies each one, and emits a `PROCEED` / `STOP` verdict before you consume the spec as binding.

## When to use

- **Stage 0 of any new WP implementation**, before reading the brief as binding instructions.
- **Before resuming an `in_progress` WP** that was paused across sessions — files may have moved, line numbers shifted, function names changed.
- **When a doc references paths, line numbers, or function names** that downstream actions depend on.
- **Whenever a memory entry, brief, or plan claim feels stale** and you want a single command to check it.

## Usage

```
/spec-drift-check <spec-path> [<additional-context>]
```

Example:

```
/spec-drift-check plans/task-briefs/P10.25-init-update-parent-child-duplicate.md
```

## What it does

The skill runs a 4-stage pipeline:

1. **Extract claims** — parses the brief and pulls out every verifiable statement (file paths, function names, line refs, behavior claims, integration assertions).
2. **Verify each claim** — runs file existence checks, grep-based content checks, AST/symbol lookups (via LSP when available), and behavioral probes.
3. **Classify drift** — marks each claim `CONFIRMED`, `LOW_DRIFT`, `MEDIUM_DRIFT`, or `HIGH_DRIFT`.
4. **Emit verdict**:
   - All `CONFIRMED` → **PROCEED** with the original brief.
   - Only `LOW` + `MEDIUM` drift → **PROCEED** with an adjusted plan (deltas documented in the verification log).
   - Any `HIGH` drift → **STOP**. Surface findings via `AskUserQuestion` for explicit sign-off before any implementation begins.

## What it produces

A verification log at `logs/spec-verify-{session}-{wp-id}.md` plus a diagnostic record at `logs/diagnostics/spec-drift-check-{timestamp}.yaml`. The verification log becomes the **canonical plan** for the rest of the WP — it supersedes the original brief on any point of difference.

## Why it matters

Specs decay. A WP brief authored two weeks ago may reference a function that was renamed last session, or a file that moved during a refactor. Without a drift check, you waste implementation effort on stale assumptions and discover the mismatch in the middle of writing code. `spec-drift-check` makes the cost of staleness explicit and contained — surface it before implementation, not during.

The `SD1` rule in `Rules.md` makes this check mandatory for any new or resumed WP. Skipping it is a rule violation.

## Sub-agents

None. The skill runs as a single-context pipeline that orchestrates `Bash`, `Read`, and `Grep` calls plus optional LSP lookups. Output is structured for downstream consumption by an implementation session.
