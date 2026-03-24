#!/usr/bin/env bash
# Verify Sprint 13 — mission-control Pre-flight Health Check
set -euo pipefail
source "$(dirname "$0")/common.sh"

LOG_FILE="${1:-}"
WORKDIR="${2:-$HOME/Projects/mission-control}"

MC="$HOME/Projects/mission-control"
MC_MEMORY="$MC/memory"

echo "Sprint 13 — mission-control Pre-flight Health Check"

# Health report file exists
HEALTH_REPORT=$(ls "$MC_MEMORY"/health-check-*.md 2>/dev/null | head -1)
if [[ -n "$HEALTH_REPORT" ]]; then
  _pass "health report created: $(basename $HEALTH_REPORT)"
else
  _fail "No health-check-*.md found in mission-control/memory/"
fi

# Health report has Recommendation section
if [[ -n "$HEALTH_REPORT" ]]; then
  check_file "$HEALTH_REPORT" "Recommendation\|PROCEED\|HOLD" "health report has Recommendation"
fi

# mission-control :3031 is responding
if curl -sf http://localhost:3031/health >/dev/null 2>&1; then
  _pass "live: mission-control :3031 responding"
elif curl -sf http://localhost:3031/ >/dev/null 2>&1; then
  _pass "live: mission-control :3031 responding (root endpoint)"
else
  _fail "mission-control :3031 not responding"
fi

# cascade-router :3032 is responding
if curl -sf http://localhost:3032/health >/dev/null 2>&1; then
  _pass "live: cascade-router :3032 responding"
else
  _fail "cascade-router :3032 not responding (Sprint 05 migration may have failed)"
fi

# context infrastructure intact
check_file "$MC/CLAUDE.md" "" "CLAUDE.md"
check_file "$MC/.claude/rules/pipeline-safety.md" "" "pipeline-safety.md"
check_file "$MC_MEMORY/MEMORY.md" "" "memory/MEMORY.md"
check_file "$MC_MEMORY/pipeline.md" "" "memory/pipeline.md"
check_file "$MC_MEMORY/services.md" "" "memory/services.md"

print_summary "Sprint 13"
