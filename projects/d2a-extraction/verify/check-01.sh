#!/usr/bin/env bash
# Verify Sprint 01 — Infrastructure Reconnaissance + Oracle Fix
set -euo pipefail
source "$(dirname "$0")/common.sh"

LOG_FILE="${1:-}"
WORKDIR="${2:-$HOME/Projects/wordsynk-automation-sys}"

MC_MEMORY="$HOME/Projects/mission-control/memory"

echo "Sprint 01 — Infrastructure Reconnaissance + Oracle Fix"

# Primary: infrastructure.md exists
check_file "$MC_MEMORY/infrastructure.md" "" "mission-control/memory/infrastructure.md"

# Contains FLEET section
check_file "$MC_MEMORY/infrastructure.md" "FLEET\|Mac Mini\|Mac Studio" "infrastructure.md has fleet data"

# Contains ORACLE section
check_file "$MC_MEMORY/infrastructure.md" "ORACLE\|192.168.0.192\|11434" "infrastructure.md has Oracle endpoint"

# Contains SWARM placeholder
check_file "$MC_MEMORY/infrastructure.md" "SWARM\|swarm" "infrastructure.md has SWARM section"

# Contains SSH section
check_file "$MC_MEMORY/infrastructure.md" "SSH\|ssh " "infrastructure.md has SSH section"

# Bonus: Oracle LAN actually responding
if curl -sf http://192.168.0.192:11434/api/tags >/dev/null 2>&1; then
  _pass "live: Oracle LLM responding at 192.168.0.192:11434"
else
  echo "  ⚠ Oracle LLM not responding at 192.168.0.192:11434 (may need LAN binding fix)"
fi

print_summary "Sprint 01"
