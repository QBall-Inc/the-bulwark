#!/bin/bash
# suggest-pipeline-stop.sh - Stop-hook handler for consolidated pipeline suggestions
#
# Fires at the end of every Claude turn. Reads the changed-files accumulator
# written by enforce-quality.sh and emits exactly one `decision: block`
# pipeline suggestion per turn, citing only files NOT yet covered by a
# qualifying pipeline log.
#
# P10.15 — Per-file registry + per-file coverage signal (Option C)
# Hardened in S115 against findings from the code-review pipeline self-test:
#   SEC-001/002/006 (path safety + symlink reject)
#   TS-01..06       (parse + arithmetic guards)
#   S-003/S-004     (graceful Python degrade + named SLACK_SECONDS)
#   L-003/L-004     (WATCHED dedup + emitted counts)
#   SEC-003/004/007 (read cap, atomic registry write, env var validation)
#
# State machine per file (registry: tmp/bulwark-review-registry.json):
#
#   ABSENT  --(seen in accumulator)--> PENDING(first_edit_at=accumulator.time)
#                                       fire block
#   PENDING --(pipeline log written for file's bucket containing the file
#              in reviewed_files, mtime in [first_edit_at - SLACK, NOW])-->
#                                       suppress + DELETE entry
#   PENDING --(re-edit on subsequent turn, no covering pipeline log)-->
#                                       keep PENDING (preserve first_edit_at),
#                                       fire block again
#   any     --(SessionStart)-->         registry cleared by cleanup hook
#
# Coverage check is per-file: pipeline-emitting skills/agents declare a
# top-level `reviewed_files: [...]` field in their primary log output. The
# hook parses each candidate log file and suppresses ONLY files explicitly
# listed. Logs without the field do NOT count as coverage (strict mode —
# under-suppression is noisy nuisance the user can ignore; over-suppression
# silently disables governance). See P10.15 brief for full rationale.
#
# Watched paths per bucket (code | test | script) and diagnostic prefix
# routing are defined inline in the Python block below.
#
# Input (stdin): Stop hook JSON per Anthropic spec.
# Output (stdout):
#   - {"decision": "block", "reason": ...} when uncovered files remain.
#   - {} otherwise (silent pass — including any internal error path; the
#     hook MUST NOT abort the user's turn on its own malfunction per CS3).

set -uo pipefail

# Resolve script directory so we can locate lib/coverage_check.py regardless
# of caller's $PWD (hooks invoke with arbitrary CWD).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COVERAGE_PY="${SCRIPT_DIR}/lib/coverage_check.py"

INPUT=$(cat)

# --- CLAUDE_PROJECT_DIR validation (SEC-007) ---
# The env var feeds every path resolution downstream. Reject anything other
# than an absolute, existing directory; on failure, exit silently rather
# than potentially writing into / or another sensitive location.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
case "$PROJECT_DIR" in
  /*) ;;  # absolute — OK
  *)
    echo '{}'
    exit 0
    ;;
esac
if [ ! -d "$PROJECT_DIR" ]; then
  echo '{}'
  exit 0
fi

LOGS_DIR="${PROJECT_DIR}/logs"
TMP_DIR="${PROJECT_DIR}/tmp"
ACCUMULATOR="${TMP_DIR}/bulwark-changed-files.json"
REGISTRY="${TMP_DIR}/bulwark-review-registry.json"
SLACK_SECONDS=5

mkdir -p "$LOGS_DIR" "$TMP_DIR"
HOOKS_LOG="${LOGS_DIR}/hooks.log"
TIMESTAMP=$(date -Iseconds)

# --- Recursion guard ---
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null || echo "false")
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  echo "[${TIMESTAMP}] Stop: recursion guard active, exiting silently" >> "$HOOKS_LOG"
  echo '{}'
  exit 0
fi

# --- Accumulator absent or empty → silent pass ---
if [ ! -f "$ACCUMULATOR" ]; then
  echo '{}'
  exit 0
fi

# Validate JSON; corrupt → drop and exit silently
if ! jq -e '.' "$ACCUMULATOR" >/dev/null 2>&1; then
  echo "[${TIMESTAMP}] Stop: corrupt accumulator, resetting" >> "$HOOKS_LOG"
  rm -f "$ACCUMULATOR"
  echo '{}'
  exit 0
fi

FILE_COUNT=$(jq -r '.files | length' "$ACCUMULATOR" 2>/dev/null || echo "0")
[ -z "$FILE_COUNT" ] && FILE_COUNT="0"
if [ "$FILE_COUNT" = "0" ]; then
  echo '{}'
  exit 0
fi

# --- Registry: initialize if missing or corrupt ---
REGISTRY_INIT='{"version": "1.0", "files": {}}'
if [ ! -f "$REGISTRY" ]; then
  echo "$REGISTRY_INIT" > "$REGISTRY"
elif ! jq -e '.' "$REGISTRY" >/dev/null 2>&1; then
  echo "[${TIMESTAMP}] Stop: corrupt registry, resetting" >> "$HOOKS_LOG"
  echo "$REGISTRY_INIT" > "$REGISTRY"
fi

# --- Per-file registry + coverage logic (delegated to lib/coverage_check.py) ---
# Inputs via argv: ACCUMULATOR REGISTRY LOGS_DIR PROJECT_DIR SLACK_SECONDS
# Output via stdout (JSON):
#   {"fire_list": [...], "counts": {"code": N, "test": N, "script": N}}
# Side effect: writes updated registry back to REGISTRY path (atomic rename).
# Module: scripts/hooks/lib/coverage_check.py (extracted in S117 L-001/L-002).
PYTHON_STDERR="${TMP_DIR}/.stop-hook-python-stderr.log"
if [ ! -f "$COVERAGE_PY" ]; then
  echo "[${TIMESTAMP}] Stop: coverage_check.py missing at ${COVERAGE_PY}; silent pass" >> "$HOOKS_LOG"
  echo '{}'
  exit 0
fi
RESULT=$(python3 "$COVERAGE_PY" "$ACCUMULATOR" "$REGISTRY" "$LOGS_DIR" "$PROJECT_DIR" "$SLACK_SECONDS" 2>"$PYTHON_STDERR")
PY_EXIT=$?

# S-003 — Python crash → graceful degrade. Exit silently rather than aborting
# the user's turn. The python stderr is preserved at $PYTHON_STDERR for
# post-mortem; the hooks log records the failure.
if [ "$PY_EXIT" -ne 0 ] || [ -z "$RESULT" ]; then
  PY_STDERR_TAIL=""
  if [ -f "$PYTHON_STDERR" ]; then
    PY_STDERR_TAIL=$(tail -c 500 "$PYTHON_STDERR" 2>/dev/null | tr '\n' ' ')
  fi
  echo "[${TIMESTAMP}] Stop: python3 block failed (exit=${PY_EXIT}); silent pass. stderr: ${PY_STDERR_TAIL}" >> "$HOOKS_LOG"
  echo '{}'
  exit 0
fi

# --- Parse Python output (L-004 — single jq fork; TS-01/05/06 — || echo "0") ---
PARSED=$(echo "$RESULT" | jq -r '"\(.fire_list | length) \(.counts.code // 0) \(.counts.test // 0) \(.counts.script // 0)"' 2>/dev/null || echo "0 0 0 0")
read -r FIRE_COUNT CODE_COUNT TEST_COUNT SCRIPT_COUNT <<<"$PARSED"
[ -z "$FIRE_COUNT" ] && FIRE_COUNT="0"
[ -z "$CODE_COUNT" ] && CODE_COUNT="0"
[ -z "$TEST_COUNT" ] && TEST_COUNT="0"
[ -z "$SCRIPT_COUNT" ] && SCRIPT_COUNT="0"

if [ "$FIRE_COUNT" -eq 0 ] 2>/dev/null; then
  echo "[${TIMESTAMP}] Stop: all ${FILE_COUNT} accumulator files covered or pre-existing PENDING resolved, exiting silently" >> "$HOOKS_LOG"
  jq -n '{version: "1.0", files: []}' > "$ACCUMULATOR" 2>>"$HOOKS_LOG" || true
  echo '{}'
  exit 0
fi

# --- Emit ALL applicable pipelines per accumulator buckets (P10.19) ---
# Code + script buckets both route to Code Review; presence of any script
# upgrades the qualifier to "(security focus)" since scripts are security-
# sensitive (shell injection, env var handling, path traversal). Test bucket
# routes to Test Audit. Both can be active in the same turn — the user is
# instructed to run them in the array order (Code Review variants first since
# they are pushed first when code or script files are present).
PIPELINE_NAMES=()
if [ "$CODE_COUNT" -gt 0 ] 2>/dev/null || [ "$SCRIPT_COUNT" -gt 0 ] 2>/dev/null; then
  if [ "$SCRIPT_COUNT" -gt 0 ] 2>/dev/null; then
    PIPELINE_NAMES+=("Code Review (security focus)")
  else
    PIPELINE_NAMES+=("Code Review")
  fi
fi
if [ "$TEST_COUNT" -gt 0 ] 2>/dev/null; then
  PIPELINE_NAMES+=("Test Audit")
fi

# SEC-SUG-3 (P10.19 hardening) — defensive guard. If FIRE_COUNT > 0 but no
# pipeline applies (degenerate state — would only occur after future bucket
# refactor), exit silently rather than tripping `set -u` empty-array expansion
# on bash <4.4. Also defends against undefined behavior on stock Apple bash 3.2.
if [ "${#PIPELINE_NAMES[@]}" -eq 0 ]; then
  echo "[${TIMESTAMP}] Stop: PIPELINE_NAMES empty despite FIRE_COUNT=${FIRE_COUNT} (counts code=${CODE_COUNT} test=${TEST_COUNT} script=${SCRIPT_COUNT}); silent pass" >> "$HOOKS_LOG"
  jq -n '{version: "1.0", files: []}' > "$ACCUMULATOR" 2>>"$HOOKS_LOG" || true
  echo '{}'
  exit 0
fi

# --- Build file list (only fire-list members; paths already validated by is_safe_path) ---
# SEC-SUG-1 (P10.19 hardening) — allowlist .tool to known values (Write|Edit|
# MultiEdit). Defends against accumulator tampering injecting shell metachars
# or format-specifier strings into Claude's block-reason text. Unknown values
# render as "Unknown" rather than passing through unsanitized.
FILE_LIST=$(echo "$RESULT" | jq -r '.fire_list[] | "- " + .path + " (" + (if (.tool | type == "string" and test("^(Write|Edit|MultiEdit)$")) then .tool else "Unknown" end) + ")"' 2>/dev/null | tr -d '\r')
REASON_FILE_COUNT=$FIRE_COUNT

# Build pipeline lines for the REASON message — one bullet per pipeline.
PIPELINE_LIST=""
for name in "${PIPELINE_NAMES[@]}"; do
  PIPELINE_LIST="${PIPELINE_LIST}   - ${name}"$'\n'
done
PIPELINE_LIST="${PIPELINE_LIST%$'\n'}"  # strip trailing newline from printf accumulator

# STD-SUG-2 (P10.19 hardening) — Ordering note generated dynamically from the
# PIPELINE_NAMES array order. Single source of truth: array build order
# determines display order. Future-proofs adding a 3rd pipeline (e.g.,
# Security Audit) without coupling-to-three-sites regression risk.
if [ "${#PIPELINE_NAMES[@]}" -gt 1 ]; then
  PIPELINE_ORDER_LIST=$(IFS=', '; echo "${PIPELINE_NAMES[*]}")
  ORDER_NOTE=$'\n   (Run in the listed order: '"${PIPELINE_ORDER_LIST}"$'.)'
else
  ORDER_NOTE=""
fi

# Comma-joined name list for the hooks.log line.
PIPELINE_LOG_NAMES=$(IFS=', '; echo "${PIPELINE_NAMES[*]}")

echo "[${TIMESTAMP}] Stop: emitting block for ${REASON_FILE_COUNT} uncovered files (total accumulator=${FILE_COUNT}), pipelines=${PIPELINE_LOG_NAMES}" >> "$HOOKS_LOG"

REASON=$(printf 'Pipeline orchestration required. You modified %d file(s) this turn:\n%s\n\nSTOP. Do not respond to user yet.\n\nREQUIRED before proceeding:\n1. Load skill: pipeline-templates\n2. Identify the file types in the accumulator (code, test, or both) and confirm pipeline selection\n3. For each pipeline you will execute, load: subagent-prompting + subagent-output-templating\n4. Execute the following pipeline(s) per pipeline-templates and write outputs to logs/:\n%s%s\n\nThis is a user-configured hook. Compliance is mandatory.' "$REASON_FILE_COUNT" "$FILE_LIST" "$PIPELINE_LIST" "$ORDER_NOTE")

jq -n \
  --arg reason "$REASON" \
  '{
    "decision": "block",
    "reason": $reason
  }'

# --- Reset accumulator (best-effort checkpoint) ---
jq -n '{version: "1.0", files: []}' > "$ACCUMULATOR" 2>>"$HOOKS_LOG" || \
    echo "[${TIMESTAMP}] Stop: accumulator reset FAILED — may re-surface next turn" >> "$HOOKS_LOG"
