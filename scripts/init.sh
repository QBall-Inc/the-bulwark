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

# --- Ensure `just` is installed (hard dependency for scaffold-produced Justfiles) ---

# shellcheck source=./install-just.sh
source "$SCRIPT_DIR/install-just.sh"
install_just

echo ""

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

# --- Write .bulwark/init-marker.yaml ---
# Durable marker recording WHAT init wrote and at WHAT version. Read by:
#   - scripts/hooks/check-template-drift.sh (silent skip if marker absent → no false-positive drift on user-custom Rules.md)
#   - skills/init/SKILL.md UPDATE MODE (iterates artifacts_written to know which user files to diff vs canonical)
# Schema is locked; bulwark-update mode parses it deterministically.

if [ "$SCOPE" = "user" ]; then
  MARKER_DIR="$HOME/.bulwark"
else
  MARKER_DIR="$PROJECT_DIR/.bulwark"
fi
MARKER_PATH="$MARKER_DIR/init-marker.yaml"

# Resolve plugin version from plugin.json (single source of truth).
# Defensive: if plugin.json or jq missing, fall back to "unknown".
PLUGIN_MANIFEST="$PLUGIN_DIR/.claude-plugin/plugin.json"
if [ -f "$PLUGIN_MANIFEST" ] && command -v jq >/dev/null 2>&1; then
  PLUGIN_VERSION=$(jq -r '.version // "unknown"' "$PLUGIN_MANIFEST" 2>/dev/null || echo "unknown")
else
  PLUGIN_VERSION="unknown"
fi

INIT_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

mkdir -p "$MARKER_DIR"

# Compute artifact paths relative to the scope root (RULES_TARGET_DIR for project; HOME for user).
# CLAUDE.md is at scope root; rules.md is at .claude/rules/rules.md (project) or rules/rules.md (user, since HOME/.claude/rules/rules.md → .claude/rules/rules.md relative to HOME).
if [ "$SCOPE" = "user" ]; then
  CLAUDE_REL=".claude/CLAUDE.md"
  RULES_REL=".claude/rules/rules.md"
  SCOPE_ROOT="$HOME"
else
  CLAUDE_REL="CLAUDE.md"
  RULES_REL=".claude/rules/rules.md"
  # Resolve PROJECT_DIR to an absolute path (drift hook reads scope_root and must not depend on cwd).
  SCOPE_ROOT="$(cd "$PROJECT_DIR" && pwd -P)"
fi

cat > "$MARKER_PATH" <<EOF
# .bulwark/init-marker.yaml — written by scripts/init.sh at install time.
# DO NOT delete or hand-edit unless you intend to re-run /the-bulwark:init.
# Used by check-template-drift.sh (SessionStart hook) and /the-bulwark:init --update.
version: "$PLUGIN_VERSION"
init_at: "$INIT_TIMESTAMP"
scope: $SCOPE
scope_root: "$SCOPE_ROOT"
artifacts_written:
  - path: "$CLAUDE_REL"
    canonical: "lib/templates/claude.md"
  - path: "$RULES_REL"
    canonical: "lib/templates/rules.md"
EOF

echo "  Init marker written at $MARKER_PATH"

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
