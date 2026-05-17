#!/usr/bin/env bash
# Age-based cleanup for logs/ and tmp/ directories
# Deletes files older than 10 days, preserves .gitkeep
# Runs on SessionStart — T-10 threshold is the guard (safe on resume/compact)
#
# Hardened in P10.16 (SUG-001): SEC-007-style env-var validation — refuses
# to operate if CLAUDE_PROJECT_DIR is not an absolute existing path.
# Parity with cleanup-review-registry.sh.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

case "$PROJECT_DIR" in
  /*) ;;
  *) exit 0 ;;
esac
[ -d "$PROJECT_DIR" ] || exit 0

TIMESTAMP=$(date -Iseconds)
HOOKS_LOG="${PROJECT_DIR}/logs/hooks.log"
mkdir -p "$(dirname "$HOOKS_LOG")" 2>/dev/null
echo "[${TIMESTAMP}] SessionStart: cleanup-stale.sh — purging logs/ and tmp/ files >10 days old" >> "$HOOKS_LOG" 2>/dev/null

find "${PROJECT_DIR}/logs" "${PROJECT_DIR}/tmp" \
  -type f -mtime +10 -not -name '.gitkeep' -delete 2>/dev/null

# Remove empty directories left after file deletion (except the roots)
find "${PROJECT_DIR}/logs" "${PROJECT_DIR}/tmp" \
  -mindepth 1 -type d -empty -delete 2>/dev/null

exit 0  # Never block session start
