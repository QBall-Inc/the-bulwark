#!/bin/bash
# verify-hooks.sh - Automated verification for P3.4-5 hooks configuration
#
# Verifies:
# 1. hooks/hooks.json is valid JSON
# 2. All referenced scripts exist and are executable
# 3. inject-protocol.sh produces governance output
# 4. sync-hooks-for-dev.sh transforms paths correctly
#
# Exit codes:
#   0 = All checks pass
#   1 = One or more checks failed

set -euo pipefail

PROJECT_DIR="${1:-.}"
PASS=0
FAIL=0

log_pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
log_fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "=== P3.4-5 Hooks Configuration Verification ==="
echo ""

# V1: hooks.json is valid JSON
echo "V1: Validating hooks/hooks.json syntax..."
if cat "$PROJECT_DIR/hooks/hooks.json" | jq . > /dev/null 2>&1; then
  log_pass "hooks/hooks.json is valid JSON"
else
  log_fail "hooks/hooks.json is invalid JSON"
fi

# V2: Required hook events exist
echo "V2: Checking required hook events..."
for event in PostToolUse SubagentStart SubagentStop SessionStart; do
  if jq -e ".hooks.${event}" "$PROJECT_DIR/hooks/hooks.json" > /dev/null 2>&1; then
    log_pass "${event} hook defined"
  else
    log_fail "${event} hook missing"
  fi
done

# V3: All referenced scripts exist and are executable
echo "V3: Checking script existence and permissions..."
SCRIPTS=$(jq -r '.. | .command? // empty' "$PROJECT_DIR/hooks/hooks.json" | sed 's|\${CLAUDE_PLUGIN_ROOT}|'"$PROJECT_DIR"'|g')
for script in $SCRIPTS; do
  if [ -f "$script" ]; then
    if [ -x "$script" ]; then
      log_pass "$(basename "$script") exists and executable"
    else
      log_fail "$(basename "$script") exists but not executable"
    fi
  else
    log_fail "$(basename "$script") not found at $script"
  fi
done

# V4: inject-protocol.sh produces output
echo "V4: Testing inject-protocol.sh output..."
OUTPUT=$(CLAUDE_PROJECT_DIR="$PROJECT_DIR" bash "$PROJECT_DIR/scripts/hooks/inject-protocol.sh" 2>&1 || true)
if echo "$OUTPUT" | grep -q "Bulwark Governance Protocol"; then
  log_pass "inject-protocol.sh outputs governance protocol"
else
  log_fail "inject-protocol.sh does not output expected content"
fi

# V5: SessionStart has once:true
echo "V5: Checking SessionStart once:true..."
ONCE=$(jq -r '.hooks.SessionStart[0].hooks[0].once // false' "$PROJECT_DIR/hooks/hooks.json")
if [ "$ONCE" = "true" ]; then
  log_pass "SessionStart has once: true"
else
  log_fail "SessionStart missing once: true"
fi

# V6: Timeout values are in milliseconds (>= 1000)
echo "V6: Checking timeout values are in milliseconds..."
TIMEOUTS=$(jq -r '.. | .timeout? // empty' "$PROJECT_DIR/hooks/hooks.json")
for timeout in $TIMEOUTS; do
  if [ "$timeout" -ge 1000 ]; then
    log_pass "Timeout ${timeout}ms is valid (>= 1000)"
  else
    log_fail "Timeout ${timeout} appears to be in seconds, should be milliseconds"
  fi
done

# V7: sync-hooks-for-dev.sh works
echo "V7: Testing sync-hooks-for-dev.sh..."
if [ -x "$PROJECT_DIR/scripts/sync-hooks-for-dev.sh" ]; then
  # Run sync and check output
  SYNC_OUTPUT=$(bash "$PROJECT_DIR/scripts/sync-hooks-for-dev.sh" 2>&1 || true)
  if echo "$SYNC_OUTPUT" | grep -q "Path transformation"; then
    log_pass "sync-hooks-for-dev.sh executes successfully"

    # Check that PROJECT_DIR is used in settings.json
    if grep -q 'CLAUDE_PROJECT_DIR' "$PROJECT_DIR/.claude/settings.json" 2>/dev/null; then
      log_pass "settings.json uses CLAUDE_PROJECT_DIR (correct for project)"
    else
      log_fail "settings.json does not use CLAUDE_PROJECT_DIR"
    fi
  else
    log_fail "sync-hooks-for-dev.sh did not complete successfully"
  fi
else
  log_fail "sync-hooks-for-dev.sh not found or not executable"
fi

# Summary
echo ""
echo "=== Summary ==="
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo ""

if [ $FAIL -eq 0 ]; then
  echo "Result: ALL CHECKS PASSED"
  exit 0
else
  echo "Result: $FAIL CHECK(S) FAILED"
  exit 1
fi
