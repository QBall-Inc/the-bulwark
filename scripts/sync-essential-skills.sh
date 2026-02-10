#!/bin/bash
# Sync selected skills and agents from Bulwark to the Essential Agents & Skills repo.
# Usage: ./scripts/sync-essential-skills.sh [DEST_PATH]
#
# DEST_PATH defaults to ../essential-agents-skills (sibling directory).
# Only syncs skills listed in SKILLS array — Bulwark-internal skills are excluded.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BULWARK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEST="${1:-$BULWARK_ROOT/../essential-agents-skills}"

if [ ! -d "$DEST/.git" ]; then
  echo "Error: $DEST is not a git repository. Clone the repo first."
  exit 1
fi

# --- Skills to sync (directory names under skills/) ---
SKILLS=(
  anthropic-validator
  code-review
  bug-magnet-data
  test-audit
  test-classification
  mock-detection
  assertion-patterns
  component-patterns
  session-handoff
  subagent-prompting
  subagent-output-templating
)

echo "=== Syncing skills ==="
mkdir -p "$DEST/skills"

for skill in "${SKILLS[@]}"; do
  if [ -d "$BULWARK_ROOT/skills/$skill" ]; then
    echo "  Syncing skills/$skill/"
    rsync -av --delete "$BULWARK_ROOT/skills/$skill/" "$DEST/skills/$skill/"
  else
    echo "  WARNING: skills/$skill/ not found in Bulwark"
  fi
done

# --- EZ Statusline ecosystem (rebranded, self-contained) ---
echo "=== Syncing ez-statusline ecosystem ==="

# Skill: bulwark-statusline -> ez-statusline
if [ -d "$BULWARK_ROOT/skills/bulwark-statusline" ]; then
  echo "  Syncing skills/bulwark-statusline/ -> skills/ez-statusline/"
  mkdir -p "$DEST/skills/ez-statusline"
  rsync -av --delete "$BULWARK_ROOT/skills/bulwark-statusline/" "$DEST/skills/ez-statusline/"
fi

# Bundle config template inside skill directory
if [ -f "$BULWARK_ROOT/lib/templates/statusline-default.yaml" ]; then
  echo "  Bundling statusline-default.yaml into skills/ez-statusline/templates/"
  mkdir -p "$DEST/skills/ez-statusline/templates"
  cp "$BULWARK_ROOT/lib/templates/statusline-default.yaml" "$DEST/skills/ez-statusline/templates/"
fi

# Bundle statusline.sh inside skill directory (self-contained)
if [ -f "$BULWARK_ROOT/scripts/statusline/statusline.sh" ]; then
  echo "  Bundling statusline.sh into skills/ez-statusline/scripts/"
  mkdir -p "$DEST/skills/ez-statusline/scripts"
  cp "$BULWARK_ROOT/scripts/statusline/statusline.sh" "$DEST/skills/ez-statusline/scripts/statusline.sh"
  chmod +x "$DEST/skills/ez-statusline/scripts/statusline.sh"
fi

# Agent: standards-reviewer (used by anthropic-validator)
if [ -f "$BULWARK_ROOT/agents/bulwark-standards-reviewer.md" ]; then
  echo "  Syncing agents/bulwark-standards-reviewer.md -> agents/standards-reviewer.md"
  mkdir -p "$DEST/agents"
  cp "$BULWARK_ROOT/agents/bulwark-standards-reviewer.md" "$DEST/agents/standards-reviewer.md"
fi

# Agent: statusline-setup
if [ -f "$BULWARK_ROOT/agents/statusline-setup.md" ]; then
  echo "  Syncing agents/statusline-setup.md"
  mkdir -p "$DEST/agents"
  cp "$BULWARK_ROOT/agents/statusline-setup.md" "$DEST/agents/statusline-setup.md"
fi

echo ""
echo "=== Sync complete ==="
echo "Destination: $DEST"
echo ""
echo "Next steps:"
echo "  1. Review changes: cd $DEST && git status"
echo "  2. Clean Bulwark references in standalone copies (bulwark -> ez-statusline, paths, etc.)"
echo "  3. Commit: git add -A && git commit -m 'Sync from Bulwark'"
