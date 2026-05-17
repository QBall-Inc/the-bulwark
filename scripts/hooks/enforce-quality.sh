#!/bin/bash
# enforce-quality.sh - Quality gate + changed-files accumulator
#
# Called by PostToolUse hooks on Write|Edit operations.
#
# Phase 1: Quality checks (code files only)
#   - Runs just typecheck, lint, build
#   - Exit 2 on failure (blocks tool call)
#
# Phase 2: Accumulator write (code + script files only)
#   - Appends file path to tmp/bulwark-changed-files.json
#   - Excludes docs, config, infra paths via extension + prefix filter
#   - Dedup on path
#   - Stop hook (suggest-pipeline-stop.sh) reads accumulator and emits
#     exactly ONE pipeline-suggestion block per turn — replacing the legacy
#     per-edit decision:block anti-pattern (hook storm / silent crash).
#
# Exit codes:
#   0 = All checks passed, accumulator updated
#   2 = Quality gate failed (block)
#
# Usage: Called by hooks, not directly by users

set -euo pipefail

# Configuration
MAX_OUTPUT_LINES=100

# Color codes (if terminal supports) — used for warning banners only
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Get directories
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
LOGS_DIR="${PROJECT_DIR}/logs"
HOOKS_LOG="${LOGS_DIR}/hooks.log"

# Ensure logs directory exists
mkdir -p "$LOGS_DIR"

# Capture stdin JSON at start (needed for both phases)
INPUT=$(cat)

# Log hook invocation
TIMESTAMP=$(date -Iseconds)
FILE_PATH_FOR_LOG=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.edits[0].file_path // "unknown"')
echo "[${TIMESTAMP}] PostToolUse: enforce-quality.sh triggered for ${FILE_PATH_FOR_LOG}" >> "$HOOKS_LOG"

# Extract file path from input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.edits[0].file_path // ""')

# Normalize absolute path to repo-relative (if under PROJECT_DIR)
REL_PATH="$FILE_PATH"
if [ -n "$FILE_PATH" ] && [ "${PROJECT_DIR}" != "." ] && [[ "$REL_PATH" == "$PROJECT_DIR/"* ]]; then
    REL_PATH="${REL_PATH#"$PROJECT_DIR/"}"
fi

# Skip infrastructure directories (no quality checks or pipeline suggestions).
# Matches against REPO-RELATIVE path — absolute-path glob matching was a bug:
# any project under a path containing /tmp/, /logs/, etc. was ignored entirely.
# DEF-005: Prevents infinite loops when writing to logs/
case "$REL_PATH" in
  logs/*|tmp/*|.claude/*|node_modules/*|dist/*|build/*|.git/*)
    exit 0
    ;;
esac

# Function to detect if file is a code file
is_code_file() {
    local path="$1"
    echo "$path" | grep -qiE '\.(ts|js|tsx|jsx|py|go|rs|java|cpp|c|rb|php|swift|kt)$'
}

# Function to find just command
find_just() {
    if command -v just &> /dev/null; then
        echo "just"
    elif [ -x "$HOME/.local/bin/just" ]; then
        echo "$HOME/.local/bin/just"
    elif [ -x "/usr/local/bin/just" ]; then
        echo "/usr/local/bin/just"
    else
        echo ""
    fi
}

# Function to check if a Justfile recipe exists
# DEF-003: Gracefully handle missing recipes
recipe_exists() {
    local recipe="$1"
    local just_cmd="$2"
    $just_cmd --list 2>/dev/null | grep -qE "^${recipe}[[:space:]]" || \
    $just_cmd --list 2>/dev/null | grep -qE "^${recipe}$"
}

# ============================================================
# PHASE 1: Quality Checks (code files only)
# ============================================================

if is_code_file "$FILE_PATH"; then
    # Check if Justfile exists
    if [ ! -f "${PROJECT_DIR}/Justfile" ]; then
        echo -e "${YELLOW}::warning::No Justfile found. Run /bulwark-scaffold to initialize.${NC}" >&2
        # Don't block for missing Justfile - proceed to Phase 2
    else
        JUST_CMD=$(find_just)

        if [ -z "$JUST_CMD" ]; then
            echo -e "${YELLOW}::warning::just command not found. Install from https://just.systems${NC}" >&2
            # Don't block for missing just - proceed to Phase 2
        else
            # Change to project directory for quality checks
            cd "${PROJECT_DIR}"

            # Run typecheck if recipe exists (DEF-003: graceful handling)
            if recipe_exists "typecheck" "$JUST_CMD"; then
                TYPECHECK_OUTPUT=$($JUST_CMD typecheck 2>&1 | head -n $MAX_OUTPUT_LINES) || {
                    echo "" >&2
                    echo "╔════════════════════════════════════════════════════════════╗" >&2
                    echo "║  QUALITY GATE FAILED: Typecheck                            ║" >&2
                    echo "╠════════════════════════════════════════════════════════════╣" >&2
                    echo "║  Fix the type errors below before proceeding.              ║" >&2
                    echo "╚════════════════════════════════════════════════════════════╝" >&2
                    echo "$TYPECHECK_OUTPUT" >&2
                    exit 2
                }
            fi

            # Run lint if recipe exists (DEF-003: graceful handling)
            if recipe_exists "lint" "$JUST_CMD"; then
                LINT_OUTPUT=$($JUST_CMD lint 2>&1 | head -n $MAX_OUTPUT_LINES) || {
                    echo "" >&2
                    echo "╔════════════════════════════════════════════════════════════╗" >&2
                    echo "║  QUALITY GATE FAILED: Lint                                 ║" >&2
                    echo "╠════════════════════════════════════════════════════════════╣" >&2
                    echo "║  Fix the lint errors below before proceeding.              ║" >&2
                    echo "╚════════════════════════════════════════════════════════════╝" >&2
                    echo "$LINT_OUTPUT" >&2
                    exit 2
                }
            fi

            # Run build if recipe exists (DEF-003: graceful handling)
            if recipe_exists "build" "$JUST_CMD"; then
                BUILD_OUTPUT=$($JUST_CMD build 2>&1 | head -n $MAX_OUTPUT_LINES) || {
                    echo "" >&2
                    echo "╔════════════════════════════════════════════════════════════╗" >&2
                    echo "║  QUALITY GATE FAILED: Build                                ║" >&2
                    echo "╠════════════════════════════════════════════════════════════╣" >&2
                    echo "║  Fix the build errors below before proceeding.             ║" >&2
                    echo "╚════════════════════════════════════════════════════════════╝" >&2
                    echo "$BUILD_OUTPUT" >&2
                    exit 2
                }
            fi

        fi
    fi
fi

# ============================================================
# PHASE 2: Accumulator Write (code + script files only)
# ============================================================
#
# Legacy Phase 2 chained to suggest-pipeline.sh, which emitted one
# decision:block per edit — cascading into N interrupts on multi-edit turns.
# Replaced by: append qualifying file path to accumulator; Stop hook
# (suggest-pipeline-stop.sh) emits exactly one block at turn end.

# Skip accumulator write if no file path (defensive)
if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# --- Exclusion filter: extensions ---
# Docs, config, data files do not warrant pipeline orchestration.
# Prefix exclusions (logs/, tmp/, .claude/, node_modules/, dist/, build/, .git/)
# already exited at the top-of-file skip. REL_PATH is also pre-computed there.
FILENAME=$(basename "$FILE_PATH")
EXTENSION="${FILENAME##*.}"
EXTENSION_LOWER=$(echo "$EXTENSION" | tr '[:upper:]' '[:lower:]')

case "$EXTENSION_LOWER" in
    md|markdown|json|jsonc|yaml|yml|xml|csv|tsv|txt|docx|xlsx|pdf|html|htm)
        exit 0
        ;;
esac

# --- Accumulator: ensure directory, validate, append with dedup ---
ACCUMULATOR_DIR="${PROJECT_DIR}/tmp"
ACCUMULATOR="${ACCUMULATOR_DIR}/bulwark-changed-files.json"
mkdir -p "$ACCUMULATOR_DIR"

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
ACC_TIMESTAMP=$(date -Iseconds)

# Recover from corrupt accumulator
if [ -f "$ACCUMULATOR" ] && ! jq -e '.' "$ACCUMULATOR" >/dev/null 2>&1; then
    rm -f "$ACCUMULATOR"
fi

if [ ! -f "$ACCUMULATOR" ]; then
    jq -n --arg p "$REL_PATH" --arg t "$TOOL_NAME" --arg ts "$ACC_TIMESTAMP" \
        '{version: "1.0", files: [{path: $p, tool: $t, time: $ts}]}' > "$ACCUMULATOR"
else
    # Dedup: append only if path not already present
    EXISTING=$(jq -r --arg p "$REL_PATH" '.files[] | select(.path == $p) | .path' "$ACCUMULATOR" 2>/dev/null || echo "")
    if [ -z "$EXISTING" ]; then
        jq --arg p "$REL_PATH" --arg t "$TOOL_NAME" --arg ts "$ACC_TIMESTAMP" \
            '.files += [{path: $p, tool: $t, time: $ts}]' "$ACCUMULATOR" > "${ACCUMULATOR}.tmp" \
            && mv "${ACCUMULATOR}.tmp" "$ACCUMULATOR"
    fi
fi

exit 0
