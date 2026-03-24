#!/usr/bin/env bash
# Verify Sprint 05 — cascade-router Migration
set -euo pipefail
source "$(dirname "$0")/common.sh"

LOG_FILE="${1:-}"
WORKDIR="${2:-$HOME/Projects/wordsynk-automation-sys}"

MC_CR="$HOME/Projects/mission-control/cascade-router"

echo "Sprint 05 — cascade-router Migration"

# cascade-router directory exists in mission-control
check_dir "$MC_CR" "mission-control/cascade-router/"

# Key files present in new location
check_file "$MC_CR/package.json" "" "cascade-router/package.json in mission-control"
check_file "$MC_CR/data/cascade-config.json" "" "cascade-router/data/cascade-config.json in mission-control"

# cascade-config.json uses LAN IP (not Tailscale)
if [[ -f "$MC_CR/data/cascade-config.json" ]]; then
  if grep -q "192.168.0.192" "$MC_CR/data/cascade-config.json"; then
    _pass "cascade-config.json uses LAN IP"
  elif grep -q "100.94.226.127" "$MC_CR/data/cascade-config.json"; then
    _fail "cascade-config.json still has Tailscale IP"
  else
    echo "  ⚠ cascade-config.json doesn't have Oracle LAN IP — check manually"
  fi
fi

# cascade-router health check
if curl -sf http://localhost:3032/health >/dev/null 2>&1; then
  _pass "live: cascade-router :3032 responding"
else
  _fail "cascade-router :3032 not responding"
fi

# services.md updated with new path
check_file "$HOME/Projects/mission-control/memory/services.md" \
  "mission-control/cascade-router\|mission-control.*cascade" \
  "services.md updated with new cascade-router path"

print_summary "Sprint 05"
