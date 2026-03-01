#!/bin/bash
# Usage: init-rules.sh <target-dir>
# Copies universal rules.md to <target-dir>/.claude/rules/rules.md
# If rules.md already exists at target, creates .bak backup.
# Source: lib/templates/rules.md (portable copy, NOT project root Rules.md)

set -euo pipefail

TARGET="${1:?Usage: init-rules.sh <target-dir>}"
SOURCE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_FILE="$SOURCE_DIR/lib/templates/rules.md"

if [ ! -f "$SOURCE_FILE" ]; then
  echo "ERROR: Source template not found at $SOURCE_FILE"
  exit 1
fi

if [ ! -d "$TARGET" ]; then
  echo "ERROR: Target directory does not exist: $TARGET"
  exit 1
fi

RULES_DIR="$TARGET/.claude/rules"
RULES_FILE="$RULES_DIR/rules.md"

mkdir -p "$RULES_DIR"

if [ -f "$RULES_FILE" ]; then
  BACKUP="$RULES_FILE.bak"
  cp "$RULES_FILE" "$BACKUP"
  echo "  Backed up existing rules.md to $BACKUP"
fi

cp "$SOURCE_FILE" "$RULES_FILE"
echo "  rules.md installed at $RULES_FILE"
