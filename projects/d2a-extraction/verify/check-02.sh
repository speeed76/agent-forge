#!/usr/bin/env bash
# Verify Sprint 02 — d2a Full Audit + cascade-config Fix
set -euo pipefail
source "$(dirname "$0")/common.sh"

LOG_FILE="${1:-}"
WORKDIR="${2:-$HOME/Projects/wordsynk-automation-sys}"

MC_MEMORY="$HOME/Projects/mission-control/memory"
CASCADE_CONFIG="$WORKDIR/cascade-router/data/cascade-config.json"

echo "Sprint 02 — d2a Full Audit + cascade-config Fix"

# d2a-audit.md exists
check_file "$MC_MEMORY/d2a-audit.md" "" "mission-control/memory/d2a-audit.md"

# Contains all required sections
check_file "$MC_MEMORY/d2a-audit.md" "ORACLE_FIX\|Oracle" "d2a-audit.md has ORACLE_FIX section"
check_file "$MC_MEMORY/d2a-audit.md" "GAPS\|gaps" "d2a-audit.md has GAPS section"
check_file "$MC_MEMORY/d2a-audit.md" "DIRECT_IMPORTS\|direct.*import\|import anthropic" "d2a-audit.md has DIRECT_IMPORTS section"
check_file "$MC_MEMORY/d2a-audit.md" "LEGACY\|legacy\|dispatcher" "d2a-audit.md has LEGACY section"
check_file "$MC_MEMORY/d2a-audit.md" "SWARM_STATE\|swarm\|Swarm" "d2a-audit.md has SWARM_STATE section"

# cascade-config.json: LAN IP used (not Tailscale)
if [[ -f "$CASCADE_CONFIG" ]]; then
  if grep -q "192.168.0.192" "$CASCADE_CONFIG"; then
    _pass "cascade-config.json uses LAN IP (192.168.0.192)"
  else
    _fail "cascade-config.json does NOT use LAN IP — Oracle endpoint may still be wrong"
  fi

  # Tailscale IP should be gone from Oracle backend
  if grep -q "100.94.226.127" "$CASCADE_CONFIG"; then
    _fail "cascade-config.json still contains Tailscale IP 100.94.226.127"
  else
    _pass "cascade-config.json: Tailscale IP removed"
  fi
else
  echo "  ⚠ cascade-config.json not found at $CASCADE_CONFIG (may have moved in Sprint 05)"
fi

# Bonus: cascade-router health
if curl -sf http://localhost:3032/health >/dev/null 2>&1; then
  _pass "live: cascade-router responding at :3032"
else
  echo "  ⚠ cascade-router not responding at :3032 (expected after Sprint 05 migration)"
fi

print_summary "Sprint 02"
