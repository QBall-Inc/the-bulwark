#!/bin/bash
# bulwark-permission-hook.sh - PreToolUse permission-bypass for Bulwark bundled assets
#
# OPT-IN, DEFAULT OFF. Auto-approves Read/Edit/Bash operations whose target
# resolves INSIDE a Bulwark plugin root, and passes through (no opinion) for
# everything else. A scoped workaround for upstream CC permission-prompt bugs
# on plugin-bundled assets the user already trusted at install time.
#
# Design + safety model: docs/internal/p10.8-hook-design.md
# Brief:                 plans/task-briefs/P10.8-pretooluse-hook-permission-bypass.md
#
# Event:   PreToolUse, matcher "Read|Edit|Bash"
# stdin:   PreToolUse event JSON (.tool_name, .tool_input.file_path | .command)
# stdout:  hookSpecificOutput JSON for allow/deny; EMPTY for pass-through (defer)
# exit:    always 0 — decisions are expressed in JSON, never via exit 2
#
# Decision model (all on the CANONICAL path, never the literal string):
#   - target canonically under a plugin root        -> allow
#   - target CLAIMS a plugin root but escapes it     -> deny (anti-spoof)
#   - anything else                                  -> pass-through (defer)
# Bash is the highest-risk surface: only SIMPLE commands (no shell
# metacharacters) whose every path token sits under a plugin root are allowed.
# Write is intentionally NOT matched -> writes always keep CC's default prompt.
#
# Opt-in gate (default OFF), CONTEXT-AWARE so default-OFF never depends on CC
#   exporting a userConfig default:
#   - Plugin context ($CLAUDE_PLUGIN_ROOT set — installed plugin or --plugin-dir):
#     require an EXPLICIT $CLAUDE_PLUGIN_OPTION_ENABLE_PERMISSION_BYPASS=true;
#     unset / "false" / anything-else -> inert (fail-safe OFF). The plugin's
#     userConfig.enable_permission_bypass (default false) drives this — and even
#     if CC omits the var for an unchanged default, the hook stays OFF.
#   - Project/scaffold context ($CLAUDE_PLUGIN_ROOT unset): the hook's presence
#     in the project's .claude/settings.json IS the opt-in, so an UNSET var is
#     active; an explicit "false" still disables it.
#
# Portability: prefers GNU `realpath -m`; falls back to a pure-bash lexical
#   `..`/`.` normalizer (no filesystem access) so behavior is identical on
#   WSL/Linux/macOS. Canonicalization is fail-safe: a path it cannot resolve
#   to an absolute form never matches a root (so it is never auto-approved).
#
# Usage: invoked by Claude Code as a PreToolUse hook; not run directly.

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Opt-in gate (default OFF) — context-aware (see header)
# ─────────────────────────────────────────────────────────────────────────────
GATE="${CLAUDE_PLUGIN_OPTION_ENABLE_PERMISSION_BYPASS-__unset__}"
if [ -n "${CLAUDE_PLUGIN_ROOT-}" ]; then
  # Plugin context: default-OFF must NOT depend on CC exporting the userConfig
  # default, so require an EXPLICIT opt-in. unset/false/unknown -> inert.
  case "$GATE" in
    true|1|yes|on) : ;;
    *) exit 0 ;;
  esac
else
  # Project/scaffold context: presence in .claude/settings.json IS the opt-in,
  # so an UNSET gate is active; an explicit "false" still disables.
  case "$GATE" in
    __unset__|true|1|yes|on) : ;;
    *) exit 0 ;;
  esac
fi

# ─────────────────────────────────────────────────────────────────────────────
# Decision emitters
# ─────────────────────────────────────────────────────────────────────────────
emit_allow() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}

emit_deny() {
  log_deny "$1" "${2:-}"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$1"
  exit 0
}

# Deny is rare and security-relevant -> log it (allows/pass-throughs are hot-path,
# not logged). Fully non-fatal; only appends if a logs/ dir already exists.
log_deny() {
  local reason="$1" detail="$2"
  local logdir="${CLAUDE_PROJECT_DIR:-.}/logs"
  [ -d "$logdir" ] || return 0
  # Sanitize the user-influenced detail before appending to the shared log:
  # strip CR/LF (prevents log-line spoofing) and bound length (SEC-SUG-1).
  detail="${detail//$'\n'/ }"
  detail="${detail//$'\r'/ }"
  detail="${detail:0:500}"
  printf '[%s] PreToolUse bulwark-permission-hook: DENY %s (%s)\n' \
    "$(date -Iseconds 2>/dev/null || echo now)" "$reason" "$detail" \
    >> "$logdir/hooks.log" 2>/dev/null || true
}

# ─────────────────────────────────────────────────────────────────────────────
# Path expansion + canonicalization
# ─────────────────────────────────────────────────────────────────────────────

# Expand a leading ~ and any literal $HOME / $CLAUDE_PLUGIN_ROOT tokens the
# Bash command string may carry unexpanded.
expand_path() {
  local p="$1"
  # Match a LITERAL leading tilde in the input and expand it ourselves; tildes
  # must NOT shell-expand inside these case patterns (SC2088 here is intentional).
  # shellcheck disable=SC2088
  case "$p" in
    "~")    p="${HOME:-}" ;;
    "~/"*)  p="${HOME:-}/${p#"~/"}" ;;
  esac
  p="${p//\$\{CLAUDE_PLUGIN_ROOT\}/${CLAUDE_PLUGIN_ROOT:-}}"
  p="${p//\$CLAUDE_PLUGIN_ROOT/${CLAUDE_PLUGIN_ROOT:-}}"
  p="${p//\$\{HOME\}/${HOME:-}}"
  p="${p//\$HOME/${HOME:-}}"
  printf '%s' "$p"
}

# Pure-bash lexical resolution of . and .. — no filesystem access, portable.
# Only normalizes ABSOLUTE paths; a relative path is returned unchanged so it
# can never match an absolute root (fail-safe).
lexical_normalize() {
  local path="$1"
  case "$path" in
    /*) ;;
    *) printf '%s' "$path"; return 0 ;;
  esac
  local IFS='/' seg
  local -a parts=() out=()
  read -ra parts <<< "$path" || true
  for seg in "${parts[@]}"; do
    case "$seg" in
      ''|'.') ;;                                   # drop empty + current-dir
      '..') [ "${#out[@]}" -gt 0 ] && unset 'out[${#out[@]}-1]' && out=("${out[@]}") ;;
      *) out+=("$seg") ;;
    esac
  done
  local result=""
  for seg in "${out[@]}"; do result="$result/$seg"; done
  [ -n "$result" ] || result="/"
  printf '%s' "$result"
}

# Canonicalize an absolute path (resolve .. and, when realpath is available,
# symlinks). Relative paths are returned unchanged (never match a root).
canonicalize() {
  local p="$1" out
  case "$p" in
    /*) ;;
    *) printf '%s' "$p"; return 0 ;;
  esac
  if out=$(realpath -m -- "$p" 2>/dev/null) && [ -n "$out" ]; then
    printf '%s' "$out"; return 0
  fi
  lexical_normalize "$p"
}

# ─────────────────────────────────────────────────────────────────────────────
# Root membership (operate on canonical paths only)
# ─────────────────────────────────────────────────────────────────────────────

# True if canonical path lives under ~/.claude/plugins/cache/<owner>/the-bulwark[-*]/...
# Version-agnostic by design (#15642): the version segment is below the plugin dir.
is_under_cache_root() {
  local cp="$1" suffix owner rest plugin
  case "$cp" in
    *"/.claude/plugins/cache/"*) ;;
    *) return 1 ;;
  esac
  suffix="${cp#*"/.claude/plugins/cache/"}"   # owner/plugin/version/...
  owner="${suffix%%/*}"
  [ -n "$owner" ] && [ "$owner" != "$suffix" ] || return 1
  rest="${suffix#*/}"
  plugin="${rest%%/*}"
  case "$plugin" in
    the-bulwark|the-bulwark-*) return 0 ;;
  esac
  return 1
}

# True if canonical path lives under the dev plugin root ($CLAUDE_PLUGIN_ROOT, for --plugin-dir).
is_under_dev_root() {
  local cp="$1" droot
  [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] || return 1
  droot="$(canonicalize "$CLAUDE_PLUGIN_ROOT")"
  [ -n "$droot" ] || return 1
  case "$cp" in
    "$droot"|"$droot"/*) return 0 ;;
  esac
  return 1
}

is_under_root() {
  is_under_cache_root "$1" || is_under_dev_root "$1"
}

# True if the RAW (pre-canonical) string references a plugin marker — used to
# tell a traversal-spoof (deny) apart from an unrelated path (pass-through).
claims_root() {
  local raw="$1"
  case "$raw" in
    *".claude/plugins/cache/"*"the-bulwark"*) return 0 ;;
  esac
  # Match the literal, unexpanded $CLAUDE_PLUGIN_ROOT token a raw command may
  # carry; single quotes are intentional (SC2016 expected — we match literals).
  # shellcheck disable=SC2016
  case "$raw" in
    *'${CLAUDE_PLUGIN_ROOT}'*|*'$CLAUDE_PLUGIN_ROOT'*) return 0 ;;
  esac
  if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
    case "$raw" in
      *"$CLAUDE_PLUGIN_ROOT"*) return 0 ;;
    esac
  fi
  return 1
}

# ─────────────────────────────────────────────────────────────────────────────
# Decision logic
# ─────────────────────────────────────────────────────────────────────────────

# Read / Edit: decide on the single file path.
decide_path() {
  local raw="$1" canon
  canon="$(canonicalize "$(expand_path "$raw")")"
  if [ -n "$canon" ] && is_under_root "$canon"; then
    emit_allow "bulwark-bundled-asset"
  elif claims_root "$raw"; then
    emit_deny "path escapes the Bulwark plugin root" "$raw"
  fi
  exit 0   # pass-through
}

# Bash: most conservative. Reject anything we cannot reason about simply, then
# auto-approve ONLY a "run a plugin script" shape: the command verb is itself a
# plugin-script path (direct exec) OR a bare bash/sh interpreter, AND every
# path-like token sits under a plugin root. A non-script verb on a plugin path
# (e.g. `rm <plugin-file>`) is NOT auto-approved — it falls through to CC's
# default prompt (CR-SUG-1).
decide_bash() {
  local cmd="$1" expanded tok canon verb
  # Literal shell metacharacters; single quotes are intentional (SC2016 expected).
  # shellcheck disable=SC2016
  case "$cmd" in
    *'&&'*|*'||'*|*';'*|*'|'*|*'$('*|*'`'*|*'>'*|*'<'*|*'&'*|*$'\n'*)
      exit 0 ;;   # compound / pipe / subshell / redirect / background -> pass-through
  esac
  expanded="$(expand_path "$cmd")"
  # Word-split WITHOUT globbing (read -ra, default IFS) so a literal '*' in the
  # command is never pathname-expanded during inspection. A path token containing
  # spaces won't match a root cleanly -> falls through to pass-through (SEC-SUG-3).
  local -a toks=()
  read -ra toks <<< "$expanded" || true
  [ "${#toks[@]}" -gt 0 ] || exit 0
  # Command verb must be a plugin script (direct exec) or a bare bash/sh interpreter.
  verb="${toks[0]}"
  local verb_ok=0
  case "$verb" in
    bash|sh) verb_ok=1 ;;
    */*)
      canon="$(canonicalize "$verb")"
      if [ -n "$canon" ] && is_under_root "$canon"; then verb_ok=1; fi
      ;;
  esac
  local has_plugin_token=0 has_escape=0 has_external=0
  for tok in "${toks[@]}"; do
    case "$tok" in
      */*) ;;          # path-like token
      *) continue ;;   # flags / bare words -> ignore
    esac
    canon="$(canonicalize "$tok")"
    if [ -n "$canon" ] && is_under_root "$canon"; then
      has_plugin_token=1
    elif claims_root "$tok"; then
      has_escape=1
    else
      has_external=1
    fi
  done
  if [ "$has_escape" -eq 1 ]; then
    emit_deny "command path escapes the Bulwark plugin root" "$cmd"
  elif [ "$verb_ok" -eq 1 ] && [ "$has_plugin_token" -eq 1 ] && [ "$has_external" -eq 0 ]; then
    emit_allow "bulwark-bundled-script"
  fi
  exit 0   # pass-through
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────
INPUT="$(cat)"
TOOL="$(printf '%s' "$INPUT" | jq -r '.tool_name // ""')"

case "$TOOL" in
  Read|Edit)
    FP="$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // ""')"
    [ -n "$FP" ] || exit 0
    decide_path "$FP"
    ;;
  Bash)
    CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // ""')"
    [ -n "$CMD" ] || exit 0
    decide_bash "$CMD"
    ;;
  *)
    exit 0   # not a tool this hook decides on
    ;;
esac
