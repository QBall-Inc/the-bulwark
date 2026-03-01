#!/bin/bash
# Usage: init.sh [--scope=project|user] [target-dir]
# Initializes Bulwark governance for a project or user.
#
# Creates:
#   CLAUDE.md    — governance contract, session protocols, modes of operation
#   rules.md     — universal rules (in .claude/rules/)
#
# Scope:
#   --scope=project  (default) — CLAUDE.md at project root, rules at .claude/rules/
#   --scope=user               — CLAUDE.md at ~/.claude/, rules at ~/.claude/rules/
#
# Existing CLAUDE.md and rules.md are backed up with .bak extension.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_TEMPLATE="$PLUGIN_DIR/lib/templates/claude.md"
SCOPE=""
TARGET=""

# --- Parse arguments ---

for arg in "$@"; do
  case "$arg" in
    --scope=project) SCOPE="project" ;;
    --scope=user)    SCOPE="user" ;;
    --scope=*)
      echo "ERROR: Invalid scope '${arg#--scope=}'. Use 'project' or 'user'."
      exit 1
      ;;
    *)
      if [ -z "$TARGET" ]; then
        TARGET="$arg"
      else
        echo "ERROR: Unexpected argument '$arg'"
        exit 1
      fi
      ;;
  esac
done

# --- Interactive scope prompt (if no flag provided) ---

if [ -z "$SCOPE" ]; then
  echo ""
  echo "  Bulwark Init — Scope Selection"
  echo "  ==============================="
  echo ""
  echo "  1) Project scope (default)"
  echo "     CLAUDE.md at project root, rules at .claude/rules/"
  echo "     Affects only this project. Version-controllable."
  echo ""
  echo "  2) User scope"
  echo "     CLAUDE.md at ~/.claude/, rules at ~/.claude/rules/"
  echo "     Applies to ALL projects on this machine."
  echo ""
  read -rp "  Select scope [1]: " choice
  case "$choice" in
    2)    SCOPE="user" ;;
    1|"") SCOPE="project" ;;
    *)
      echo "ERROR: Invalid choice '$choice'. Use 1 or 2."
      exit 1
      ;;
  esac
fi

# --- Resolve target paths ---

if [ "$SCOPE" = "user" ]; then
  CLAUDE_TARGET="$HOME/.claude/CLAUDE.md"
  RULES_TARGET_DIR="$HOME"
  RULES_AT_MENTION="@rules/rules.md"
  echo ""
  echo "  Scope: user (~/.claude/)"
elif [ "$SCOPE" = "project" ]; then
  PROJECT_DIR="${TARGET:-.}"
  if [ ! -d "$PROJECT_DIR" ]; then
    echo "ERROR: Target directory does not exist: $PROJECT_DIR"
    exit 1
  fi
  CLAUDE_TARGET="$PROJECT_DIR/CLAUDE.md"
  RULES_TARGET_DIR="$PROJECT_DIR"
  RULES_AT_MENTION="@.claude/rules/rules.md"
  echo ""
  echo "  Scope: project ($PROJECT_DIR)"
fi

echo ""

# --- Validate template ---

if [ ! -f "$CLAUDE_TEMPLATE" ]; then
  echo "ERROR: CLAUDE.md template not found at $CLAUDE_TEMPLATE"
  exit 1
fi

# --- Install CLAUDE.md ---

if [ -f "$CLAUDE_TARGET" ]; then
  BACKUP="$CLAUDE_TARGET.bak"
  cp "$CLAUDE_TARGET" "$BACKUP"
  echo "  Backed up existing CLAUDE.md to $BACKUP"
fi

if [ "$SCOPE" = "user" ]; then
  mkdir -p "$HOME/.claude"
  # User scope: strip Project Assets section, adjust @-mention path
  sed '/^## Project Assets/,/^---/d; s|@.claude/rules/rules.md|'"$RULES_AT_MENTION"'|g' \
    "$CLAUDE_TEMPLATE" > "$CLAUDE_TARGET"
else
  cp "$CLAUDE_TEMPLATE" "$CLAUDE_TARGET"
fi

echo "  CLAUDE.md installed at $CLAUDE_TARGET"

# --- Install rules.md ---

"$SCRIPT_DIR/init-rules.sh" "$RULES_TARGET_DIR"

# --- Post-init checklist ---

echo ""
echo "  ==============================="
echo "  Bulwark governance initialized!"
echo "  ==============================="
echo ""
RULES_DISPLAY="${RULES_TARGET_DIR}/.claude/rules/rules.md"
echo "  Files created:"
echo "    - $CLAUDE_TARGET"
echo "    - $RULES_DISPLAY"
echo ""
echo "  Next steps:"
echo "    1. Restart your Claude Code session (required — hooks activate on restart)"
echo "    2. Run /setup-lsp to configure Language Server Protocol support (recommended)"
echo "    3. Run /bulwark-scaffold to generate a Justfile with project tooling (recommended)"
echo ""

if [ "$SCOPE" = "user" ]; then
  echo "  Note: You installed at user scope. Consider also creating a project-level"
  echo "  CLAUDE.md with project-specific assets and context for individual projects."
  echo ""
fi

echo "  IMPORTANT: Hooks do not activate until you restart your Claude Code session."
echo "  This is a known Claude Code limitation (#10997). After restarting, Bulwark's"
echo "  quality gates (typecheck, lint, build) will enforce automatically on every"
echo "  code change."
echo ""
