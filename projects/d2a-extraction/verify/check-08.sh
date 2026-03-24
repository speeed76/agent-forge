#!/usr/bin/env bash
# Verify Sprint 08 — Docker Swarm Investigation
set -euo pipefail
source "$(dirname "$0")/common.sh"

LOG_FILE="${1:-}"
WORKDIR="${2:-$HOME/Projects/wordsynk-automation-sys}"

MC_MEMORY="$HOME/Projects/mission-control/memory"

echo "Sprint 08 — Docker Swarm Investigation"

# swarm-state.md exists
check_file "$MC_MEMORY/swarm-state.md" "" "mission-control/memory/swarm-state.md"

# Contains "manager" keyword
check_file "$MC_MEMORY/swarm-state.md" "manager\|Manager\|MANAGER" "swarm-state.md mentions manager"

# Contains DIAGNOSIS section
check_file "$MC_MEMORY/swarm-state.md" "DIAGNOSIS\|diagnosis" "swarm-state.md has DIAGNOSIS section"

# Contains FIX_REQUIRED
check_file "$MC_MEMORY/swarm-state.md" "FIX_REQUIRED\|fix required\|Fix Required" "swarm-state.md has FIX_REQUIRED section"

# Contains node status info
check_file "$MC_MEMORY/swarm-state.md" \
  "Mac Mini\|Mac Studio\|Ubuntu\|192.168.0" \
  "swarm-state.md documents node status"

print_summary "Sprint 08"
