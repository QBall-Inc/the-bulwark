#!/bin/bash
# apply-section.sh — Insert a single canonical section into a user file
#
# Invoked from skills/init/SKILL.md Stage 9d (UPDATE MODE) per Accept decision.
# Position-aware: scans canonical for the section's predecessor anchor and
# inserts after the matching predecessor in the user file. Falls back to
# end-of-file append if predecessor not found.
#
# Atomic write: writes to temp + mv -f. Never edits in place.
#
# Usage:
#   bash apply-section.sh --target=USER_FILE --canonical=CANONICAL_FILE --anchor='Section Name'
#
# Exit 0 on success; exit 1 on any error (missing files, permission denied,
# malformed input). Caller (UPDATE MODE) MUST treat exit 1 as STOP — partial
# writes to user files are not acceptable.

set -euo pipefail

# --- Argument parsing ---

TARGET=""
CANONICAL=""
ANCHOR=""

for arg in "$@"; do
  case "$arg" in
    --target=*)     TARGET="${arg#--target=}" ;;
    --canonical=*)  CANONICAL="${arg#--canonical=}" ;;
    --anchor=*)     ANCHOR="${arg#--anchor=}" ;;
    *)
      echo "ERROR: unknown argument '$arg'" >&2
      exit 1
      ;;
  esac
done

[ -n "$TARGET" ]    || { echo "ERROR: --target required" >&2; exit 1; }
[ -n "$CANONICAL" ] || { echo "ERROR: --canonical required" >&2; exit 1; }
[ -n "$ANCHOR" ]    || { echo "ERROR: --anchor required" >&2; exit 1; }

# SEC-007 absoluteness + traversal guards.
# SEC-APS-003 hardening: strip trailing slash before traversal check
# (handles "/trusted/.." bypass class — same fix as check-template-drift.sh).
TARGET="${TARGET%/}"
CANONICAL="${CANONICAL%/}"
case "$TARGET"    in /*) ;; *) echo "ERROR: --target must be absolute path" >&2; exit 1 ;; esac
case "$CANONICAL" in /*) ;; *) echo "ERROR: --canonical must be absolute path" >&2; exit 1 ;; esac
case "$TARGET"    in *../*|*..) echo "ERROR: --target contains traversal" >&2; exit 1 ;; esac
case "$CANONICAL" in *../*|*..) echo "ERROR: --canonical contains traversal" >&2; exit 1 ;; esac

[ -f "$TARGET" ]    || { echo "ERROR: target file not found: $TARGET" >&2; exit 1; }
[ -f "$CANONICAL" ] || { echo "ERROR: canonical file not found: $CANONICAL" >&2; exit 1; }

# Reject if target is a symlink — atomic mv would replace the symlink with a
# regular file, surprising the user. Force them to resolve first.
if [ -L "$TARGET" ]; then
  echo "ERROR: target is a symlink ($TARGET) — resolve to canonical path first" >&2
  exit 1
fi

# --- Extract canonical section content ---
# Section spans from the anchor line through the next same-or-shallower header
# (or EOF). For ## anchors, section ends at next ##. For ### anchors, ends at
# next ## or ###.

# TS-006 hardening: in_section_done sticky flag prevents re-entry on a
# duplicate header further down the file (rare but possible — e.g., user
# template with two `### Foo` headers under different parents).
# TS-005 hardening: write to a TEMP FILE instead of capturing via $() —
# bash command-substitution strips trailing newlines, dropping intentional
# blank-line separators at section end.
# P10.24 hardening: each of the three awk blocks in this script (this
# function + PREDECESSOR + PRED_END) starts with `{ sub(/\r$/, "") }` —
# a POSIX-portable CRLF defense. Canonical templates may ship with CRLF
# line terminators on Windows/WSL checkouts; without this, the
# `stripped == anchor` string comparison fails silently because $0 has
# a trailing \r the anchor doesn't. See P10.24 brief for the empirical
# bug report (S124 stock-watcher init --update failure).
extract_section_to_file() {
  local file="$1"
  local target_anchor="$2"
  local out="$3"
  awk -v anchor="$target_anchor" '
    BEGIN { in_section = 0; in_section_done = 0; depth = 0 }
    { sub(/\r$/, "") }
    /^(##|###) / {
      stripped = $0
      sub(/^#+[ ]+/, "", stripped)
      if (stripped == anchor && !in_section_done) {
        in_section = 1
        if ($0 ~ /^### /) depth = 3
        else depth = 2
        print $0
        next
      } else if (in_section) {
        if ($0 ~ /^## / || (depth == 3 && $0 ~ /^### /)) {
          in_section = 0
          in_section_done = 1
          exit
        }
      }
    }
    in_section { print $0 }
  ' "$file" > "$out"
}

# Extract section content into a temp file (preserves trailing newlines AND
# avoids `awk -v section=...` backslash-sequence corruption on insertion).
SECTION_TMP=$(mktemp 2>/dev/null) || { echo "ERROR: mktemp failed for section content" >&2; exit 1; }
trap 'rm -f "$SECTION_TMP" 2>/dev/null' EXIT
extract_section_to_file "$CANONICAL" "$ANCHOR" "$SECTION_TMP"

if [ ! -s "$SECTION_TMP" ]; then
  echo "ERROR: anchor '$ANCHOR' not found in canonical file $CANONICAL" >&2
  exit 1
fi

# --- Find canonical predecessor anchor ---
# The section appearing immediately BEFORE our target anchor in canonical order.

PREDECESSOR=$(awk -v target="$ANCHOR" '
  { sub(/\r$/, "") }
  /^(##|###) / {
    stripped = $0
    sub(/^#+[ ]+/, "", stripped)
    if (stripped == target) {
      print last_anchor
      exit
    }
    last_anchor = stripped
  }
' "$CANONICAL")

# --- Compute insertion line in target file ---
# If predecessor exists in target, find end of that section. Else, append at EOF.

INSERTION_LINE=0  # 0 = append at end
FALLBACK="false"

if [ -n "$PREDECESSOR" ]; then
  # Find the line where predecessor section ENDS in the target file.
  PRED_END=$(awk -v pred="$PREDECESSOR" '
    BEGIN { in_pred = 0; depth = 0; last_line = 0 }
    { sub(/\r$/, "") }
    /^(##|###) / {
      stripped = $0
      sub(/^#+[ ]+/, "", stripped)
      if (stripped == pred) {
        in_pred = 1
        if ($0 ~ /^### /) depth = 3
        else depth = 2
        last_line = NR
        next
      } else if (in_pred) {
        if ($0 ~ /^## / || (depth == 3 && $0 ~ /^### /)) {
          print NR - 1
          # P10.24 hardening (Issue 2): reset in_pred BEFORE exit so the END
          # block does not re-fire `if (in_pred) print last_line`, which would
          # emit a second integer and break the bash `[ "$PRED_END" -gt 0 ]`
          # arithmetic test (silent fallback to EOF append).
          in_pred = 0
          exit
        }
      }
    }
    in_pred { last_line = NR }
    END {
      if (in_pred) print last_line
    }
  ' "$TARGET")

  if [ -n "$PRED_END" ] && [ "$PRED_END" -gt 0 ]; then
    INSERTION_LINE="$PRED_END"
  else
    FALLBACK="true"
  fi
else
  FALLBACK="true"
fi

# --- Atomic insert ---
# TS-009 hardening: create temp file in target's directory (not $TMPDIR) so
# `mv -f` is guaranteed atomic — cross-filesystem mv is copy+delete which
# breaks atomicity (matters on WSL where /tmp may be on a different mount
# than /mnt/c/).
# TS-001 / SEC-APS-001 hardening: use head/tail/cat (not awk -v) so backslash
# sequences in canonical content (e.g., \n, \t, regex examples in code blocks)
# are preserved verbatim. awk -v silently transforms escape sequences.

TMP_FILE=$(mktemp "$(dirname "$TARGET")/.bulwark-apply-XXXXXX" 2>/dev/null) || \
  { echo "ERROR: mktemp failed in target dir" >&2; exit 1; }
trap 'rm -f "$TMP_FILE" "$SECTION_TMP" 2>/dev/null' EXIT

if [ "$FALLBACK" = "true" ]; then
  # Append at end with one blank line separator.
  cat "$TARGET" > "$TMP_FILE"
  # Ensure trailing newline before appending.
  if [ -n "$(tail -c 1 "$TARGET" 2>/dev/null)" ]; then
    echo "" >> "$TMP_FILE"
  fi
  echo "" >> "$TMP_FILE"
  cat "$SECTION_TMP" >> "$TMP_FILE"
else
  # Insert after INSERTION_LINE: head + blank + section + tail. No awk -v.
  head -n "$INSERTION_LINE" "$TARGET" > "$TMP_FILE"
  echo "" >> "$TMP_FILE"
  cat "$SECTION_TMP" >> "$TMP_FILE"
  tail -n "+$((INSERTION_LINE + 1))" "$TARGET" >> "$TMP_FILE"
fi

# --- Post-write validation ---
# SEC-APS-002 hardening: line-count sanity check catches gross corruption
# (truncation, awk-eaten-content, etc.) that an anchor-presence check misses.

TARGET_LINES=$(wc -l < "$TARGET")
SECTION_LINES=$(wc -l < "$SECTION_TMP")
TMP_LINES=$(wc -l < "$TMP_FILE")
EXPECTED_MIN=$((TARGET_LINES + SECTION_LINES))  # +1 for blank separator (≥ not =)

if [ ! -s "$TMP_FILE" ]; then
  echo "ERROR: insertion produced empty file (refusing to write)" >&2
  exit 1
fi
if [ "$TMP_LINES" -lt "$EXPECTED_MIN" ]; then
  echo "ERROR: insertion truncated content (got ${TMP_LINES} lines; expected ≥ ${EXPECTED_MIN}). Refusing to write." >&2
  exit 1
fi
if ! grep -qF "$ANCHOR" "$TMP_FILE"; then
  echo "ERROR: insertion did not preserve anchor in output (refusing to write)" >&2
  exit 1
fi

# Atomic mv (same filesystem guaranteed by mktemp in target dir).
mv -f "$TMP_FILE" "$TARGET"
trap 'rm -f "$SECTION_TMP" 2>/dev/null' EXIT

if [ "$FALLBACK" = "true" ]; then
  echo "Section '$ANCHOR' appended to $TARGET (fallback-position: predecessor not found)"
else
  echo "Section '$ANCHOR' inserted after line $INSERTION_LINE in $TARGET"
fi
exit 0
