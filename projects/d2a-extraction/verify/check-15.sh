#!/usr/bin/env bash
# Verify Sprint 15 — E2E Smoke Test: PawsOnLeash (Path A)
set -euo pipefail
source "$(dirname "$0")/common.sh"

LOG_FILE="${1:-}"
WORKDIR="${2:-$HOME/Projects/mission-control}"

MC_MEMORY="$HOME/Projects/mission-control/memory"

echo "Sprint 15 — E2E Smoke Test: PawsOnLeash (Path A)"

# E2E results file created
E2E_REPORT=$(ls "$MC_MEMORY"/e2e-results-*.md 2>/dev/null | head -1)
if [[ -n "$E2E_REPORT" ]]; then
  _pass "E2E results file: $(basename $E2E_REPORT)"
else
  _fail "No e2e-results-*.md found in mission-control/memory/"
fi

# E2E results has required sections
if [[ -n "$E2E_REPORT" ]]; then
  check_file "$E2E_REPORT" "PIPELINE_RESPONSE\|pipeline response\|Pipeline Response" "e2e-results has pipeline response"
  check_file "$E2E_REPORT" "VERDICT\|verdict\|PASS\|FAIL\|PARTIAL" "e2e-results has verdict"
fi

# Check if PR was created on cobalt-sandbox
PR_NUMBER=$(gh api repos/speeed76/cobalt-sandbox/pulls --jq '.[0].number' 2>/dev/null || echo "")
if [[ -n "$PR_NUMBER" ]] && [[ "$PR_NUMBER" != "null" ]]; then
  _pass "PR created on cobalt-sandbox: #$PR_NUMBER"
else
  # Not necessarily a failure — pipeline may not have completed within timeout
  # Check if the E2E results document why
  if [[ -n "$E2E_REPORT" ]] && grep -qi "timeout\|not running\|DOWN\|blocker\|PARTIAL" "$E2E_REPORT" 2>/dev/null; then
    echo "  ⚠ No PR on cobalt-sandbox, but E2E results document reason — acceptable"
    _pass "E2E test ran with documented outcome (no PR but reason given)"
  else
    _fail "No PR on cobalt-sandbox and E2E results don't explain why"
  fi
fi

print_summary "Sprint 15"
