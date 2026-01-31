# Bulwark Defect List

Defects identified during manual testing and development.

---

## Open Defects

(None)

---

## Closed Defects

### DEF-001: bulwark-scaffold missing SessionStart hook

**Identified:** Session 27 (2026-01-27)
**Phase:** P3.1-3 Manual Testing
**Severity:** Medium
**Status:** Closed (Session 28)
**Fixed:** Updated `skills/bulwark-scaffold/SKILL.md` to include SessionStart hook configuration and copy required files (inject-protocol.sh, governance-protocol skill).

---

### DEF-003: enforce-quality.sh should handle missing Justfile recipes gracefully

**Identified:** Session 27 (2026-01-27)
**Phase:** P3.2 Manual Testing
**Severity:** Medium
**Status:** Closed (Session 28)
**Fixed:** Added `recipe_exists()` function to check if recipe exists before calling. Scripts now skip missing recipes instead of failing.

---

### DEF-004: suggest-pipeline.sh doesn't distinguish new code from edits

**Identified:** Session 27 (2026-01-27)
**Phase:** P3.2 Manual Testing
**Severity:** High
**Status:** Closed (Session 28)
**Fixed:** Updated pipeline selection logic to consider `$TOOL_NAME`:
- `Write` on code file → New Feature Pipeline
- `Edit` on code file → Code Review Pipeline
- `Write` on script → New Feature (security focus)
- `Edit` on script → Code Review (security focus)

---

### DEF-005: Hook triggers on log file writes causing potential infinite loop

**Identified:** Session 27 (2026-01-27)
**Phase:** P3.2 Manual Testing
**Severity:** High
**Status:** Closed (Session 28)
**Fixed:** Added path exclusions at start of both `enforce-quality.sh` and `suggest-pipeline.sh`:
```bash
case "$FILE_PATH" in
  */logs/*|logs/*|*/tmp/*|tmp/*|*/.claude/*|.claude/*|*/node_modules/*|node_modules/*)
    exit 0
    ;;
esac
```

---

## Completed Cleanup Activities

### CLEANUP-001: Remove scaffold artifacts from test fixtures

**Status:** Complete (Session 28)
**Directories cleaned:** express-api, flask-service, actix-server, shellscript-utils
**Removed:** .claude/, logs/, Justfile, Justfile.backup-*, .gitignore (scaffold-created)

---

### CLEANUP-002: Remove P3.2 test files from Bulwark project

**Status:** Complete (Session 28)
**Removed:** scripts/test-utils/, docs/test-architecture-overview.md
