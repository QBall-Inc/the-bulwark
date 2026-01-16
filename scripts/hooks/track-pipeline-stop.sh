#!/bin/bash
# track-pipeline-stop.sh
# SubagentStop hook - logs pipeline stage completion
#
# Input (stdin): JSON with session_id, agent_id, subagent_type, agent_transcript_path
# Output: None required (logging only)
#
# Purpose:
# - Track when pipeline stages complete
# - Calculate stage duration (when paired with start)
# - Support pipeline debugging and verification

# Ensure logs directory exists
LOGS_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}/logs"
mkdir -p "$LOGS_DIR"

# Read input from stdin
INPUT=$(cat)

# Parse event details
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"')
AGENT_ID=$(echo "$INPUT" | jq -r '.agent_id // "unknown"')
SUBAGENT_TYPE=$(echo "$INPUT" | jq -r '.subagent_type // "unknown"')
TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.agent_transcript_path // "none"')

# Log to pipeline tracking file
cat >> "$LOGS_DIR/pipeline-tracking.log" << EOF
[$TIMESTAMP] SubagentStop
  session: $SESSION_ID
  agent_id: $AGENT_ID
  type: $SUBAGENT_TYPE
  transcript: $TRANSCRIPT_PATH
EOF

# Also log to general hooks log
echo "[$TIMESTAMP] SubagentStop: $AGENT_ID ($SUBAGENT_TYPE)" >> "$LOGS_DIR/hooks.log"

# Optionally verify output exists (if transcript path provided)
if [ "$TRANSCRIPT_PATH" != "none" ] && [ -f "$TRANSCRIPT_PATH" ]; then
    echo "[$TIMESTAMP] SubagentStop: Transcript verified at $TRANSCRIPT_PATH" >> "$LOGS_DIR/hooks.log"
fi
