#!/bin/bash
# cleanup-review-registry.sh - SessionStart hook handler
#
# Purges per-turn pipeline state at the start of every Claude session
# (true session start, post-compact, post-clear). Wipes BOTH:
#   1. Per-file review registry (PENDING/REVIEWED entries)
#   2. Per-turn changed-files accumulator (consumed by Stop hook)
#
# Pairs with suggest-pipeline-stop.sh: the Stop hook builds up PENDING entries
# AND populates the accumulator during a session. At session boundary, both
# are wiped together so fresh sessions don't inherit stale state from prior
# runs. Without the accumulator wipe (added P10.16), the registry would clear
# but the accumulator would persist any entries that landed after the
# recursion guard fired in the prior session, causing spurious decision:block
# on the new session's first Stop event.
#
# Registry path:    ${CLAUDE_PROJECT_DIR}/tmp/bulwark-review-registry.json
# Accumulator path: ${CLAUDE_PROJECT_DIR}/tmp/bulwark-changed-files.json
# (See suggest-pipeline-stop.sh for both schemas.)
#
# Hardened in S115 (SEC-007 + SEC-005): validate CLAUDE_PROJECT_DIR is an
# absolute existing path AND verify both target paths are under the expected
# tmp/ subdirectory before rm/write. Defends against env override pointing
# the script at unrelated files.
#
# Observability (added P10.16): each cleanup writes a single line to
# logs/hooks.log so the audit trail records what was cleared and when.

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# SEC-007 — env var must be absolute + existing.
case "$PROJECT_DIR" in
  /*) ;;
  *)
    echo '{}'
    exit 0
    ;;
esac
if [ ! -d "$PROJECT_DIR" ]; then
  echo '{}'
  exit 0
fi

REGISTRY_FILE="${PROJECT_DIR}/tmp/bulwark-review-registry.json"
EXPECTED_PARENT="${PROJECT_DIR}/tmp"

# SEC-005 — defensive: confirm we're about to delete inside the expected
# tmp/ subtree before rm. (Belt-and-braces with the SEC-007 guard above.)
case "$REGISTRY_FILE" in
  "$EXPECTED_PARENT"/bulwark-review-registry.json) ;;
  *)
    echo '{}'
    exit 0
    ;;
esac

TIMESTAMP=$(date -Iseconds)
HOOKS_LOG="${PROJECT_DIR}/logs/hooks.log"
mkdir -p "$(dirname "$HOOKS_LOG")" 2>/dev/null || true

ENTRY_COUNT="0"
if [ -f "$REGISTRY_FILE" ]; then
  ENTRY_COUNT=$(jq -r '.files | length' "$REGISTRY_FILE" 2>/dev/null || echo "0")
fi
echo "[${TIMESTAMP}] SessionStart: review-registry cleared (was ${ENTRY_COUNT} entries)" >> "$HOOKS_LOG" 2>/dev/null || true

if [ -f "$REGISTRY_FILE" ]; then
  rm -f "$REGISTRY_FILE"
fi

# Accumulator wipe (P10.16) — keeps registry and accumulator in lockstep at
# session boundaries. Without this, accumulator entries that landed after the
# prior session's recursion-guard fire persist into the new session and
# cause spurious decision:block on first Stop. (See header for full
# rationale.)
ACCUMULATOR_FILE="${PROJECT_DIR}/tmp/bulwark-changed-files.json"

# SEC-005 — same path-guard pattern used for the registry above.
case "$ACCUMULATOR_FILE" in
  "$EXPECTED_PARENT"/bulwark-changed-files.json) ;;
  *)
    echo '{}'
    exit 0
    ;;
esac

# SEC-006 (P10.16 SUG-002) — refuse to write through a symlink. The path-guard
# above validates the string equals the expected literal, but not the inode
# type. A symlink at that path could redirect the `jq -n > ...` write to an
# attacker-controlled target.
if [ -L "$ACCUMULATOR_FILE" ]; then
  echo "[${TIMESTAMP}] SessionStart: accumulator path is a symlink — refusing write" >> "$HOOKS_LOG" 2>/dev/null || true
elif [ -f "$ACCUMULATOR_FILE" ]; then
  ACC_COUNT=$(jq -r '.files | length' "$ACCUMULATOR_FILE" 2>/dev/null || echo "0")
  echo "[${TIMESTAMP}] SessionStart: accumulator cleared (was ${ACC_COUNT} entries)" >> "$HOOKS_LOG" 2>/dev/null || true
  jq -n '{version: "1.0", files: []}' > "$ACCUMULATOR_FILE" 2>/dev/null || rm -f "$ACCUMULATOR_FILE"
fi

# SessionStart hooks MUST emit {} with no `decision` field — per Anthropic
# hook spec, SessionStart hooks cannot block the session start. Emitting
# anything other than {} (or a JSON object without `decision`) is a contract
# violation that Claude Code's hook runner silently drops.
echo '{}'
exit 0
