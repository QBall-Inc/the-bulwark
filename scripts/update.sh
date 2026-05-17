#!/bin/bash
# update.sh — UPDATE MODE drift detection helper
#
# Invoked from skills/init/SKILL.md Stage 9b (UPDATE MODE).
# Reads the .bulwark/init-marker.yaml, computes section-anchor diff between
# canonical templates and user files, writes a structured drift report.
#
# Usage:
#   bash update.sh --check --marker=PATH --plugin-root=PATH --output=PATH
#
# Output: YAML drift report at --output path. Exit 0 always (drift is data,
# not failure). Exit 1 only on hard errors (missing marker, malformed YAML,
# unwriteable output path).

set -euo pipefail

# --- Argument parsing ---

MARKER=""
PLUGIN_ROOT=""
OUTPUT=""
MODE=""

for arg in "$@"; do
  case "$arg" in
    --check)              MODE="check" ;;
    --marker=*)           MARKER="${arg#--marker=}" ;;
    --plugin-root=*)      PLUGIN_ROOT="${arg#--plugin-root=}" ;;
    --output=*)           OUTPUT="${arg#--output=}" ;;
    *)
      echo "ERROR: unknown argument '$arg'" >&2
      exit 1
      ;;
  esac
done

if [ "$MODE" != "check" ]; then
  echo "ERROR: --check is required (no other modes supported in v1.2.0)" >&2
  exit 1
fi

# --- SEC-007 env-var validation ---

[ -n "$MARKER" ]       || { echo "ERROR: --marker required" >&2; exit 1; }
[ -n "$PLUGIN_ROOT" ]  || { echo "ERROR: --plugin-root required" >&2; exit 1; }
[ -n "$OUTPUT" ]       || { echo "ERROR: --output required" >&2; exit 1; }

# Strip trailing slashes before traversal check (handles "/tmp/x/..//"
# bypass class — same fix as check-template-drift.sh SEC-CTD-001).
MARKER="${MARKER%/}"
PLUGIN_ROOT="${PLUGIN_ROOT%/}"
OUTPUT="${OUTPUT%/}"

case "$MARKER" in /*) ;; *) echo "ERROR: --marker must be absolute path" >&2; exit 1 ;; esac
case "$PLUGIN_ROOT" in /*) ;; *) echo "ERROR: --plugin-root must be absolute path" >&2; exit 1 ;; esac
case "$OUTPUT" in /*) ;; *) echo "ERROR: --output must be absolute path" >&2; exit 1 ;; esac

[ -f "$MARKER" ]      || { echo "ERROR: marker file not found: $MARKER" >&2; exit 1; }
[ -d "$PLUGIN_ROOT" ] || { echo "ERROR: plugin root not a directory: $PLUGIN_ROOT" >&2; exit 1; }

# Reject traversal in marker / plugin / output paths (defense in depth).
# SEC-UPD-004 hardening: OUTPUT was previously absoluteness-only — add traversal.
case "$MARKER"      in *../*|*..) echo "ERROR: marker path contains traversal" >&2; exit 1 ;; esac
case "$PLUGIN_ROOT" in *../*|*..) echo "ERROR: plugin root contains traversal" >&2; exit 1 ;; esac
case "$OUTPUT"      in *../*|*..) echo "ERROR: output path contains traversal" >&2; exit 1 ;; esac

# --- Parse marker ---
# Locked schema (matches scripts/init.sh writer):
#   scope_root: "/abs/path"
#   artifacts_written:
#     - path: "rel/path"
#       canonical: "rel/path/in/plugin"

SCOPE_ROOT=$(grep -E '^scope_root:' "$MARKER" 2>/dev/null | sed -E 's/^scope_root:[[:space:]]*"?([^"]*)"?[[:space:]]*$/\1/' | head -1)
[ -n "$SCOPE_ROOT" ] || { echo "ERROR: marker missing scope_root field" >&2; exit 1; }

# SEC-UPD-001 hardening: strip trailing slash + apply traversal guard.
SCOPE_ROOT="${SCOPE_ROOT%/}"
case "$SCOPE_ROOT" in /*) ;; *) echo "ERROR: marker scope_root not absolute" >&2; exit 1 ;; esac
case "$SCOPE_ROOT" in *../*|*..) echo "ERROR: marker scope_root contains traversal" >&2; exit 1 ;; esac
[ -d "$SCOPE_ROOT" ] || { echo "ERROR: marker scope_root does not exist: $SCOPE_ROOT" >&2; exit 1; }

MARKER_VERSION=$(grep -E '^version:' "$MARKER" 2>/dev/null | sed -E 's/^version:[[:space:]]*"?([^"]*)"?[[:space:]]*$/\1/' | head -1)
# SEC-UPD-002 trust note: PLUGIN_ROOT is caller-provided (skill context),
# NOT from the marker — safe to use directly without re-validation.
# TS-008: surface jq stderr if plugin.json is malformed (don't silently
# return "unknown"; that's a real failure worth seeing).
PLUGIN_VERSION=$(jq -r '.version // "unknown"' "$PLUGIN_ROOT/.claude-plugin/plugin.json" || echo "unknown")

# Extract artifacts_written entries (path / canonical pairs).
ARTIFACTS_TMP=$(mktemp 2>/dev/null) || { echo "ERROR: mktemp failed" >&2; exit 1; }
trap 'rm -f "$ARTIFACTS_TMP" 2>/dev/null' EXIT

# TS-004 hardening: explicit known-keys termination instead of /^[a-z_]+:/.
# If init.sh adds a field after artifacts_written (e.g., updated_at), the old
# pattern would silently end capture early. Known-keys list is single-source-
# of-truth with the marker schema in scripts/init.sh.
awk '
  /^artifacts_written:/ { in_artifacts = 1; next }
  /^(version|init_at|scope|scope_root|updated_at):/ && in_artifacts { in_artifacts = 0 }
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
' "$MARKER" > "$ARTIFACTS_TMP"

# --- Section-anchor extraction (per artifact-type, default markdown) ---
# Contract: returns SORTED -u output. comm depends on this.

extract_anchors_markdown() {
  local file="$1"
  [ -f "$file" ] || { echo ""; return 0; }
  # P10.24 hardening: strip trailing \r (CRLF defense — canonical templates may
  # ship CRLF on Windows/WSL checkouts; without strip, anchor names retain \r
  # and comm -23 reports false-positive drift for every section).
  grep -E '^(##|###) ' "$file" 2>/dev/null | sed -E 's/\r$//; s/^#+[[:space:]]+//' | sort -u
}

extract_anchors_justfile() {
  local file="$1"
  [ -f "$file" ] || { echo ""; return 0; }
  grep -E '^[a-zA-Z][a-zA-Z0-9_-]*:' "$file" 2>/dev/null | sed -E 's/^([a-zA-Z][a-zA-Z0-9_-]*):.*$/\1/' | sort -u
}

extract_anchors_for_artifact() {
  local file="$1"
  local basename
  basename=$(basename "$file")
  case "$basename" in
    Justfile) extract_anchors_justfile "$file" ;;
    *.md|CLAUDE.md|rules.md|Rules.md) extract_anchors_markdown "$file" ;;
    *) extract_anchors_markdown "$file" ;;  # default to markdown
  esac
}

# P10.25 hardening: parent->child relationship map for markdown canonicals.
# For every `### Child` header in the canonical file, emit a tab-separated
# `child_anchor<TAB>parent_anchor` line where parent is the most-recent
# `## Parent` header line-order-preceding the child. Used to suppress
# children from the drift list when their parent is also drifting (the
# parent's section extraction in apply-section.sh includes ### child
# bodies, so applying the parent brings children along for free).
#
# Without this suppression, a child anchor in MISSING with a parent also in
# MISSING produces BUG-S11-APPLY-001: child falls back to EOF append (parent
# absent from user file → predecessor lookup fails), then parent's
# canonical-position insert brings the same child body along, producing a
# visible orphaned duplicate. See plans/task-briefs/P10.25-* for full trace.
#
# Output is empty for non-markdown canonicals (Justfile has no
# parent-child header relationships — recipes are flat).
build_canonical_parent_map() {
  local file="$1"
  [ -f "$file" ] || { echo ""; return 0; }
  awk '
    { sub(/\r$/, "") }
    /^## / {
      parent = $0
      sub(/^#+[[:space:]]+/, "", parent)
      next
    }
    /^### / {
      child = $0
      sub(/^#+[[:space:]]+/, "", child)
      if (parent != "") {
        print child "\t" parent
      }
    }
  ' "$file"
}

extract_canonical_excerpt() {
  # Extract first 5 content lines after the anchor in the canonical file.
  # Stops only at same-depth-or-shallower headers (so child ### sub-headers
  # appear as excerpt content under a ## parent — informative, not noise).
  # TS-006 hardening: once we exit the section, do NOT re-enter on a duplicate
  # header (sticky in_section_done flag).
  # TS-003 hardening: indent excerpt lines with 10 spaces so they sit MORE
  # indented than the `canonical_excerpt: |` key (8-space indent in YAML
  # output) — required for valid YAML block scalars.
  local canonical="$1"
  local anchor="$2"
  awk -v anchor="$anchor" '
    BEGIN { in_section = 0; in_section_done = 0; depth = 0; printed = 0 }
    { sub(/\r$/, "") }   # P10.24 hardening: CRLF defense (see apply-section.sh)
    /^(##|###) / {
      stripped = $0
      sub(/^#+[ ]+/, "", stripped)
      if (stripped == anchor && !in_section_done) {
        in_section = 1
        if ($0 ~ /^### /) depth = 3
        else depth = 2
        next
      } else if (in_section) {
        if ($0 ~ /^## / || (depth == 3 && $0 ~ /^### /)) {
          in_section = 0
          in_section_done = 1
          exit
        }
      }
    }
    in_section && printed < 5 {
      print "          " $0
      printed++
    }
  ' "$canonical"
}

# --- Compute drift per artifact ---

mkdir -p "$(dirname "$OUTPUT")" 2>/dev/null || { echo "ERROR: cannot create output dir" >&2; exit 1; }

GENERATED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
TOTAL_DRIFT=0
ARTIFACT_COUNT=0
ARTIFACTS_BUF=""

while IFS=$'\t' read -r REL_PATH CANONICAL_REL; do
  [ -n "$REL_PATH" ] || continue
  [ -n "$CANONICAL_REL" ] || continue

  # Path-traversal guards (defense in depth — same as drift hook).
  case "$REL_PATH"       in /*|*../*|*..) continue ;; esac
  case "$CANONICAL_REL"  in /*|*../*|*..) continue ;; esac

  USER_FILE="$SCOPE_ROOT/$REL_PATH"
  CANONICAL_FILE="$PLUGIN_ROOT/$CANONICAL_REL"

  [ -f "$USER_FILE" ]      || continue
  [ -f "$CANONICAL_FILE" ] || continue

  USER_ANCHORS=$(extract_anchors_for_artifact "$USER_FILE")
  CANONICAL_ANCHORS=$(extract_anchors_for_artifact "$CANONICAL_FILE")

  # Sections in canonical, missing from user (one-way diff).
  # comm requires sorted input — extract_anchors* provides via sort -u.
  MISSING=$(comm -23 <(echo "$CANONICAL_ANCHORS") <(echo "$USER_ANCHORS") 2>/dev/null)

  # P10.25: parent-child anchor suppression (BUG-S11-APPLY-001 mitigation).
  # If both `## Parent` AND `### Parent.Child` are in MISSING, drop the child:
  # apply-section.sh's parent-section extraction includes ### children, so
  # applying the parent brings them along. Filter must run before the
  # `[ -z "$MISSING" ]` empty-guard so the artifact correctly skips when
  # everything got suppressed.
  if [ -n "$MISSING" ]; then
    PARENT_MAP=$(build_canonical_parent_map "$CANONICAL_FILE")
    if [ -n "$PARENT_MAP" ]; then
      FILTERED_MISSING=""
      while IFS= read -r ANCHOR; do
        [ -n "$ANCHOR" ] || continue
        # CR-SYN-001 hardening (two-part):
        # 1. Herestrings instead of `echo "$VAR" | cmd` — `echo` interprets values
        #    starting with `-e`/`-n`/`-E` as flags AND processes backslash escapes.
        # 2. `--` end-of-options on grep so $PARENT values starting with `-n`/`-x`/
        #    etc. don't get reparsed as grep flags. (Empirically caught by T11
        #    regression test: pre-fix grep ate `-n Workflow Stages` as the `-n` flag
        #    + a different pattern, breaking parent-child suppression on
        #    flag-prefixed anchors.)
        PARENT=$(awk -F'\t' -v child="$ANCHOR" '$1 == child { print $2; exit }' <<< "$PARENT_MAP")
        if [ -n "$PARENT" ] && grep -Fxq -- "$PARENT" <<< "$MISSING"; then
          continue  # child suppressed — parent will bring it along
        fi
        FILTERED_MISSING="${FILTERED_MISSING}${ANCHOR}"$'\n'
      done <<< "$MISSING"
      MISSING="${FILTERED_MISSING%$'\n'}"
    fi
  fi

  if [ -z "$MISSING" ]; then
    continue
  fi

  ARTIFACT_COUNT=$((ARTIFACT_COUNT + 1))

  # SEC-UPD-003 hardening: use SINGLE-QUOTED YAML strings to allow literal
  # backslashes (e.g., regex examples like `\d`, `\w` in anchor headers).
  # Double-quoted YAML strings only permit specific escape sequences
  # (\n, \t, \", \\) and reject `\d` etc. Single-quoted YAML only requires
  # doubling internal single-quotes (' → ''). This is safe for path-shaped
  # values from the user-modifiable marker AND for any anchor text from
  # canonical templates.
  REL_PATH_ESC="${REL_PATH//\'/\'\'}"
  CANONICAL_REL_ESC="${CANONICAL_REL//\'/\'\'}"

  ARTIFACTS_BUF="${ARTIFACTS_BUF}  - path: '${REL_PATH_ESC}'
    canonical: '${CANONICAL_REL_ESC}'
    drift_items:
"

  while IFS= read -r ANCHOR; do
    [ -n "$ANCHOR" ] || continue
    TOTAL_DRIFT=$((TOTAL_DRIFT + 1))
    EXCERPT=$(extract_canonical_excerpt "$CANONICAL_FILE" "$ANCHOR")
    ANCHOR_ESC="${ANCHOR//\'/\'\'}"
    ARTIFACTS_BUF="${ARTIFACTS_BUF}      - anchor: '${ANCHOR_ESC}'
        canonical_excerpt: |
${EXCERPT}
"
  done <<< "$MISSING"
done < "$ARTIFACTS_TMP"

# --- Write drift report ---

# SEC-UPD-005 hardening: atomic write via mktemp + mv -f
# (matches established project pattern from cleanup-review-registry.sh +
# apply-section.sh). Prevents partial-read race if init skill reads OUTPUT
# while update.sh is still computing ARTIFACTS_BUF.
REPORT_TMP=$(mktemp 2>/dev/null) || { echo "ERROR: mktemp failed" >&2; exit 1; }
trap 'rm -f "$REPORT_TMP" "$ARTIFACTS_TMP" 2>/dev/null' EXIT

{
  echo "# Drift report — generated by scripts/update.sh"
  # Use single-quoted YAML for all string values for the same reason as the
  # per-artifact entries above (backslash-tolerance + only ' needs escaping).
  GENERATED_AT_ESC="${GENERATED_AT//\'/\'\'}"
  MARKER_VERSION_ESC="${MARKER_VERSION//\'/\'\'}"
  PLUGIN_VERSION_ESC="${PLUGIN_VERSION//\'/\'\'}"
  SCOPE_ROOT_ESC="${SCOPE_ROOT//\'/\'\'}"
  echo "generated_at: '${GENERATED_AT_ESC}'"
  echo "marker_version: '${MARKER_VERSION_ESC}'"
  echo "plugin_version: '${PLUGIN_VERSION_ESC}'"
  echo "scope_root: '${SCOPE_ROOT_ESC}'"
  echo "total_drift_items: ${TOTAL_DRIFT}"
  echo "artifact_count: ${ARTIFACT_COUNT}"
  echo "artifacts:"
  printf '%s' "${ARTIFACTS_BUF}"
} > "$REPORT_TMP"

mv -f "$REPORT_TMP" "$OUTPUT"
trap 'rm -f "$ARTIFACTS_TMP" 2>/dev/null' EXIT

echo "Drift report written: $OUTPUT (total_drift_items=${TOTAL_DRIFT})"
exit 0
