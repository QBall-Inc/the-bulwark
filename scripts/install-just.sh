#!/bin/bash
# install-just.sh — platform-aware `just` installer for Bulwark.
#
# Usage:
#   # As a library (sources functions, no side effects):
#   source scripts/install-just.sh
#   install_just          # install if missing, exit 1 if all paths fail
#   detect_platform       # echo platform tag to stdout
#
#   # As a script (runs install_just directly):
#   ./scripts/install-just.sh
#
# Platforms detected:
#   macos-intel | macos-arm64 | wsl | linux-debian | linux-rhel
#   linux-other | windows-native | unknown
#
# Priority order per platform:
#   macOS:          brew → cargo
#   WSL/Debian:     cargo → apt-get (warn: apt is stale)
#   RHEL/Fedora:    cargo → dnf/yum
#   Linux-other:    cargo
#   Windows-native: winget → scoop → cargo
#
# On success: `just` is available on PATH (or ~/.cargo/bin/just with PATH note).
# On failure: prints actionable per-platform install message and exits 1.
#
# Does NOT use curl|bash patterns. Does NOT silently skip — exits 1 on all failures.

set -euo pipefail

# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------

detect_platform() {
  # Echoes one of: macos-intel | macos-arm64 | wsl | linux-debian | linux-rhel
  #                linux-other | windows-native | unknown
  #
  # Detection order:
  #   1. WSL must be checked BEFORE linux-debian — WSL Ubuntu has apt-get too.
  #   2. Darwin is unambiguous.
  #   3. Windows-native uses MINGW/CYGWIN/MSYS uname prefix.
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
# Cargo env sourcing — rustup writes ~/.cargo/env but non-interactive shells
# may not have sourced it. Attempt to pick it up before declaring cargo absent.
# ---------------------------------------------------------------------------

_ensure_cargo_on_path() {
  if command -v cargo >/dev/null 2>&1; then
    return 0
  fi
  if [ -f "$HOME/.cargo/env" ]; then
    # shellcheck disable=SC1091
    source "$HOME/.cargo/env" 2>/dev/null || true
  fi
  if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
  fi
  command -v cargo >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# Platform-specific install helpers
# ---------------------------------------------------------------------------

_install_just_macos() {
  if command -v brew >/dev/null 2>&1; then
    echo "  Installing just via Homebrew..."
    if brew install just; then
      return 0
    fi
    echo "  Homebrew install failed. Trying cargo fallback..."
    _install_just_cargo_only "macos"
    return
  fi

  echo ""
  echo "  WARNING: Homebrew is not installed."
  if _ensure_cargo_on_path; then
    echo "  Falling back to cargo install just..."
    _install_just_cargo_only "macos"
    return
  fi

  echo ""
  echo "  ERROR: Neither Homebrew nor Cargo (Rust) is installed."
  echo ""
  echo "  To install just on macOS, choose one:"
  echo "    Option 1 — Homebrew (recommended):"
  echo "      Install Homebrew: https://brew.sh"
  echo "      Then run: brew install just"
  echo ""
  echo "    Option 2 — Cargo (Rust):"
  echo "      Install Rust: https://rustup.rs"
  echo "      Then run: cargo install just"
  echo ""
  echo "  After installing, re-run: scripts/init.sh"
  exit 1
}

_install_just_linux_cargo_first() {
  local platform_hint="$1"

  if _ensure_cargo_on_path; then
    echo "  Installing just via cargo (current version, preferred over apt)..."
    echo "  This may take 60-120 seconds while just is compiled from source..."
    if cargo install just; then
      return 0
    fi
    echo "  cargo install failed. Trying apt-get fallback..."
    _install_just_apt "$platform_hint"
    return
  fi

  if command -v apt-get >/dev/null 2>&1; then
    echo ""
    echo "  WARNING: Rust/cargo not found. Falling back to apt-get."
    echo "  NOTE: The apt-get version of just may be significantly older than"
    echo "  the current release. If Justfile features fail, install Rust"
    echo "  (https://rustup.rs) and run: cargo install just"
    echo ""
    _install_just_apt "$platform_hint"
    return
  fi

  echo ""
  echo "  ERROR: Neither cargo (Rust) nor apt-get is available."
  _print_linux_install_instructions "$platform_hint"
  exit 1
}

_install_just_apt() {
  local platform_hint="$1"

  echo "  Installing just via apt-get (sudo required)..."

  if sudo -n true 2>/dev/null; then
    if sudo apt-get install -y just; then
      return 0
    fi
    echo "  apt-get install failed."
    _print_linux_install_instructions "$platform_hint"
    exit 1
  fi

  echo "  sudo password may be required..."
  if sudo apt-get install -y just; then
    return 0
  fi
  echo "  apt-get install failed (sudo denied or package unavailable)."
  _print_linux_install_instructions "$platform_hint"
  exit 1
}

_install_just_linux_rhel() {
  if _ensure_cargo_on_path; then
    echo "  Installing just via cargo (preferred over dnf/yum)..."
    echo "  This may take 60-120 seconds while just is compiled from source..."
    if cargo install just; then
      return 0
    fi
    echo "  cargo install failed. Trying dnf/yum fallback..."
  fi

  if command -v dnf >/dev/null 2>&1; then
    echo "  Installing just via dnf (sudo required)..."
    if sudo dnf install -y just; then
      return 0
    fi
  elif command -v yum >/dev/null 2>&1; then
    echo "  Installing just via yum (sudo required)..."
    if sudo yum install -y just; then
      return 0
    fi
  fi

  echo ""
  echo "  ERROR: All install attempts failed for RHEL/Fedora platform."
  _print_linux_install_instructions "rhel"
  exit 1
}

_install_just_cargo_only() {
  local platform_hint="$1"

  if _ensure_cargo_on_path; then
    echo "  Installing just via cargo..."
    echo "  This may take 60-120 seconds while just is compiled from source..."
    if cargo install just; then
      return 0
    fi
    echo ""
    echo "  ERROR: cargo install just failed."
    echo "  Check: disk space, build tools (gcc/clang), and network access."
    _print_linux_install_instructions "$platform_hint"
    exit 1
  fi

  echo ""
  echo "  ERROR: Rust/cargo is not installed and no package manager is available."
  _print_linux_install_instructions "$platform_hint"
  exit 1
}

_install_just_windows() {
  if command -v winget >/dev/null 2>&1 || cmd.exe /c "winget --version" >/dev/null 2>&1; then
    echo "  Installing just via winget..."
    if winget install --silent Casey.Just >/dev/null 2>&1 || \
       cmd.exe /c "winget install --silent Casey.Just" >/dev/null 2>&1; then
      echo "  Note: You may need to restart your terminal for 'just' to appear on PATH."
      return 0
    fi
    echo "  winget install failed. Trying scoop..."
  fi

  if command -v scoop >/dev/null 2>&1; then
    echo "  Installing just via scoop..."
    if scoop install just; then
      return 0
    fi
    echo "  scoop install failed. Trying cargo..."
  fi

  if _ensure_cargo_on_path; then
    echo "  Installing just via cargo..."
    echo "  This may take 60-120 seconds while just is compiled from source..."
    if cargo install just; then
      return 0
    fi
  fi

  echo ""
  echo "  ERROR: Could not install just on Windows. All paths failed."
  echo ""
  echo "  Manual install options:"
  echo "    Option 1 — winget (Windows 10 1709+):"
  echo "      Open PowerShell or CMD: winget install Casey.Just"
  echo ""
  echo "    Option 2 — Scoop:"
  echo "      Install Scoop: https://scoop.sh"
  echo "      Then run: scoop install just"
  echo ""
  echo "    Option 3 — Cargo (Rust):"
  echo "      Install Rust: https://rustup.rs"
  echo "      Then run: cargo install just"
  echo ""
  echo "  After installing, re-run: scripts/init.sh"
  exit 1
}

_print_linux_install_instructions() {
  local platform_hint="${1:-linux}"

  echo ""
  echo "  Manual install options:"
  echo ""
  echo "    Option 1 — Cargo (Rust, most portable, current version):"
  echo "      Install Rust: https://rustup.rs"
  echo "      Then run: cargo install just"
  echo ""

  if [ "$platform_hint" = "debian" ] || [ "$platform_hint" = "wsl" ]; then
    echo "    Option 2 — apt-get (Ubuntu 22.04+ only, older version):"
    echo "      sudo apt-get install -y just"
    echo "      Note: apt ships an older version. Prefer cargo for current Justfile features."
    echo ""
  elif [ "$platform_hint" = "rhel" ]; then
    echo "    Option 2 — dnf (Fedora 38+):"
    echo "      sudo dnf install -y just"
    echo ""
  fi

  echo "    Option 3 — Official releases: https://just.systems/man/en/chapter_4.html"
  echo ""
  echo "  After installing, re-run: scripts/init.sh"
}

# ---------------------------------------------------------------------------
# Main entry point
# ---------------------------------------------------------------------------

install_just() {
  # Early return if just already installed
  if command -v just >/dev/null 2>&1; then
    echo "  just is already installed: $(just --version)"
    return 0
  fi

  # Check common non-PATH location (cargo installs here)
  if [ -x "$HOME/.cargo/bin/just" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
    echo "  just found at ~/.cargo/bin/just: $(just --version)"
    echo "  Note: ~/.cargo/bin is not on your PATH. Add it to ~/.bashrc or ~/.zshrc:"
    echo "    export PATH=\"\$HOME/.cargo/bin:\$PATH\""
    return 0
  fi

  echo ""
  echo "  just is not installed. Attempting platform-aware install..."
  echo ""

  local platform
  platform="$(detect_platform)"
  echo "  Detected platform: $platform"

  case "$platform" in
    macos-intel|macos-arm64)
      _install_just_macos
      ;;
    wsl)
      echo "  WSL detected — using Linux install path (cargo preferred, apt fallback)"
      _install_just_linux_cargo_first "wsl"
      ;;
    linux-debian)
      _install_just_linux_cargo_first "debian"
      ;;
    linux-rhel)
      _install_just_linux_rhel
      ;;
    linux-other)
      _install_just_cargo_only "linux-other"
      ;;
    windows-native)
      _install_just_windows
      ;;
    unknown|*)
      echo ""
      echo "  ERROR: Could not detect platform (uname -s returned: $(uname -s))"
      echo ""
      echo "  Manual install options:"
      echo "    macOS:   brew install just"
      echo "    Linux:   cargo install just  (requires Rust toolchain)"
      echo "    Windows: winget install Casey.Just"
      echo "    All:     https://just.systems/man/en/chapter_4.html"
      exit 1
      ;;
  esac

  # Post-install verification — refresh PATH in case cargo installed to ~/.cargo/bin
  if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
  fi

  if command -v just >/dev/null 2>&1; then
    echo ""
    echo "  just installed successfully: $(just --version)"
    return 0
  fi

  if [ -x "$HOME/.cargo/bin/just" ]; then
    echo ""
    echo "  just installed at ~/.cargo/bin/just: $("$HOME/.cargo/bin/just" --version)"
    echo "  Add ~/.cargo/bin to your PATH to use just in new shells:"
    echo "    export PATH=\"\$HOME/.cargo/bin:\$PATH\""
    return 0
  fi

  echo ""
  echo "  ERROR: just install appeared to succeed but 'just' is not found."
  echo "  Try opening a new terminal and running: just --version"
  echo "  If still missing, install manually: https://just.systems/man/en/chapter_4.html"
  exit 1
}

# ---------------------------------------------------------------------------
# Execute install_just when this script is run directly (not sourced).
# ---------------------------------------------------------------------------

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  install_just
fi
