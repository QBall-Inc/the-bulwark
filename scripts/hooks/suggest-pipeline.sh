#!/bin/bash
# suggest-pipeline.sh
# PostToolUse hook for Write|Edit - suggests pipeline orchestration after code changes
#
# Input (stdin): JSON with tool_name, tool_input, tool_response
# Output (stdout): JSON with hookSpecificOutput.additionalContext
#
# Behavior:
# - Small changes: Skip silently (no suggestion)
# - Significant changes: Inject additionalContext instructing Claude to load pipeline-templates
#
# Small Change Thresholds:
# - Code files: < 5 lines
# - Test files: < 10 lines
# - Config files: < 3 lines
# - Documentation: <= 10 lines
# - Scripts: < 3 lines
#
# PRODUCTION MODE:
# - Hook is always enabled (no flag file check)
# - Configured via /bulwark-scaffold (--no-hooks to opt out)
# - Called by enforce-quality.sh after quality checks pass

# Ensure logs directory exists
LOGS_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}/logs"
mkdir -p "$LOGS_DIR"

# Read input from stdin
INPUT=$(cat)

# Parse tool details
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Skip infrastructure directories (no quality checks or pipeline suggestions)
# DEF-005: Prevents infinite loops when writing to logs/
case "$FILE_PATH" in
  */logs/*|logs/*|*/tmp/*|tmp/*|*/.claude/*|.claude/*|*/node_modules/*|node_modules/*)
    exit 0
    ;;
esac

# Log the invocation
echo "[$TIMESTAMP] PostToolUse: $TOOL_NAME on $FILE_PATH" >> "$LOGS_DIR/hooks.log"

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
  IS_CODE="false"  # Treat as test, not code
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

# Calculate change size
if [ "$TOOL_NAME" = "Edit" ]; then
  # For Edit, measure the old_string and new_string
  OLD_LINES=$(echo "$INPUT" | jq -r '.tool_input.old_string // ""' | wc -l)
  NEW_LINES=$(echo "$INPUT" | jq -r '.tool_input.new_string // ""' | wc -l)
  CHANGE_SIZE=$((NEW_LINES > OLD_LINES ? NEW_LINES : OLD_LINES))
else
  # For Write, use content length
  CHANGE_SIZE=$(echo "$INPUT" | jq -r '.tool_input.content // ""' | wc -l)
fi

# Determine threshold based on file type
THRESHOLD=5  # Default for code
if [ "$IS_TEST" = "true" ]; then
  THRESHOLD=10
elif [ "$IS_CONFIG" = "true" ]; then
  THRESHOLD=3
elif [ "$IS_DOC" = "true" ]; then
  THRESHOLD=10
elif [ "$IS_SCRIPT" = "true" ]; then
  THRESHOLD=3
elif [ "$IS_DATA" = "true" ]; then
  THRESHOLD=1  # Any data file change is significant
fi

# Log decision factors
echo "[$TIMESTAMP] File type: code=$IS_CODE test=$IS_TEST config=$IS_CONFIG doc=$IS_DOC script=$IS_SCRIPT data=$IS_DATA" >> "$LOGS_DIR/hooks.log"
echo "[$TIMESTAMP] Change size: $CHANGE_SIZE lines, threshold: $THRESHOLD" >> "$LOGS_DIR/hooks.log"

# Skip small changes
if [ "$CHANGE_SIZE" -le "$THRESHOLD" ]; then
  echo "[$TIMESTAMP] Pipeline: SKIP (small change: $CHANGE_SIZE <= $THRESHOLD)" >> "$LOGS_DIR/hooks.log"
  exit 0
fi

# Determine recommended pipeline based on file type AND work type
# DEF-004: Write (new file) vs Edit (existing file) affects pipeline selection
RECOMMENDED_PIPELINE="Code Review"
if [ "$IS_CODE" = "true" ]; then
  if [ "$TOOL_NAME" = "Write" ]; then
    # New code file → New Feature Pipeline (includes test generation)
    RECOMMENDED_PIPELINE="New Feature"
  else
    # Editing existing code → Code Review Pipeline
    RECOMMENDED_PIPELINE="Code Review"
  fi
elif [ "$IS_TEST" = "true" ]; then
  RECOMMENDED_PIPELINE="Test Audit"
elif [ "$IS_CONFIG" = "true" ]; then
  RECOMMENDED_PIPELINE="Code Review (security focus)"
elif [ "$IS_SCRIPT" = "true" ]; then
  if [ "$TOOL_NAME" = "Write" ]; then
    RECOMMENDED_PIPELINE="New Feature (security focus)"
  else
    RECOMMENDED_PIPELINE="Code Review (security focus)"
  fi
elif [ "$IS_DOC" = "true" ]; then
  RECOMMENDED_PIPELINE="light review or skip"
elif [ "$IS_DATA" = "true" ]; then
  RECOMMENDED_PIPELINE="manual review suggested"
fi

echo "[$TIMESTAMP] Pipeline: SUGGEST ($RECOMMENDED_PIPELINE for $CHANGE_SIZE lines)" >> "$LOGS_DIR/hooks.log"

# Build quality status message
QUALITY_STATUS=""
if [ "$QUALITY_CHECKS_PASSED" = "true" ]; then
  QUALITY_STATUS="Quality checks COMPLETED (typecheck, lint, build all passed). Do NOT run these again."
else
  QUALITY_STATUS="Quality checks were skipped (non-code file)."
fi

# Output JSON following official Claude Code hooks specification
# Using decision: "block" to force Claude to acknowledge before proceeding
# Combined with additionalContext for full instructions including quality results
cat << EOF
{
  "decision": "block",
  "reason": "MANDATORY: $QUALITY_STATUS Pipeline orchestration required. You modified $FILE_PATH ($CHANGE_SIZE lines). Execute $RECOMMENDED_PIPELINE pipeline.",
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "STOP. Do not respond to user yet.\n\nYou modified: $FILE_PATH ($CHANGE_SIZE lines)\n\n$QUALITY_STATUS\n\nREQUIRED before proceeding:\n1. Load skill: pipeline-templates\n2. Load skill: subagent-prompting\n3. Load skill: subagent-output-templating\n4. Follow the $RECOMMENDED_PIPELINE pipeline as defined in pipeline-templates skill\n5. Verify: Logs written to logs/\n\nThis is a user-configured hook. Compliance is mandatory."
  }
}
EOF
