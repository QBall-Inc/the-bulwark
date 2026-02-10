#!/bin/bash
# enforce-quality.sh - Quality gate + pipeline suggestion (chained execution)
#
# Called by PostToolUse hooks on Write|Edit operations.
#
# Phase 1: Quality checks (code files only)
#   - Runs just typecheck, lint, build
#   - Exit 2 on failure (blocks tool call)
#
# Phase 2: Pipeline suggestion (all files)
#   - Chains to suggest-pipeline.sh
#   - Passes through stdin JSON for change analysis
#
# Exit codes:
#   0 = All checks passed, pipeline suggestion complete
#   2 = Quality gate failed (block)
#
# Usage: Called by hooks, not directly by users

set -euo pipefail

# Configuration
MAX_OUTPUT_LINES=100

# Color codes (if terminal supports)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Get directories
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
LOGS_DIR="${PROJECT_DIR}/logs"
HOOKS_LOG="${LOGS_DIR}/hooks.log"

# Ensure logs directory exists
mkdir -p "$LOGS_DIR"

# Capture stdin JSON at start (needed for both phases)
INPUT=$(cat)

# Log hook invocation
TIMESTAMP=$(date -Iseconds)
FILE_PATH_FOR_LOG=$(echo "$INPUT" | jq -r '.tool_input.file_path // "unknown"')
echo "[${TIMESTAMP}] PostToolUse: enforce-quality.sh triggered for ${FILE_PATH_FOR_LOG}" >> "$HOOKS_LOG"

# Extract file path from input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# Skip infrastructure directories (no quality checks or pipeline suggestions)
# DEF-005: Prevents infinite loops when writing to logs/
case "$FILE_PATH" in
  */logs/*|logs/*|*/tmp/*|tmp/*|*/.claude/*|.claude/*|*/node_modules/*|node_modules/*)
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

            # Export quality results for suggest-pipeline.sh
            export QUALITY_CHECKS_PASSED="true"
        fi
    fi
fi

# ============================================================
# PHASE 2: Pipeline Suggestion (all file types)
# ============================================================

SUGGEST_SCRIPT="${SCRIPT_DIR}/suggest-pipeline.sh"

if [ -x "$SUGGEST_SCRIPT" ]; then
    # Pass through the original input to suggest-pipeline.sh
    echo "$INPUT" | "$SUGGEST_SCRIPT"
else
    # suggest-pipeline.sh not found - not an error, just skip
    exit 0
fi
