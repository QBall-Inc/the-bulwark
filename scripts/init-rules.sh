#!/bin/bash
# Usage: init-rules.sh [target-dir]
# Copies universal Rules.md to target project root.
# If Rules.md already exists, creates backup.
# Source: lib/templates/rules.md (portable copy, NOT project root Rules.md)

set -euo pipefail

TARGET="${1:-.}"
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

if [ -f "$TARGET/Rules.md" ]; then
  BACKUP="$TARGET/Rules.md.backup-$(date +%Y%m%d-%H%M%S)"
  cp "$TARGET/Rules.md" "$BACKUP"
  echo "Backed up existing Rules.md to $BACKUP"
fi

cp "$SOURCE_FILE" "$TARGET/Rules.md"
echo "Rules.md installed at $TARGET/Rules.md"
