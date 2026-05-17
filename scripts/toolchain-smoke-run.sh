#!/bin/bash
# toolchain-smoke-run.sh — non-blocking language-tool availability check.
#
# Invoked by:  `/the-bulwark:init --verify` Stage 8f (SKILL.md) for per-tool
#              install-hint readout on a scaffolded project.
#
# Usage:
#   scripts/toolchain-smoke-run.sh [project-dir]
#
# Arguments:
#   project-dir  Directory containing a Justfile (default: current dir)
#
# Contract (non-negotiable per P10.1 Part E):
#   - DOES NOT install tools.
#   - DOES NOT modify the Justfile.
#   - DOES NOT exit non-zero on missing tools.
#   - ONLY reports status and install hints.
#
# Exit codes:
#   0 — always, on every successful readout (including partial/unavailable).
#   1 — only on invocation error (bad args, no Justfile) or internal failure.
#
# Output format (stdout):
#   Toolchain check ({Language}):
#     - <tool>  [installed|missing] <optional path or install hint>
#   ...
#   Status: {ready|partial|unavailable|fail-loudly}
#
# Machine-readable trailer (stderr):
#   TOOLCHAIN_STATUS={ready|partial|unavailable|fail-loudly}
#   TOOLCHAIN_LANG={node|python|rust|go|kotlin|swift|shell|generic}
#   TOOLCHAIN_MISSING={comma-separated tool names or empty}

set -uo pipefail

PROJECT_DIR="${1:-.}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "ERROR: project directory not found: $PROJECT_DIR" >&2
  exit 1
fi

JUSTFILE="$PROJECT_DIR/Justfile"

if [ ! -f "$JUSTFILE" ]; then
  echo "Toolchain check: Justfile not found at $JUSTFILE"
  echo "Status: unavailable"
  echo "TOOLCHAIN_STATUS=unavailable" >&2
  echo "TOOLCHAIN_LANG=none" >&2
  echo "TOOLCHAIN_MISSING=" >&2
  exit 0
fi

# ---------------------------------------------------------------------------
# Language detection from Justfile header
# ---------------------------------------------------------------------------

detect_language_from_justfile() {
  local justfile="$1"
  local header
  header="$(head -1 "$justfile")"

  case "$header" in
    *"Bulwark Justfile Template - Node/TypeScript"*) echo "node" ;;
    *"Bulwark Justfile Template - Python"*)          echo "python" ;;
    *"Bulwark Justfile Template - Rust"*)            echo "rust" ;;
    *"Bulwark Justfile Template - Go"*)              echo "go" ;;
    *"Bulwark Justfile Template - Kotlin"*)          echo "kotlin" ;;
    *"Bulwark Justfile Template - Swift"*)           echo "swift" ;;
    *"Bulwark Justfile Template - Shell"*)           echo "shell" ;;
    *"Bulwark Justfile Template - Generic"*)         echo "generic" ;;
    *)                                                echo "unknown" ;;
  esac
}

# ---------------------------------------------------------------------------
# Tool maps per language — mirrors skills/init/SKILL.md Stage 8f.4 table.
# Install hints are deliberately short; the full header comment block in each
# template is the canonical detail source.
# ---------------------------------------------------------------------------

tools_for_language() {
  case "$1" in
    node)    echo "tsc eslint" ;;
    python)  echo "mypy ruff pytest" ;;
    rust)    echo "cargo" ;;
    go)      echo "go golangci-lint gofmt" ;;
    kotlin)  echo "java ktlint detekt" ;;
    swift)   echo "swiftlint swift-format" ;;
    shell)   echo "shellcheck shfmt" ;;
    *)       echo "" ;;
  esac
}

install_hint_for_tool() {
  local tool="$1"
  case "$tool" in
    tsc|eslint)      echo "install: npm install (project-local) or npm install -g typescript eslint" ;;
    mypy)            echo "install: pip install mypy" ;;
    ruff)            echo "install: pip install ruff" ;;
    pytest)          echo "install: pip install pytest" ;;
    cargo)           echo "install: https://rustup.rs" ;;
    go)              echo "install: https://go.dev/doc/install" ;;
    golangci-lint)   echo "install: brew install golangci-lint (macOS) | scoop install golangci-lint (Win) | see upstream for Linux" ;;
    gofmt)           echo "install: ships with Go — install Go toolchain first" ;;
    java)            echo "install: brew install openjdk@17 (macOS) | apt install openjdk-17-jdk (Debian) | scoop install temurin-jdk (Win)" ;;
    ktlint)          echo "install: brew install ktlint (macOS) | scoop install ktlint (Win) | binary from https://github.com/pinterest/ktlint/releases" ;;
    detekt)          echo "install: brew install detekt (macOS) | scoop install detekt (Win) | jar from https://github.com/detekt/detekt/releases" ;;
    swiftlint)       echo "install: brew install swiftlint (macOS) | Linux: pre-built binary" ;;
    swift-format)    echo "install: brew install swift-format (macOS) | Linux: build from source" ;;
    shellcheck)      echo "install: brew install shellcheck (macOS) | apt install shellcheck (Debian) | scoop install shellcheck (Win)" ;;
    shfmt)           echo "install: brew install shfmt (macOS) | go install mvdan.cc/sh/v3/cmd/shfmt@latest | scoop install shfmt (Win)" ;;
    *)               echo "install: see $tool upstream documentation" ;;
  esac
}

# ---------------------------------------------------------------------------
# Per-tool availability check
# ---------------------------------------------------------------------------

check_tool() {
  local tool="$1"
  local node_local="$PROJECT_DIR/node_modules/.bin/$tool"

  # Node tools often live in project-local node_modules/.bin
  if [ -x "$node_local" ]; then
    echo "  - $tool  installed ($node_local)"
    return 0
  fi

  local tool_path
  if tool_path="$(command -v "$tool" 2>/dev/null)"; then
    echo "  - $tool  installed ($tool_path)"
    return 0
  fi

  echo "  - $tool  missing — $(install_hint_for_tool "$tool")"
  return 1
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

LANG="$(detect_language_from_justfile "$JUSTFILE")"

# Canonical display name map
case "$LANG" in
  node)    display_lang="Node/TypeScript" ;;
  python)  display_lang="Python" ;;
  rust)    display_lang="Rust" ;;
  go)      display_lang="Go" ;;
  kotlin)  display_lang="Kotlin" ;;
  swift)   display_lang="Swift" ;;
  shell)   display_lang="Shell" ;;
  generic) display_lang="Generic" ;;
  *)       display_lang="Unknown" ;;
esac

# Justfile structural check — `just --dry-run lint` confirms the recipe resolves.
# Skip for generic (recipe exits 1 by design, which is NOT the structural failure we want to catch here).
if [ "$LANG" != "generic" ] && [ "$LANG" != "unknown" ]; then
  if ! (cd "$PROJECT_DIR" && just --dry-run lint) >/dev/null 2>&1; then
    echo "Toolchain check ($display_lang):"
    echo "  Justfile failed to parse or 'lint' recipe missing."
    echo "Status: unavailable"
    echo "TOOLCHAIN_STATUS=unavailable" >&2
    echo "TOOLCHAIN_LANG=$LANG" >&2
    echo "TOOLCHAIN_MISSING=" >&2
    exit 0
  fi
fi

echo "Toolchain check ($display_lang):"

if [ "$LANG" = "generic" ]; then
  echo "  Generic template — every recipe fails loudly by design."
  echo "  Replace with a language-specific template from lib/templates/"
  echo "  or customize the recipes before running any 'just <recipe>'."
  echo "Status: fail-loudly"
  echo "TOOLCHAIN_STATUS=fail-loudly" >&2
  echo "TOOLCHAIN_LANG=generic" >&2
  echo "TOOLCHAIN_MISSING=" >&2
  exit 0
fi

if [ "$LANG" = "unknown" ]; then
  echo "  Could not detect language from Justfile header (line 1)."
  echo "  Expected: '# Bulwark Justfile Template - <Language>'"
  echo "Status: unavailable"
  echo "TOOLCHAIN_STATUS=unavailable" >&2
  echo "TOOLCHAIN_LANG=unknown" >&2
  echo "TOOLCHAIN_MISSING=" >&2
  exit 0
fi

TOOLS="$(tools_for_language "$LANG")"
MISSING=""

for tool in $TOOLS; do
  if ! check_tool "$tool"; then
    MISSING="${MISSING:+$MISSING,}$tool"
  fi
done

if [ -z "$MISSING" ]; then
  echo "Status: ready"
  echo "TOOLCHAIN_STATUS=ready" >&2
  echo "TOOLCHAIN_LANG=$LANG" >&2
  echo "TOOLCHAIN_MISSING=" >&2
else
  echo "Status: partial (missing: $MISSING)"
  echo "TOOLCHAIN_STATUS=partial" >&2
  echo "TOOLCHAIN_LANG=$LANG" >&2
  echo "TOOLCHAIN_MISSING=$MISSING" >&2
fi

# Always exit 0 — Part E is non-blocking by design.
exit 0
