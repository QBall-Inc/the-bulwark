#!/bin/bash
# Usage: init-project-rules.sh [target-dir] [--bulwark]
# Injects Binding Contract + Mandatory Rules into CLAUDE.md.
# --bulwark: Include OR1-4, SA1-6 (Bulwark-specific rules)
# Without --bulwark: Inserts placeholder for custom project rules
# Source: lib/templates/claudemd-injection.md + project-rules-*.md

set -euo pipefail

TARGET="${1:-.}"
BULWARK=false
[[ "$*" == *"--bulwark"* ]] && BULWARK=true

SOURCE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INJECTION_FILE="$SOURCE_DIR/lib/templates/claudemd-injection.md"
CLAUDE_MD="$TARGET/CLAUDE.md"

if [ ! -f "$INJECTION_FILE" ]; then
  echo "ERROR: Injection template not found at $INJECTION_FILE"
  exit 1
fi

if [ ! -d "$TARGET" ]; then
  echo "ERROR: Target directory does not exist: $TARGET"
  exit 1
fi

# Check if Mandatory Rules section already exists (idempotency)
if [ -f "$CLAUDE_MD" ] && grep -q "## Mandatory Rules" "$CLAUDE_MD"; then
  echo "Mandatory Rules section already exists in $CLAUDE_MD. Skipping."
  exit 0
fi

# Create CLAUDE.md if it doesn't exist
if [ ! -f "$CLAUDE_MD" ]; then
  printf "# Project Guide\n\n" > "$CLAUDE_MD"
  echo "Created $CLAUDE_MD"
fi

# Append injection content (Binding Contract + Read Rules.md)
cat "$INJECTION_FILE" >> "$CLAUDE_MD"

# Append project rules (bulwark or blank template)
if [ "$BULWARK" = true ]; then
  RULES_FILE="$SOURCE_DIR/lib/templates/project-rules-bulwark.md"
else
  RULES_FILE="$SOURCE_DIR/lib/templates/project-rules-template.md"
fi

if [ ! -f "$RULES_FILE" ]; then
  echo "ERROR: Project rules template not found at $RULES_FILE"
  exit 1
fi

cat "$RULES_FILE" >> "$CLAUDE_MD"

echo "Mandatory Rules added to $CLAUDE_MD"
