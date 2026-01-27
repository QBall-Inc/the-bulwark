#!/bin/bash
# sync-hooks-for-dev.sh - Sync plugin hooks to project settings for local development
#
# This script transforms hooks/hooks.json (plugin-level, uses CLAUDE_PLUGIN_ROOT)
# to .claude/settings.json (project-level, uses CLAUDE_PROJECT_DIR) for dogfooding.
#
# Usage: ./scripts/sync-hooks-for-dev.sh
#        just sync-hooks
#
# Idempotent: Safe to run repeatedly - overwrites hooks section only.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/.."
HOOKS_SOURCE="${PROJECT_DIR}/hooks/hooks.json"
SETTINGS_FILE="${PROJECT_DIR}/.claude/settings.json"

# Check source exists
if [ ! -f "$HOOKS_SOURCE" ]; then
  echo "Error: hooks/hooks.json not found at ${HOOKS_SOURCE}" >&2
  exit 1
fi

# Ensure .claude directory exists
mkdir -p "$(dirname "$SETTINGS_FILE")"

# Read and transform hooks
# Replace ${CLAUDE_PLUGIN_ROOT} with ${CLAUDE_PROJECT_DIR}
TRANSFORMED_HOOKS=$(cat "$HOOKS_SOURCE" | sed 's/\${CLAUDE_PLUGIN_ROOT}/\${CLAUDE_PROJECT_DIR}/g')

# If settings.json exists, merge hooks into it
if [ -f "$SETTINGS_FILE" ]; then
  # Read existing settings
  EXISTING=$(cat "$SETTINGS_FILE")

  # Extract hooks from transformed source
  NEW_HOOKS=$(echo "$TRANSFORMED_HOOKS" | jq '.hooks')

  # Merge: update hooks key, preserve everything else
  MERGED=$(echo "$EXISTING" | jq --argjson hooks "$NEW_HOOKS" '.hooks = $hooks')

  echo "$MERGED" | jq '.' > "$SETTINGS_FILE"
  echo "Updated .claude/settings.json with hooks from hooks/hooks.json"
else
  # Create new settings.json with just the hooks
  echo "$TRANSFORMED_HOOKS" | jq '.' > "$SETTINGS_FILE"
  echo "Created .claude/settings.json from hooks/hooks.json"
fi

# Show what was synced
echo ""
echo "Synced hooks:"
jq '.hooks | keys[]' "$SETTINGS_FILE" | tr -d '"' | while read event; do
  count=$(jq ".hooks.\"$event\" | length" "$SETTINGS_FILE")
  echo "  - ${event}: ${count} hook(s)"
done

echo ""
echo "Path transformation: \${CLAUDE_PLUGIN_ROOT} → \${CLAUDE_PROJECT_DIR}"
echo "Done."
