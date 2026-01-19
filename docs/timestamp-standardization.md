# Timestamp Format Standardization

**Created**: 2026-01-19 (Session 12)
**Status**: Completed (Session 13)
**Priority**: High (blocking P1.2/P1.3 implementation quality)

---

## Problem Statement

During dogfooding of the test-audit pipeline, the Haiku classification stage output wasn't being correctly found by the Sonnet detection stage due to timestamp naming ambiguity.

**Root cause**: Inconsistent timestamp placeholders across skills and pipeline references.

---

## Current State (Inconsistent)

| Placeholder | Used In | Example |
|-------------|---------|---------|
| `{YYYYMMDD-HHMMSS}` | subagent-output-templating, test-audit | `logs/{agent}-{YYYYMMDD-HHMMSS}.yaml` |
| `{timestamp}` | pipeline-templates references | `logs/test-classification-{timestamp}.yaml` |
| `{ts}` | code-change-workflow | `logs/test-classification-{ts}.yaml` |
| `{ISO-8601}` | YAML content fields | `timestamp: {ISO-8601}` |

**Impact**: When Stage 2 tries to find Stage 1's output using `{timestamp}` placeholder, it doesn't know the actual format used.

---

## Target State (Standardized)

### Two Formats for Two Purposes

| Context | Placeholder | Format | Example |
|---------|-------------|--------|---------|
| **File paths** | `{YYYYMMDD-HHMMSS}` | Compact, filesystem-safe | `20260119-143022` |
| **YAML fields** | `{ISO-8601}` | Standard ISO format | `2026-01-19T14:30:22Z` |

### Why Two Formats?

- **File names**: No colons (Windows-compatible), compact, lexically sortable
- **YAML fields**: Standard ISO-8601 for parsing, interoperability, human readability

### Remove Ambiguous Placeholders

- Remove `{timestamp}` - ambiguous
- Remove `{ts}` - ambiguous abbreviation
- Keep only `{YYYYMMDD-HHMMSS}` for file paths
- Keep only `{ISO-8601}` for YAML content

---

## Files to Update

### 1. skills/subagent-output-templating/SKILL.md

**Current** (line 358-359):
```markdown
[ ] Main log: logs/{agent}-{timestamp}.yaml
[ ] Diagnostics: logs/diagnostics/{agent}-{timestamp}.yaml
```

**Fix**:
```markdown
[ ] Main log: logs/{agent}-{YYYYMMDD-HHMMSS}.yaml
[ ] Diagnostics: logs/diagnostics/{agent}-{YYYYMMDD-HHMMSS}.yaml
```

**Add section** (after Log File Format):
```markdown
## Timestamp Formats

| Context | Placeholder | Format | Example |
|---------|-------------|--------|---------|
| **File paths** | `{YYYYMMDD-HHMMSS}` | Compact, filesystem-safe | `20260119-143022` |
| **YAML fields** | `{ISO-8601}` | Standard ISO format | `2026-01-19T14:30:22Z` |

**Why two formats?**
- File names: No colons (filesystem-safe on Windows), compact, lexically sortable
- YAML fields: Standard ISO-8601 for parsing and interoperability

**Important**: Always use `{YYYYMMDD-HHMMSS}` in file paths, never `{timestamp}` or `{ts}`.
```

### 2. skills/pipeline-templates/references/test-audit.md

**Lines to update**:

| Line | Current | Fix |
|------|---------|-----|
| 90 | `logs/test-classification-{timestamp}.yaml` | `logs/test-classification-{YYYYMMDD-HHMMSS}.yaml` |
| 94 | (OK - ISO-8601) | No change |
| 150 | `logs/mock-detection-{timestamp}.yaml` | `logs/mock-detection-{YYYYMMDD-HHMMSS}.yaml` |
| 155 | `classification_source: logs/test-classification-{timestamp}.yaml` | `classification_source: logs/test-classification-{YYYYMMDD-HHMMSS}.yaml` |
| 224 | `logs/test-audit-{timestamp}.yaml` | `logs/test-audit-{YYYYMMDD-HHMMSS}.yaml` |
| 230-231 | `{timestamp}` references | `{YYYYMMDD-HHMMSS}` |
| 323, 329, 335 | `{timestamp}` | `{YYYYMMDD-HHMMSS}` |

### 3. skills/pipeline-templates/references/code-change-workflow.md

**Lines to update**:

| Line | Current | Fix |
|------|---------|-----|
| 100-102 | `{ts}` | `{YYYYMMDD-HHMMSS}` |

### 4. skills/pipeline-templates/references/fix-validation.md

**Line 63**: Already uses `{issue-id}-{timestamp}` - update to `{issue-id}-{YYYYMMDD-HHMMSS}`

### 5. skills/test-audit/SKILL.md

**Lines to check** (may already be correct):
- Line 96: `YYYYMMDD-HHMMSS` (OK)
- Line 114, 139, 154: `{timestamp}` → `{YYYYMMDD-HHMMSS}`
- Line 264, 266: `{YYYYMMDD-HHMMSS}` (OK)
- Line 325-326: `{timestamp}` → `{YYYYMMDD-HHMMSS}`

### 6. skills/test-classification/SKILL.md

Check and update any `{timestamp}` references to `{YYYYMMDD-HHMMSS}`.

### 7. skills/mock-detection/SKILL.md

Check and update any `{timestamp}` references to `{YYYYMMDD-HHMMSS}`.

---

## Cross-Reference Pattern

When one stage references another stage's output, the pattern should be:

```yaml
# Stage 2 referencing Stage 1
metadata:
  sources:
    classification: logs/test-classification-{YYYYMMDD-HHMMSS}.yaml
```

**Implementation note**: The orchestrator generates the timestamp once and passes it to all stages in the CONTEXT so they use the same value.

---

## Sync to .claude/skills/

After updating `skills/`, sync to `.claude/skills/` for dogfooding:

```bash
# Sync updated skills
cp -r skills/subagent-output-templating .claude/skills/
cp -r skills/pipeline-templates .claude/skills/
cp -r skills/test-audit .claude/skills/
cp -r skills/test-classification .claude/skills/
cp -r skills/mock-detection .claude/skills/
```

---

## Verification

After fixes, test the test-audit pipeline:

1. Run `/test-audit tests/fixtures/`
2. Verify classification stage creates file with `{YYYYMMDD-HHMMSS}` format
3. Verify detection stage finds and reads classification output
4. Verify synthesis stage references both previous outputs correctly

---

## Estimated Effort

- **Skill updates**: 15-20 minutes
- **Sync to .claude/skills/**: 5 minutes
- **Verification**: 10 minutes

**Total**: ~30-35 minutes

---

## Recommendation

Fix this before implementing P1.2 (`bulwark-issue-analyzer`) so the new agent follows correct patterns from the start. The fix is mechanical (search-replace) and low risk.
