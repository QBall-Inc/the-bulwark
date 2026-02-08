#!/bin/bash
# implementer-quality.sh - Agent-invoked quality gate + pipeline suggestion
#
# Called by bulwark-implementer agent directly via Bash after each Write/Edit.
# Unlike enforce-quality.sh (which reads stdin JSON from hook system),
# this script accepts a file path as a CLI argument.
#
# Phase 1: Quality checks (code files only)
#   - Runs just typecheck, lint, build
#   - Outputs error details to stdout on failure
#
# Phase 2: Pipeline suggestion (all file types)
#   - Classifies file type and estimates change size
#   - Outputs plain text suggestion
#
# Exit codes:
#   0 = All checks passed (or non-code file)
#   1 = Quality gate failed
#
# Usage: implementer-quality.sh <file_path>

set -euo pipefail

# Configuration
MAX_OUTPUT_LINES=100

# Validate arguments
if [ $# -lt 1 ]; then
    echo "ERROR: Missing file path argument" >&2
    echo "Usage: implementer-quality.sh <file_path>" >&2
    exit 1
fi

FILE_PATH="$1"

# Get directories
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
LOGS_DIR="${PROJECT_DIR}/logs"
HOOKS_LOG="${LOGS_DIR}/hooks.log"

# Ensure logs directory exists
mkdir -p "$LOGS_DIR"

# Log invocation
TIMESTAMP=$(date -Iseconds)
echo "[$TIMESTAMP] implementer-quality.sh invoked for ${FILE_PATH}" >> "$HOOKS_LOG"

# Skip infrastructure directories
case "$FILE_PATH" in
    */logs/*|logs/*|*/tmp/*|tmp/*|*/.claude/*|.claude/*|*/node_modules/*|node_modules/*)
        echo "QUALITY: SKIPPED (infrastructure path)"
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
recipe_exists() {
    local recipe="$1"
    local just_cmd="$2"
    $just_cmd --list 2>/dev/null | grep -qE "^${recipe}[[:space:]]" || \
    $just_cmd --list 2>/dev/null | grep -qE "^${recipe}$"
}

# ============================================================
# PHASE 1: Quality Checks (code files only)
# ============================================================

QUALITY_PASSED="true"

if is_code_file "$FILE_PATH"; then
    if [ ! -f "${PROJECT_DIR}/Justfile" ]; then
        echo "WARNING: No Justfile found. Quality checks skipped."
    else
        JUST_CMD=$(find_just)

        if [ -z "$JUST_CMD" ]; then
            echo "WARNING: just command not found. Quality checks skipped."
        else
            cd "${PROJECT_DIR}"

            # Run typecheck if recipe exists
            if recipe_exists "typecheck" "$JUST_CMD"; then
                TYPECHECK_OUTPUT=$($JUST_CMD typecheck 2>&1 | head -n $MAX_OUTPUT_LINES) || {
                    QUALITY_PASSED="false"
                    echo "QUALITY: FAILED"
                    echo "GATE: typecheck"
                    echo "---"
                    echo "$TYPECHECK_OUTPUT"
                    echo "---"
                    echo "Fix the type errors above and retry."
                    echo "[$TIMESTAMP] implementer-quality.sh: FAILED typecheck for ${FILE_PATH}" >> "$HOOKS_LOG"
                    exit 1
                }
            fi

            # Run lint if recipe exists
            if recipe_exists "lint" "$JUST_CMD"; then
                LINT_OUTPUT=$($JUST_CMD lint 2>&1 | head -n $MAX_OUTPUT_LINES) || {
                    QUALITY_PASSED="false"
                    echo "QUALITY: FAILED"
                    echo "GATE: lint"
                    echo "---"
                    echo "$LINT_OUTPUT"
                    echo "---"
                    echo "Fix the lint errors above and retry."
                    echo "[$TIMESTAMP] implementer-quality.sh: FAILED lint for ${FILE_PATH}" >> "$HOOKS_LOG"
                    exit 1
                }
            fi

            # Run build if recipe exists
            if recipe_exists "build" "$JUST_CMD"; then
                BUILD_OUTPUT=$($JUST_CMD build 2>&1 | head -n $MAX_OUTPUT_LINES) || {
                    QUALITY_PASSED="false"
                    echo "QUALITY: FAILED"
                    echo "GATE: build"
                    echo "---"
                    echo "$BUILD_OUTPUT"
                    echo "---"
                    echo "Fix the build errors above and retry."
                    echo "[$TIMESTAMP] implementer-quality.sh: FAILED build for ${FILE_PATH}" >> "$HOOKS_LOG"
                    exit 1
                }
            fi
        fi
    fi
fi

# ============================================================
# PHASE 2: Pipeline Suggestion (all file types)
# ============================================================

# Extract file extension and name
FILENAME=$(basename "$FILE_PATH")
EXTENSION="${FILENAME##*.}"
EXTENSION_LOWER=$(echo "$EXTENSION" | tr '[:upper:]' '[:lower:]')

# Determine file type
IS_CODE="false"
IS_TEST="false"
IS_CONFIG="false"
IS_DOC="false"
IS_SCRIPT="false"
IS_DATA="false"

# Code files
if echo "$EXTENSION_LOWER" | grep -qE '^(ts|js|tsx|jsx|py|go|rs|java|cpp|c|rb|php|swift|kt)$'; then
    IS_CODE="true"
fi

# Test files (check filename pattern)
if echo "$FILENAME" | grep -qiE '(test|spec|_test)\.(ts|js|tsx|jsx|py|go|rs|java|cpp|rb)$'; then
    IS_TEST="true"
    IS_CODE="false"
fi

# Config files
if echo "$EXTENSION_LOWER" | grep -qE '^(json|yaml|yml|toml|ini|env|config)$'; then
    IS_CONFIG="true"
fi

# Documentation files
if echo "$EXTENSION_LOWER" | grep -qE '^(md|txt|rst|adoc)$'; then
    IS_DOC="true"
fi

# Script files
if echo "$EXTENSION_LOWER" | grep -qE '^(sh|bash|zsh|fish|ps1)$'; then
    IS_SCRIPT="true"
fi

# Data files
if echo "$EXTENSION_LOWER" | grep -qE '^(xlsx|xls|csv|pdf|docx|pptx)$'; then
    IS_DATA="true"
fi

# Count file lines as change size proxy (no hook JSON available)
if [ -f "$FILE_PATH" ]; then
    CHANGE_SIZE=$(wc -l < "$FILE_PATH" 2>/dev/null || echo "0")
else
    CHANGE_SIZE=0
fi

# Determine threshold based on file type
THRESHOLD=5
if [ "$IS_TEST" = "true" ]; then
    THRESHOLD=10
elif [ "$IS_CONFIG" = "true" ]; then
    THRESHOLD=3
elif [ "$IS_DOC" = "true" ]; then
    THRESHOLD=10
elif [ "$IS_SCRIPT" = "true" ]; then
    THRESHOLD=3
elif [ "$IS_DATA" = "true" ]; then
    THRESHOLD=1
fi

# Determine recommended pipeline
RECOMMENDED_PIPELINE="none"
if [ "$CHANGE_SIZE" -gt "$THRESHOLD" ]; then
    if [ "$IS_CODE" = "true" ]; then
        # Check if file already existed (Edit vs new Write)
        # Since we can't tell from CLI, use line count as heuristic:
        # large files are likely existing code, small files may be new
        RECOMMENDED_PIPELINE="Code Review"
    elif [ "$IS_TEST" = "true" ]; then
        RECOMMENDED_PIPELINE="Test Audit"
    elif [ "$IS_CONFIG" = "true" ]; then
        RECOMMENDED_PIPELINE="Code Review"
    elif [ "$IS_SCRIPT" = "true" ]; then
        RECOMMENDED_PIPELINE="Code Review"
    elif [ "$IS_DOC" = "true" ]; then
        RECOMMENDED_PIPELINE="none"
    elif [ "$IS_DATA" = "true" ]; then
        RECOMMENDED_PIPELINE="none"
    fi
fi

# Log decision
echo "[$TIMESTAMP] implementer-quality.sh: PASSED for ${FILE_PATH} (pipeline: ${RECOMMENDED_PIPELINE}, lines: ${CHANGE_SIZE})" >> "$HOOKS_LOG"

# Output results in plain text format
echo "QUALITY: PASSED"
echo "PIPELINE: ${RECOMMENDED_PIPELINE}"
echo "TARGET: ${FILE_PATH}"
echo "LINES: ${CHANGE_SIZE}"
if [ "$RECOMMENDED_PIPELINE" != "none" ]; then
    echo "REASON: File type detected, ${CHANGE_SIZE} lines exceeds threshold ${THRESHOLD}"
else
    if [ "$CHANGE_SIZE" -le "$THRESHOLD" ]; then
        echo "REASON: Small change (${CHANGE_SIZE} lines, threshold ${THRESHOLD}), no pipeline needed"
    else
        echo "REASON: File type does not require pipeline review"
    fi
fi
