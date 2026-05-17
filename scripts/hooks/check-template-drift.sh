#!/bin/bash
# check-template-drift.sh — SessionStart hook
#
# Detects drift between Bulwark's canonical templates (in the installed plugin)
# and the user's project copies of CLAUDE.md / rules.md / Justfile / statusline
# config that were written by /the-bulwark:init.
#
# If drift is detected, emits a one-line additionalContext suggesting
# /the-bulwark:init --update. The skill UPDATE MODE handles per-section review
# and application interactively.
#
# Marker-gated: silent skip when .bulwark/init-marker.yaml is absent. This
# prevents false-positive drift reports for projects that have a hand-rolled
# Rules.md unrelated to Bulwark templates.
#
# Section-anchor based diff: compares rule IDs (e.g., ### SD1:) and section
# headers (e.g., ## Spec Drift Rules (SD)) for PRESENCE, not literal text.
# User customizations within sections are NEVER touched.
#
# Performance: ~90ms typical, ~300ms worst-case. Under existing SessionStart
# chain budget. Last in chain (informational, after governance + cleanup hooks).

set -euo pipefail

# --- SEC-007 env-var validation (parity with cleanup-stale.sh) ---

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
case "$PROJECT_DIR" in
  /*) ;;
  *) exit 0 ;;
esac
[ -d "$PROJECT_DIR" ] || exit 0

# --- Plugin root resolution ---

PLUGIN_DIR="${CLAUDE_PLUGIN_ROOT:-}"
if [ -z "$PLUGIN_DIR" ] || [ ! -d "$PLUGIN_DIR" ]; then
  # Plugin root not resolvable — silent skip. Hook only operates when Bulwark
  # is installed as a plugin (--plugin-dir or marketplace install).
  exit 0
fi

# --- Marker-gated skip ---
# If .bulwark/init-marker.yaml is absent, this project was either:
#   (a) never Bulwark-initialized, OR
#   (b) Bulwark-initialized pre-v1.2.0 (before the marker existed).
# Either way: silent skip. The user can run /the-bulwark:init --update which
# handles backward-compat (offers to write the marker on first run).

MARKER_PATH="${PROJECT_DIR}/.bulwark/init-marker.yaml"
[ -f "$MARKER_PATH" ] || exit 0

# --- Section-anchor extraction helper ---
# Extracts ## and ### headers (with text) from a markdown file. Used to compare
# section presence, not content. User edits within sections are not flagged.
#
# CONTRACT (cross-file with scripts/update.sh): returns SORTED -u output.
# Downstream `comm -23` REQUIRES sorted input. Do not remove `sort -u`.

extract_anchors() {
  local file="$1"
  [ -f "$file" ] || { echo ""; return 0; }
  # P10.24 hardening: strip trailing \r (CRLF defense — canonical templates may
  # ship CRLF on Windows/WSL checkouts; without strip, anchor names retain \r
  # and comm -23 reports false-positive drift for every section).
  grep -E '^(##|###) ' "$file" 2>/dev/null | sed -E 's/\r$//; s/^#+[[:space:]]+//' | sort -u
}

# Sed-grep YAML parser (sufficient for our locked schema).
# Marker schema (per scripts/init.sh):
#   scope_root: "<absolute path>"
#   artifacts_written:
#     - path: "<relative-to-scope_root>"
#       canonical: "<relative-to-plugin-root>"
SCOPE_ROOT=$(grep -E '^scope_root:' "$MARKER_PATH" 2>/dev/null | sed -E 's/^scope_root:[[:space:]]*"?([^"]*)"?[[:space:]]*$/\1/' | head -1)
[ -n "$SCOPE_ROOT" ] || exit 0

# SEC-007: SCOPE_ROOT comes from a user-modifiable marker. Apply absoluteness
# guard matching cleanup-stale.sh + cleanup-review-registry.sh pattern. Reject
# relative paths and traversal sequences silently — drift detection is best-
# effort and a malformed marker should never be a hard error.
# SEC-CTD-001 hardening: strip trailing slash before traversal check (handles
# bypass like "/tmp/x/..//" which would otherwise pass both case arms).
SCOPE_ROOT="${SCOPE_ROOT%/}"
case "$SCOPE_ROOT" in
  /*) ;;
  *) exit 0 ;;
esac
case "$SCOPE_ROOT" in
  *../*|*..) exit 0 ;;
esac
[ -d "$SCOPE_ROOT" ] || exit 0

# Extract path/canonical pairs. Each artifact entry is a YAML mapping
# under artifacts_written. We collect paired lines.
ARTIFACTS_TMP=$(mktemp 2>/dev/null)
if [ -z "${ARTIFACTS_TMP:-}" ]; then
  # SYNTH-004 hardening: mktemp failure (e.g., /tmp exhausted) is observable.
  TIMESTAMP=$(date -Iseconds)
  HOOKS_LOG="${PROJECT_DIR}/logs/hooks.log"
  mkdir -p "$(dirname "$HOOKS_LOG")" 2>/dev/null || true
  echo "[${TIMESTAMP}] SessionStart: check-template-drift — mktemp failed; skipping drift detection" >> "$HOOKS_LOG" 2>/dev/null || true
  exit 0
fi
trap 'rm -f "$ARTIFACTS_TMP" 2>/dev/null' EXIT

awk '
  /^artifacts_written:/ { in_artifacts = 1; next }
  /^[a-z_]+:/ && in_artifacts { in_artifacts = 0 }
  in_artifacts && /^[[:space:]]*-[[:space:]]*path:/ {
    match($0, /"[^"]+"/);
    p = substr($0, RSTART+1, RLENGTH-2);
    next_path = p;
  }
  in_artifacts && /^[[:space:]]*canonical:/ {
    match($0, /"[^"]+"/);
    c = substr($0, RSTART+1, RLENGTH-2);
    if (next_path != "") {
      print next_path "\t" c;
      next_path = "";
    }
  }
' "$MARKER_PATH" > "$ARTIFACTS_TMP"

# --- Per-artifact drift detection ---

TOTAL_DRIFT=0
DRIFT_SUMMARY=""

while IFS=$'\t' read -r REL_PATH CANONICAL_REL; do
  [ -n "$REL_PATH" ] || continue
  [ -n "$CANONICAL_REL" ] || continue

  # SYNTH-002/003 + SEC-CTD-002 hardening: REL_PATH and CANONICAL_REL come
  # from a user-modifiable marker. Strip trailing slash first (handles the
  # "subdir/../" bypass), then reject absolute paths and traversal sequences.
  REL_PATH="${REL_PATH%/}"
  CANONICAL_REL="${CANONICAL_REL%/}"
  case "$REL_PATH" in /*|*../*|*..) continue ;; esac
  case "$CANONICAL_REL" in /*|*../*|*..) continue ;; esac

  USER_FILE="$SCOPE_ROOT/$REL_PATH"
  CANONICAL_FILE="$PLUGIN_DIR/$CANONICAL_REL"

  # Skip silently if either file is missing — not our error to report.
  [ -f "$USER_FILE" ] || continue
  [ -f "$CANONICAL_FILE" ] || continue

  USER_ANCHORS=$(extract_anchors "$USER_FILE")
  CANONICAL_ANCHORS=$(extract_anchors "$CANONICAL_FILE")

  # Sections present in canonical but missing from user file.
  # comm -23 requires sorted input — extract_anchors guarantees `sort -u`
  # in the pipeline (TS-007 contract pin).
  MISSING=$(comm -23 <(echo "$CANONICAL_ANCHORS") <(echo "$USER_ANCHORS") 2>/dev/null)
  if [ -n "$MISSING" ]; then
    MISSING_COUNT=$(echo "$MISSING" | grep -c .)
    TOTAL_DRIFT=$((TOTAL_DRIFT + MISSING_COUNT))
    DRIFT_SUMMARY="${DRIFT_SUMMARY}${REL_PATH}: ${MISSING_COUNT}; "
  fi
done < "$ARTIFACTS_TMP"

# --- Emit additionalContext if drift detected ---

if [ "$TOTAL_DRIFT" -eq 0 ]; then
  exit 0
fi

# Hooks log (observability, parity with cleanup hooks).
TIMESTAMP=$(date -Iseconds)
HOOKS_LOG="${PROJECT_DIR}/logs/hooks.log"
mkdir -p "$(dirname "$HOOKS_LOG")" 2>/dev/null || true
echo "[${TIMESTAMP}] SessionStart: check-template-drift — ${TOTAL_DRIFT} section(s) missing across user files (${DRIFT_SUMMARY%; })" >> "$HOOKS_LOG" 2>/dev/null || true

# additionalContext payload — surfaces drift to Claude's context.
# jq is required (universally available in supported Bulwark environments).
# SEC-CTD-003 hardening: removed plain-echo fallback whose interpolation could
# malform JSON if DRIFT_SUMMARY ever included non-path-shaped content.
if ! command -v jq >/dev/null 2>&1; then
  echo "[${TIMESTAMP}] SessionStart: check-template-drift — jq missing; cannot emit additionalContext (drift count was ${TOTAL_DRIFT})" >> "$HOOKS_LOG" 2>/dev/null || true
  exit 0
fi

jq -n --arg n "$TOTAL_DRIFT" --arg summary "${DRIFT_SUMMARY%; }" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: ("Bulwark template drift detected: " + $n + " section(s) missing in your installed config files (" + $summary + "). Run /the-bulwark:init --update to review and apply.")
  }
}'

exit 0
