#!/bin/bash
# install-bun.sh — platform-aware `bun` installer for Bulwark.
#
# bun is required for Bulwark eval-infrastructure runtime:
#   - skills/create-skill/scripts/run-loop.ts (eval loop runner)
#   - skills/create-skill/scripts/grade.ts (grader)
#   - Generated TS scripts in per-skill scripts/ directories (T-021)
#
# Usage:
#   # As a library (sources functions, no side effects):
#   source scripts/install-bun.sh
#   install_bun          # install if missing or < 1.0, exit 1 if all paths fail
#   detect_platform      # echo platform tag to stdout
#   verify_bun           # exit 0 if bun >= 1.0 on PATH, exit 1 otherwise
#
#   # As a script (runs install_bun directly):
#   ./scripts/install-bun.sh           # install (idempotent)
#   ./scripts/install-bun.sh --verify  # check only; no install
#   ./scripts/install-bun.sh --dry-run # print what would happen
#
# Platforms detected:
#   macos-intel | macos-arm64 | wsl | linux-debian | linux-rhel
#   linux-other | windows-native | unknown
#
# Priority order per platform:
#   macOS:          brew (oven-sh/bun/bun) → curl|bash (bun.sh/install)
#   Linux/WSL:      curl|bash (bun.sh/install)
#   Windows-native: powershell (bun.sh/install.ps1)
#
# On success: `bun` >= 1.0 is available on PATH (or $HOME/.bun/bin/bun with PATH note).
# On failure: prints actionable per-platform install message and exits 1.

set -euo pipefail

readonly BUN_MIN_MAJOR=1
readonly BUN_INSTALL_DIR="${BUN_INSTALL:-$HOME/.bun}"
readonly BUN_INSTALL_URL="https://bun.sh/install"

# ---------------------------------------------------------------------------
# Platform detection (parity with install-just.sh)
# ---------------------------------------------------------------------------

detect_platform() {
  local os
  os="$(uname -s)"

  case "$os" in
    Darwin)
      local arch
      arch="$(uname -m)"
      case "$arch" in
        arm64)  echo "macos-arm64" ;;
        x86_64) echo "macos-intel" ;;
        *)      echo "macos-intel" ;;
      esac
      ;;
    Linux)
      if grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
      elif command -v apt-get >/dev/null 2>&1 && [ -f /etc/debian_version ]; then
        echo "linux-debian"
      elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
        echo "linux-rhel"
      else
        echo "linux-other"
      fi
      ;;
    CYGWIN*|MINGW*|MSYS*)
      echo "windows-native"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Version probe — succeeds if bun >= BUN_MIN_MAJOR is on PATH or in $HOME/.bun/bin
# ---------------------------------------------------------------------------

_bun_major_version() {
  # Echo the integer major version of bun, or empty string if not installable.
  local bun_bin="$1"
  local version_str
  version_str="$("$bun_bin" --version 2>/dev/null || true)"
  if [ -z "$version_str" ]; then
    echo ""
    return 0
  fi
  # bun --version prints "1.0.30" or similar; strip everything after first dot.
  echo "${version_str%%.*}"
}

verify_bun() {
  local bun_bin=""

  if command -v bun >/dev/null 2>&1; then
    bun_bin="$(command -v bun)"
  elif [ -x "$BUN_INSTALL_DIR/bin/bun" ]; then
    bun_bin="$BUN_INSTALL_DIR/bin/bun"
  fi

  if [ -z "$bun_bin" ]; then
    return 1
  fi

  local major
  major="$(_bun_major_version "$bun_bin")"
  if [ -z "$major" ]; then
    return 1
  fi

  if [ "$major" -lt "$BUN_MIN_MAJOR" ]; then
    echo "  bun found at $bun_bin but version $($bun_bin --version) is below required $BUN_MIN_MAJOR.0" >&2
    return 1
  fi

  echo "  bun is installed: $($bun_bin --version) at $bun_bin"
  return 0
}

# ---------------------------------------------------------------------------
# PATH integration — bun installs into $HOME/.bun/bin by default. Append to
# user's shell rc (idempotent). Mirrors bun's own install script behavior but
# is explicit so we can verify across bash/zsh/fish.
# ---------------------------------------------------------------------------

_ensure_bun_on_path() {
  if command -v bun >/dev/null 2>&1; then
    return 0
  fi
  if [ -d "$BUN_INSTALL_DIR/bin" ]; then
    export PATH="$BUN_INSTALL_DIR/bin:$PATH"
  fi
  command -v bun >/dev/null 2>&1
}

_print_path_integration_note() {
  echo ""
  echo "  Note: bun installed to $BUN_INSTALL_DIR/bin"
  echo "  bun's installer typically appends PATH lines to your shell rc."
  echo "  If 'bun' is not found in a new shell, add this line to ~/.bashrc or ~/.zshrc:"
  echo "    export BUN_INSTALL=\"\$HOME/.bun\""
  echo "    export PATH=\"\$BUN_INSTALL/bin:\$PATH\""
  echo ""
  echo "  For fish, add to ~/.config/fish/config.fish:"
  echo "    set -gx BUN_INSTALL \"\$HOME/.bun\""
  echo "    set -gx PATH \"\$BUN_INSTALL/bin\" \$PATH"
}

# ---------------------------------------------------------------------------
# Platform-specific install helpers
# ---------------------------------------------------------------------------

_install_bun_macos() {
  if command -v brew >/dev/null 2>&1; then
    echo "  Installing bun via Homebrew..."
    if brew install oven-sh/bun/bun; then
      return 0
    fi
    echo "  Homebrew install failed. Trying curl|bash fallback..."
  fi

  _install_bun_curl
}

_install_bun_curl() {
  if ! command -v curl >/dev/null 2>&1; then
    echo ""
    echo "  ERROR: curl is required to install bun via the official installer."
    echo ""
    echo "  Manual install options:"
    echo "    macOS:   brew install oven-sh/bun/bun"
    echo "    Linux:   Install curl, then re-run this script"
    echo "    Or visit: https://bun.sh/docs/installation"
    exit 1
  fi

  echo "  Installing bun via official installer (curl $BUN_INSTALL_URL | bash)..."
  echo "  This downloads and runs bun's official installer from bun.sh."

  if curl -fsSL "$BUN_INSTALL_URL" | bash; then
    _print_path_integration_note
    return 0
  fi

  echo ""
  echo "  ERROR: bun install via $BUN_INSTALL_URL failed."
  echo "  Check: network access, disk space at $BUN_INSTALL_DIR."
  echo "  See https://bun.sh/docs/installation for manual options."
  exit 1
}

_install_bun_windows() {
  echo ""
  echo "  Windows-native bun install requires PowerShell."
  echo "  Run this in PowerShell (not bash):"
  echo "    powershell -c \"irm bun.sh/install.ps1 | iex\""
  echo ""
  echo "  Or use WSL for the bash install path."
  exit 1
}

# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

install_bun() {
  # Early return — version probe (AC-P10.11-4: skip install if bun >= 1.0 on PATH)
  if verify_bun; then
    return 0
  fi

  echo ""
  echo "  bun is not installed (or version is below required $BUN_MIN_MAJOR.0)."
  echo "  Attempting platform-aware install..."
  echo ""

  local platform
  platform="$(detect_platform)"
  echo "  Detected platform: $platform"

  case "$platform" in
    macos-intel|macos-arm64)
      _install_bun_macos
      ;;
    wsl|linux-debian|linux-rhel|linux-other)
      _install_bun_curl
      ;;
    windows-native)
      _install_bun_windows
      ;;
    unknown|*)
      echo ""
      echo "  ERROR: Could not detect platform (uname -s returned: $(uname -s))"
      echo ""
      echo "  Manual install options:"
      echo "    macOS:   brew install oven-sh/bun/bun"
      echo "    Linux:   curl -fsSL https://bun.sh/install | bash"
      echo "    Windows: powershell -c \"irm bun.sh/install.ps1 | iex\""
      echo "    Docs:    https://bun.sh/docs/installation"
      exit 1
      ;;
  esac

  # Post-install verification — bun's installer adds $HOME/.bun/bin to PATH for
  # NEW shells; in the CURRENT shell we must source it ourselves.
  if _ensure_bun_on_path && verify_bun; then
    return 0
  fi

  echo ""
  echo "  ERROR: bun install appeared to succeed but 'bun' is not found at expected location."
  echo "  Expected: $BUN_INSTALL_DIR/bin/bun"
  echo "  Try opening a new terminal and running: bun --version"
  echo "  If still missing, install manually: https://bun.sh/docs/installation"
  exit 1
}

# ---------------------------------------------------------------------------
# CLI dispatch — handle --verify and --dry-run flags
# ---------------------------------------------------------------------------

_main() {
  local mode="install"
  while [ $# -gt 0 ]; do
    case "$1" in
      --verify) mode="verify" ;;
      --dry-run) mode="dry-run" ;;
      --help|-h)
        sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
        exit 0
        ;;
      *)
        echo "Unknown argument: $1" >&2
        echo "Usage: $0 [--verify|--dry-run|--help]" >&2
        exit 2
        ;;
    esac
    shift
  done

  case "$mode" in
    verify)
      if verify_bun; then
        exit 0
      fi
      echo "  bun is NOT installed (or version below $BUN_MIN_MAJOR.0)" >&2
      exit 1
      ;;
    dry-run)
      local platform
      platform="$(detect_platform)"
      echo "  Platform detected: $platform"
      if verify_bun; then
        echo "  Action: no-op (bun already installed)"
      else
        case "$platform" in
          macos-intel|macos-arm64)
            echo "  Action: brew install oven-sh/bun/bun (with curl|bash fallback)"
            ;;
          wsl|linux-debian|linux-rhel|linux-other)
            echo "  Action: curl -fsSL $BUN_INSTALL_URL | bash"
            ;;
          windows-native)
            echo "  Action: print PowerShell instructions (cannot install from bash on Windows-native)"
            ;;
          *)
            echo "  Action: ERROR — unknown platform"
            ;;
        esac
      fi
      exit 0
      ;;
    install)
      install_bun
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Execute when run directly (not sourced).
# ---------------------------------------------------------------------------

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  _main "$@"
fi
