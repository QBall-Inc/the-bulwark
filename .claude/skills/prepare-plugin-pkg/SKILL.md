---
name: prepare-plugin-pkg
description: Use when preparing a Claude Code plugin for packaging and distribution. Audits inventory, validates plugin.json and hooks.json, reviews init scripts, and produces a distribution-readiness report.
user-invocable: true
---

# Prepare Plugin Package

Guides you through preparing a Claude Code plugin for packaging and distribution. Covers
inventory audit, structural validation, hooks configuration, init script review, and
distribution readiness. Produces a severity-rated findings report at the end.

---

## Mandatory Execution Checklist (BINDING)

**Every item below is mandatory. No deviations. No substitutions. No skipping.**

You MUST complete all items in order. Do NOT skip steps. Do NOT combine steps.
Do NOT declare complete until every checkbox below is verifiable.

If you find yourself thinking "I can skip the inventory audit" or "the hooks look fine" — STOP.
That thought pattern violates this checklist. Every step exists because real plugins shipped with
real bugs when these checks were skipped.

- [ ] Step 1: All 4 reference files loaded
- [ ] Step 2: Every skill and agent file classified (no files skipped)
- [ ] Step 3: plugin.json validated (or absence documented as CRITICAL)
- [ ] Step 4: hooks.json audited — timeout values checked (no millisecond values shipped as seconds)
- [ ] Step 5: Init script reviewed (or absence noted with reason)
- [ ] Step 6: Distribution checklist completed — version consistency, first-run restart documented
- [ ] Step 7: Audit report populated from template and written to `$CLAUDE_PROJECT_DIR/tmp/`
- [ ] Step 7: All CRITICAL findings have specific remediation steps
- [ ] Step 7: User offered the opportunity to address findings

---

## When to Use This Skill

**Load this skill when the user request matches ANY of these patterns:**

| Trigger Pattern | Example Request | Usage |
|-----------------|-----------------|-------|
| Preparing plugin for release | "I want to package my plugin for the marketplace" | Full 8-step workflow |
| Pre-release distribution check | "Is my plugin ready to distribute?" | Full 8-step workflow |
| Plugin structure validation | "Check my plugin.json and hooks config are correct" | Steps 1-4 focused |
| Post-development cleanup | "Help me clean up legacy files before shipping" | Step 2 focused |

**DO NOT use for:**
- Auditing a project that is not a Claude Code plugin (no plugin.json present)
- Reviewing individual skills or agents in isolation (use anthropic-validator instead)

---

## Step 1: Load References

Load ALL reference files before proceeding. These contain the authoritative definitions
for plugin format, hook configuration, and distribution requirements.

| Reference | Path | Purpose |
|-----------|------|---------|
| Plugin Format | `references/plugin-format.md` | Directory structure, plugin.json schema, root vs .claude/ conventions |
| Hooks Reference | `references/hooks-reference.md` | Hook event types, timeout units, $CLAUDE_PLUGIN_ROOT, matcher syntax |
| Distribution Checklist | `references/distribution-checklist.md` | npm/marketplace fields, version consistency, first-run restart requirement |
| Common Pitfalls | `references/common-pitfalls.md` | Timeout confusion, directory mistakes, legacy file shipping, CLAUDE.md redundancy |

**Confirm to the user:** "References loaded. Beginning inventory audit."

---

## Step 2: Inventory Audit

Scan the project for skills and agents in both root and `.claude/` directories.
Report what is found before drawing any conclusions.

### 2a: Scan Directories

Use Glob to enumerate:
- `skills/*/SKILL.md` (root skills)
- `agents/*.md` (root agents)
- `.claude/skills/*/SKILL.md` (.claude skills)
- `.claude/agents/*.md` (.claude agents)

If a directory does not exist, note it as absent — do not treat absence as an error.

### 2b: Classify Each Entry

For each skill and agent found, classify into one of these buckets:

| Bucket | Condition | Implication |
|--------|-----------|-------------|
| Distribution-ready | In root only OR in both root and .claude/ | Will ship in plugin |
| Internal-only | In .claude/ only (not in root) | Not distributed — may be intentional |
| Duplicate | Same name in both root and .claude/ | Verify they are identical; flag if diverged |
| Potentially stale | Name contains `_old`, `_bak`, `_draft`, `_v1`, `_proto`, `tmp` | Candidate for removal |
| Test-only agent | Name contains `test`, `fixture`, `mock`, `harness` | Should NOT ship in plugin |

### 2c: Report Inventory

Present a table of all discovered files with their bucket classification. Do not skip
files — completeness is required. Ask the user to confirm or correct the classification
before proceeding to Step 3.

---

## Step 3: Plugin Structure Validation

Validate the plugin's structural files against the plugin format reference.

### 3a: Locate plugin.json

Search for `plugin.json` at the project root. If not found, search one level down.
If absent entirely: record as CRITICAL finding and continue remaining steps.

### 3b: Validate Required Fields

Check each required field defined in `references/plugin-format.md`:

| Field | Check | Severity if Missing |
|-------|-------|---------------------|
| `name` | Present, non-empty, kebab-case | CRITICAL |
| `version` | Present, semver format (X.Y.Z) | CRITICAL |
| `description` | Present, non-empty, single line | HIGH |
| `author` | Present | MEDIUM |
| `skills` | Array, paths exist | HIGH |
| `agents` | Array, paths exist (if any agents) | HIGH |
| `hooks` | Present if hooks.json exists | MEDIUM |

### 3c: Validate Path References

For each path listed in `skills` and `agents` arrays:
- Confirm the file exists at the stated path
- Flag any path that references `.claude/` (plugin distributes from root)

### 3d: Version Format

Confirm version follows semver (X.Y.Z). Flag pre-release suffixes (e.g., `-alpha`, `-rc1`)
if the stated goal is marketplace submission.

---

## Step 4: Hooks Configuration Audit

Validate hooks.json against the hooks reference. This is the most error-prone area —
read `references/hooks-reference.md` carefully before executing.

### 4a: Locate hooks.json

Search for `hooks.json` at project root. If absent, note and skip to Step 5.

### 4b: Validate Hook Event Types

For each hook entry, confirm the `event` field is one of the valid event types listed
in `references/hooks-reference.md`. Flag any unrecognized event type as HIGH severity.

### 4c: Audit Timeout Values

**This is the most common critical mistake.** Timeout values are in SECONDS, not milliseconds.

For each hook with a `timeout` field:
- If value >= 1000: flag as CRITICAL ("Likely in milliseconds — 60000 = 16.7 hours")
- If value > 120: flag as HIGH ("Unusually long timeout, verify intent")
- If value < 1: flag as HIGH ("Sub-second timeout will cause immediate failures")
- Acceptable range: 5-120 seconds

### 4d: Validate Script Paths

For each hook's `script` or `command` field:
- Confirm the referenced file exists
- Confirm the file is executable (`-x` permission)
- Flag non-executable scripts as HIGH severity

### 4e: Validate $CLAUDE_PLUGIN_ROOT Usage

For hooks that reference paths, confirm they use `$CLAUDE_PLUGIN_ROOT` rather than
hardcoded absolute paths or relative paths. Hardcoded paths break on other machines.

### 4f: Validate PostToolUse Matchers

For PostToolUse hooks, validate matcher syntax per `references/hooks-reference.md`.
Flag any matcher using deprecated or unrecognized patterns.

---

## Step 5: Init Script Review

If the plugin includes an init script (commonly `init.sh`, `install.sh`, or referenced
in plugin.json as an `onInstall` hook):

### 5a: Target Path Conventions

Confirm injected files target `.claude/rules/` (not project root or `.claude/` directly).
Files placed in `.claude/rules/` are auto-loaded by Claude Code without configuration.

Flag as MEDIUM if:
- Init script injects to project root (user must reference it manually)
- Init script injects CLAUDE.md content that duplicates auto-loaded rules

### 5b: Thin Orchestrator Pattern

Init scripts should perform filesystem operations only. They must NOT:
- Invoke `claude` CLI to run skills programmatically
- Make network requests during init
- Run AI-guided configuration inline

Flag as HIGH if init script invokes `claude` or makes HTTP requests.

### 5c: Post-Init Checklist

Confirm the init script (or plugin documentation) prints a post-install checklist
that delegates AI-guided configuration to skills (not programmatic invocation).

### 5d: Absence

If no init script is found, note "No init script detected — Step 5 skipped." and
proceed to Step 6.

---

## Step 6: Distribution Readiness Check

Work through `references/distribution-checklist.md` item by item.

### 6a: npm package.json (if npm distribution)

| Field | Requirement | Severity if Missing |
|-------|-------------|---------------------|
| `name` | Matches plugin.json name | CRITICAL |
| `version` | Matches plugin.json version | CRITICAL |
| `description` | Present | MEDIUM |
| `files` | Lists only distribution directories | HIGH |
| `keywords` | Includes "claude-code", "claude-plugin" | LOW |
| `main` | Not required for plugins (flag if present pointing to non-existent file) | MEDIUM |

### 6b: Marketplace.json (if self-hosted marketplace)

Validate fields per `references/distribution-checklist.md`. Flag missing required fields.

### 6c: Version Consistency

Confirm `version` in plugin.json, package.json (if present), and any CHANGELOG header
are all consistent. Any mismatch is CRITICAL.

### 6d: First-Run Restart Requirement

Claude Code hooks do not activate until the user restarts Claude Code after installation.
Confirm this is documented in:
- README or install instructions
- Post-install output of init script (if present)

Flag as HIGH if neither location documents the restart requirement.

### 6e: Files to Exclude from Distribution

Flag presence of any of these in the distribution bundle:
- `logs/` directory: MEDIUM (internal only)
- `tmp/` directory: MEDIUM (internal only)
- `.claude/` directory contents: HIGH (init script may copy selectively, but .claude/ itself should not ship)
- Test fixtures or harness agents (classified in Step 2): HIGH

---

## Step 7: Present Audit Report

Load `templates/audit-report.md` and populate it with all findings from Steps 2-6.

Severity levels:
- **CRITICAL**: Blocks distribution. Must fix before release.
- **HIGH**: Should fix before release. Risk of user-facing failure.
- **MEDIUM**: Should address. Quality and discoverability impact.
- **LOW**: Nice to fix. Cosmetic or future-proofing.

Present the completed report to the user. For each CRITICAL and HIGH finding, provide
a specific, actionable recommendation. Do not just list the problem — state the fix.

After presenting, ask: "Would you like to work through any of these findings now?"

Write the completed audit report to: `$CLAUDE_PROJECT_DIR/tmp/audit-report-{YYYYMMDD}.md`

---

## Reference Index

| File | Lines | Contents |
|------|-------|----------|
| `references/plugin-format.md` | ~140 | Directory structure, plugin.json schema, root vs .claude/ conventions |
| `references/hooks-reference.md` | ~150 | Hook event types, timeout units, script paths, matcher syntax |
| `references/distribution-checklist.md` | ~160 | npm/marketplace fields, version consistency, first-run restart |
| `references/common-pitfalls.md` | ~155 | Timeout confusion, directory mistakes, legacy files, CLAUDE.md redundancy |
| `templates/audit-report.md` | ~96 | Audit report template with severity-rated findings sections |
