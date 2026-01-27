#!/bin/bash
# inject-protocol.sh - Inject governance protocol at session start
#
# Hook configuration: once: true (fires once per session)
# Exit code 0: stdout added to Claude's CONTEXT (not just verbose mode)
#
# Architecture: Reads governance content from skill file (not hardcoded)
# This keeps governance readable and user-extensible.
#
# Usage: Called by SessionStart hook, not directly by users

set -euo pipefail

# Get directories
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
LOGS_DIR="${PROJECT_DIR}/logs"
HOOKS_LOG="${LOGS_DIR}/hooks.log"

# Skill file location (relative to script in plugin structure)
# Script is at: scripts/hooks/inject-protocol.sh
# Skill is at:  skills/governance-protocol/SKILL.md
SKILL_FILE="${SCRIPT_DIR}/../../skills/governance-protocol/SKILL.md"

# Ensure logs directory exists
mkdir -p "$LOGS_DIR"

# Log the injection event (for verification)
TIMESTAMP=$(date -Iseconds)
echo "[${TIMESTAMP}] SessionStart: Governance protocol injected (once:true)" >> "$HOOKS_LOG"

# Output activation header (visible in Claude's context)
echo "═══════════════════════════════════════════════════════════════"
echo "  BULWARK GOVERNANCE PROTOCOL - ACTIVATED"
echo "  Quality enforcement enabled for this session"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Extract and output skill content (after frontmatter)
# Frontmatter is between first --- and second ---
if [ -f "$SKILL_FILE" ]; then
  # Use awk with state tracking to skip frontmatter
  # Handle both Unix (LF) and Windows (CRLF) line endings
  awk 'BEGIN{s=0} /^---\r?$/{s++;next} s>=2{gsub(/\r$/,"");print}' "$SKILL_FILE"
else
  echo "Warning: governance-protocol skill not found at ${SKILL_FILE}" >&2
  echo "## Bulwark Governance Protocol"
  echo ""
  echo "Governance skill not found. Please ensure skills/governance-protocol/SKILL.md exists."
fi

exit 0
