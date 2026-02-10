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

# Verify sub-agent wrote expected log output
# Custom agents (bulwark-implementer, bulwark-issue-analyzer, etc.) always include
# their name in log filenames per SA2. Skip for general-purpose agents which are
# ad-hoc and may not follow the naming convention.
if [ "$SUBAGENT_TYPE" != "unknown" ] && [ "$SUBAGENT_TYPE" != "general-purpose" ]; then
    # Search for files containing agent type name modified in last 60 seconds
    RECENT_LOG=$(find "$LOGS_DIR" -maxdepth 2 -name "*${SUBAGENT_TYPE}*" -mmin -1 2>/dev/null | head -1)
    if [ -n "$RECENT_LOG" ]; then
        echo "[$TIMESTAMP] SubagentStop: Log verified at $RECENT_LOG" >> "$LOGS_DIR/hooks.log"
    else
        echo "[$TIMESTAMP] SubagentStop: WARNING - No log output found for $SUBAGENT_TYPE" >> "$LOGS_DIR/hooks.log"
        echo "WARNING: Sub-agent $SUBAGENT_TYPE ($AGENT_ID) completed without writing expected log to logs/" >&2
    fi
fi
