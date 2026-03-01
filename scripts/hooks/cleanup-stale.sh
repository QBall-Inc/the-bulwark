#!/usr/bin/env bash
# Age-based cleanup for logs/ and tmp/ directories
# Deletes files older than 10 days, preserves .gitkeep
# Runs on SessionStart — T-10 threshold is the guard (safe on resume/compact)

find "${CLAUDE_PROJECT_DIR}/logs" "${CLAUDE_PROJECT_DIR}/tmp" \
  -type f -mtime +10 -not -name '.gitkeep' -delete 2>/dev/null

# Remove empty directories left after file deletion (except the roots)
find "${CLAUDE_PROJECT_DIR}/logs" "${CLAUDE_PROJECT_DIR}/tmp" \
  -mindepth 1 -type d -empty -delete 2>/dev/null

exit 0  # Never block session start
