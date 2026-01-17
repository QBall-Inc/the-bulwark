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
# ENABLE/DISABLE:
# - To enable:  touch ${CLAUDE_PROJECT_DIR}/.claude/enable-pipeline-hooks
# - To disable: rm ${CLAUDE_PROJECT_DIR}/.claude/enable-pipeline-hooks
# - Hook is DISABLED by default

# Check if hook is enabled via flag file
FLAG_FILE="${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude/enable-pipeline-hooks"
if [ ! -f "$FLAG_FILE" ]; then
  # Hook disabled - exit silently
  exit 0
fi

# Ensure logs directory exists
LOGS_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}/logs"
mkdir -p "$LOGS_DIR"

# Read input from stdin
INPUT=$(cat)

# Parse tool details
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

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

# Determine recommended pipeline based on file type
RECOMMENDED_PIPELINE="Code Review"
if [ "$IS_TEST" = "true" ]; then
  RECOMMENDED_PIPELINE="Test Audit"
elif [ "$IS_CONFIG" = "true" ]; then
  RECOMMENDED_PIPELINE="Code Review (security focus)"
elif [ "$IS_SCRIPT" = "true" ]; then
  RECOMMENDED_PIPELINE="Code Review (security focus)"
elif [ "$IS_DOC" = "true" ]; then
  RECOMMENDED_PIPELINE="light review or skip"
elif [ "$IS_DATA" = "true" ]; then
  RECOMMENDED_PIPELINE="manual review suggested"
fi

echo "[$TIMESTAMP] Pipeline: SUGGEST ($RECOMMENDED_PIPELINE for $CHANGE_SIZE lines)" >> "$LOGS_DIR/hooks.log"

# Inject mandatory pipeline instruction - framed as task incompleteness
# NOTE: The instruction chain is explicit to prevent loopholes where sub-agents
# return inline instead of writing to logs. Each step must be followed in order.
cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "STOP - TASK INCOMPLETE\n\nYou modified $FILE_PATH ($CHANGE_SIZE lines).\n\nThis implementation is NOT COMPLETE. Per project requirements:\n\n1. Load the subagent-prompting skill to get the 4-part prompt template\n   (GOAL/CONSTRAINTS/CONTEXT/OUTPUT)\n\n2. Load the subagent-output-templating skill and pass it to each sub-agent\n   so they write structured output to logs/\n\n3. Run the $RECOMMENDED_PIPELINE pipeline, prompting each sub-agent\n   using the 4-part template from step 1\n\n4. Do NOT summarize or report completion until the pipeline has executed\n   AND sub-agent logs have been written to logs/\n\n5. The user has explicitly configured this requirement - skipping violates\n   their intent"
  }
}
EOF
