#!/bin/bash
# suggest-pipeline-stop.sh - Stop-hook handler for consolidated pipeline suggestions
#
# Fires at the end of every Claude turn. Reads the changed-files accumulator
# written by enforce-quality.sh and emits exactly one `decision: block`
# pipeline suggestion per turn, citing all qualifying files.
#
# Replaces the PostToolUse-per-edit `decision: block` anti-pattern from
# legacy suggest-pipeline.sh, which cascaded N interruptions on multi-edit
# turns (the "hook storm" / "silent crash").
#
# Input (stdin): Stop hook JSON per Anthropic spec:
#   - stop_hook_active (bool)       recursion guard; true if already firing
#   - stop_reason (string)          end_turn | user_interrupt | max_tokens
#   - session_id (string)           current session id
#   - transcript_path (string)      path to turn transcript
#   - cwd (string)                  working directory
#   - permission_mode (string)      current permission mode
#   - hook_event_name (string)      always "Stop" here
#
# Output (stdout):
#   - {"decision": "block", "reason": ...} when accumulator is non-empty;
#     prevents Claude from ending the turn until the suggested pipeline runs.
#   - {} otherwise (silent pass).
#
# NOTE: Stop hooks do NOT support `hookSpecificOutput` / `additionalContext`
# per the Claude Code schema (https://code.claude.com/docs/en/hooks). Valid
# top-level fields for Stop hooks: decision, reason, continue, stopReason,
# suppressOutput, systemMessage. All instruction content must live in `reason`.
#
# Accumulator contract: see scripts/hooks/enforce-quality.sh (writer).
# Path: ${CLAUDE_PROJECT_DIR:-$(pwd)}/tmp/bulwark-changed-files.json
# Schema: {"version": "1.0", "files": [{"path", "tool", "time"}]}

set -euo pipefail

# Read stdin once
INPUT=$(cat)

# Resolve project directory
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOGS_DIR="${PROJECT_DIR}/logs"
ACCUMULATOR="${PROJECT_DIR}/tmp/bulwark-changed-files.json"

mkdir -p "$LOGS_DIR"
HOOKS_LOG="${LOGS_DIR}/hooks.log"
TIMESTAMP=$(date -Iseconds)

# --- Recursion guard ---
# If a prior Stop hook already blocked and Claude is now responding to that
# block, stop_hook_active is true. Short-circuit to prevent infinite loops.
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
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
if [ "$FILE_COUNT" = "0" ]; then
  echo '{}'
  exit 0
fi

# --- Categorize files for targeted pipeline suggestion ---
CODE_FILES=$(jq -r '[.files[] | select(.path | test("\\.(ts|tsx|js|jsx|py|go|rs|java|cpp|c|rb|php|swift|kt)$"; "i"))] | length' "$ACCUMULATOR")
TEST_FILES=$(jq -r '[.files[] | select(.path | test("(test|spec|_test)\\.(ts|tsx|js|jsx|py|go|rs|java|cpp|rb)$"; "i"))] | length' "$ACCUMULATOR")
SCRIPT_FILES=$(jq -r '[.files[] | select(.path | test("\\.(sh|bash|zsh|fish|ps1)$"; "i"))] | length' "$ACCUMULATOR")

# Choose dominant pipeline
RECOMMENDED_PIPELINE="Code Review"
if [ "$TEST_FILES" -gt 0 ] && [ "$TEST_FILES" -ge "$CODE_FILES" ]; then
  RECOMMENDED_PIPELINE="Test Audit"
elif [ "$SCRIPT_FILES" -gt 0 ] && [ "$SCRIPT_FILES" -ge "$CODE_FILES" ]; then
  RECOMMENDED_PIPELINE="Code Review (security focus)"
fi

# --- Build file list for reason field (sanitized for newline injection) ---
FILE_LIST=$(jq -r '.files[] | "- " + .path + " (" + .tool + ")"' "$ACCUMULATOR" | tr -d '\r')

echo "[${TIMESTAMP}] Stop: emitting block for ${FILE_COUNT} files, pipeline=${RECOMMENDED_PIPELINE}" >> "$HOOKS_LOG"

# --- Emit blocking decision FIRST ---
# Under `set -e`, if the accumulator reset fails (disk full, permission error),
# emitting after the reset would silently drop the block. Emit first so the
# user always gets the pipeline suggestion; reset is best-effort afterward.
# Using jq to build the JSON safely (FILE_LIST may contain shell metachars).
#
# All instruction content goes into `reason` — Stop hooks do not support
# `hookSpecificOutput.additionalContext` per CC schema.
REASON=$(printf 'Pipeline orchestration required. You modified %d file(s) this turn:\n%s\n\nSTOP. Do not respond to user yet.\n\nREQUIRED before proceeding:\n1. Load skill: pipeline-templates\n2. Load skill: subagent-prompting\n3. Load skill: subagent-output-templating\n4. Follow the %s pipeline as defined in pipeline-templates skill\n5. Verify: Logs written to logs/\n\nThis is a user-configured hook. Compliance is mandatory.' "$FILE_COUNT" "$FILE_LIST" "$RECOMMENDED_PIPELINE")

jq -n \
  --arg reason "$REASON" \
  '{
    "decision": "block",
    "reason": $reason
  }'

# --- Reset accumulator (best-effort checkpoint) ---
# || true: if reset fails, at worst the same files re-surface next turn and
# the recursion guard (stop_hook_active) still prevents an immediate loop.
jq -n '{version: "1.0", files: []}' > "$ACCUMULATOR" 2>>"$HOOKS_LOG" || \
    echo "[${TIMESTAMP}] Stop: accumulator reset FAILED — may re-surface next turn" >> "$HOOKS_LOG"
