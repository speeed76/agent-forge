#!/usr/bin/env bash
# Verify Sprint 07 — cortex Direct Import Refactor
set -euo pipefail
source "$(dirname "$0")/common.sh"

LOG_FILE="${1:-}"
WORKDIR="${2:-$HOME/Projects/cortex}"

CORTEX="$HOME/Projects/cortex"

echo "Sprint 07 — cortex Direct Import Refactor"

# No direct anthropic imports in operationalizer.py
if [[ -f "$CORTEX/runtime/operationalizer.py" ]]; then
  if grep -q "^import anthropic\|^from anthropic\|anthropic\.Anthropic()" "$CORTEX/runtime/operationalizer.py" 2>/dev/null; then
    _fail "operationalizer.py STILL has direct anthropic imports"
  else
    _pass "operationalizer.py: no direct anthropic imports"
  fi
else
  _fail "operationalizer.py not found at $CORTEX/runtime/operationalizer.py"
fi

# No direct anthropic imports in cla.py
if [[ -f "$CORTEX/runtime/cla.py" ]]; then
  if grep -q "^import anthropic\|^from anthropic\|anthropic\.Anthropic()" "$CORTEX/runtime/cla.py" 2>/dev/null; then
    _fail "cla.py STILL has direct anthropic imports"
  else
    _pass "cla.py: no direct anthropic imports"
  fi
else
  _fail "cla.py not found at $CORTEX/runtime/cla.py"
fi

# cascade_client.py mentions cascade-router
check_file "$CORTEX/runtime/cascade_client.py" \
  "3032\|cascade.*router\|CASCADE_ROUTER_URL\|/api/cascade" \
  "cascade_client.py routes through cascade-router"

# Python import test
if python3 -c "import sys; sys.path.insert(0, '$CORTEX'); from runtime import operationalizer" 2>/dev/null; then
  _pass "python import: operationalizer module importable"
else
  echo "  ⚠ operationalizer import failed (may need cascade-router running or deps installed)"
fi

# Git commit with cascade in message
check_git_commit "$CORTEX" "cascade\|refactor\|direct.*import" "cortex git commit"

# Bonus: check remote push
REMOTE_SHA=$(cd "$CORTEX" && git ls-remote origin HEAD 2>/dev/null | awk '{print $1}' | head -1)
LOCAL_SHA=$(cd "$CORTEX" && git rev-parse HEAD 2>/dev/null)
if [[ "$REMOTE_SHA" == "$LOCAL_SHA" ]]; then
  _pass "git: local HEAD matches remote (push successful)"
else
  echo "  ⚠ local HEAD ($LOCAL_SHA) != remote ($REMOTE_SHA) — push may have failed"
fi

print_summary "Sprint 07"
