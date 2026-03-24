#!/usr/bin/env bash
# Verify Sprint 14 — cobalt-sandbox Initialization
set -euo pipefail
source "$(dirname "$0")/common.sh"

LOG_FILE="${1:-}"
WORKDIR="${2:-$HOME/Projects/mission-control}"

MC_MEMORY="$HOME/Projects/mission-control/memory"

echo "Sprint 14 — cobalt-sandbox Initialization"

# cobalt-sandbox has a main branch commit
SHA=$(gh api repos/speeed76/cobalt-sandbox/commits/main --jq '.sha' 2>/dev/null || echo "")

if [[ ${#SHA} -eq 40 ]]; then
  _pass "cobalt-sandbox/main SHA: ${SHA:0:8}..."
else
  _fail "cobalt-sandbox/commits/main: no valid SHA returned (got: '$SHA')"
fi

# pipeline.md updated with cobalt-sandbox status
check_file "$MC_MEMORY/pipeline.md" \
  "cobalt-sandbox\|cobalt_sandbox\|READY" \
  "memory/pipeline.md mentions cobalt-sandbox status"

# Bonus: FORGE_PAT access
if [[ -n "${FORGE_PAT:-}" ]]; then
  if gh api repos/speeed76/cobalt-sandbox --token "$FORGE_PAT" --jq '.full_name' >/dev/null 2>&1; then
    _pass "FORGE_PAT has access to cobalt-sandbox"
  else
    echo "  ⚠ FORGE_PAT cannot access cobalt-sandbox — add repo to PAT allowlist"
  fi
else
  echo "  ⚠ FORGE_PAT not set in environment — cannot verify PAT access"
fi

print_summary "Sprint 14"
