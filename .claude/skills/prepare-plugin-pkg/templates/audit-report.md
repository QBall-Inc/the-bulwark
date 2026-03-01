# Plugin Distribution Audit Report

**Plugin:** {plugin-name}
**Version:** {version}
**Audit Date:** {YYYY-MM-DD}
**Distribution Target:** {npm / self-hosted marketplace / official marketplace}

---

## Inventory Summary

| Category | Count | Files |
|----------|-------|-------|
| Distribution-ready skills | {n} | {list} |
| Distribution-ready agents | {n} | {list} |
| Internal-only (.claude/ only) | {n} | {list or "none"} |
| Duplicate (root + .claude/) | {n} | {list or "none"} |
| Potentially stale | {n} | {list or "none"} |
| Test-only (should not ship) | {n} | {list or "none"} |

---

## Plugin Structure

| Check | Status | Notes |
|-------|--------|-------|
| plugin.json present | PASS / FAIL | |
| name field valid (kebab-case) | PASS / FAIL | |
| version field valid (semver) | PASS / FAIL | |
| description field present | PASS / FAIL | |
| skills paths exist | PASS / FAIL | {any missing paths} |
| agents paths exist | PASS / FAIL | {any missing paths} |
| No .claude/ paths in plugin.json | PASS / FAIL | |

---

## Hooks Configuration

| Check | Status | Notes |
|-------|--------|-------|
| hooks.json present | PASS / SKIP | Skip if no hooks |
| All event types valid | PASS / FAIL | {any invalid events} |
| Timeout values in seconds (not ms) | PASS / FAIL | {any suspicious values} |
| All scripts exist | PASS / FAIL | {any missing scripts} |
| All scripts executable | PASS / FAIL | {any non-executable scripts} |
| $CLAUDE_PLUGIN_ROOT used for paths | PASS / FAIL | |

---

## Distribution Readiness

| Check | Status | Notes |
|-------|--------|-------|
| package.json version matches plugin.json | PASS / FAIL / N/A | |
| package.json `files` excludes .claude/, logs/, tmp/ | PASS / FAIL / N/A | |
| Version consistent across all manifests | PASS / FAIL | |
| First-run restart requirement documented | PASS / FAIL | |
| No internal directories in distribution bundle | PASS / FAIL | |

---

## Findings

### CRITICAL (must fix before release)

| ID | Location | Finding | Recommended Fix |
|----|----------|---------|-----------------|
| C-1 | {file:line} | {description} | {specific fix} |

### HIGH (should fix before release)

| ID | Location | Finding | Recommended Fix |
|----|----------|---------|-----------------|
| H-1 | {file:line} | {description} | {specific fix} |

### MEDIUM (address for quality)

| ID | Location | Finding | Recommended Fix |
|----|----------|---------|-----------------|
| M-1 | {file:line} | {description} | {specific fix} |

### LOW (nice to fix)

| ID | Location | Finding | Recommended Fix |
|----|----------|---------|-----------------|
| L-1 | {file:line} | {description} | {specific fix} |

---

## Summary

**Total findings:** {n} CRITICAL, {n} HIGH, {n} MEDIUM, {n} LOW

**Distribution readiness:** BLOCKED / READY WITH WARNINGS / READY

{One sentence summary of overall state and most important next action.}
