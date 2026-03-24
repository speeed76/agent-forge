#!/usr/bin/env bash
# Verify Sprint 09 — Docker Swarm Fix
set -euo pipefail
source "$(dirname "$0")/common.sh"

LOG_FILE="${1:-}"
WORKDIR="${2:-$HOME/Projects/wordsynk-automation-sys}"

MC_MEMORY="$HOME/Projects/mission-control/memory"
STACK_FILE="$WORKDIR/docker-stack.yml"

echo "Sprint 09 — Docker Swarm Fix"

# swarm-state.md has SPRINT09_RESULT
check_file "$MC_MEMORY/swarm-state.md" "SPRINT09_RESULT\|Sprint09\|sprint 09\|sprint09" "swarm-state.md has SPRINT09_RESULT"

# Accept either fixed swarm OR documented as not needed
SWARM_STATE=$(cat "$MC_MEMORY/swarm-state.md" 2>/dev/null | grep -i "NOT_NEEDED\|FIXED\|not needed\|not required" | head -1)

if [[ -n "$SWARM_STATE" ]]; then
  _pass "swarm disposition documented: $SWARM_STATE"
else
  # Try live docker check
  NODE_COUNT=$(docker node ls --format "{{.Status}}" 2>/dev/null | grep -c "Ready" || echo "0")
  if [[ "$NODE_COUNT" -ge 2 ]]; then
    _pass "docker swarm: $NODE_COUNT Ready nodes"
  elif [[ "$NODE_COUNT" -eq 1 ]]; then
    echo "  ⚠ only 1 Ready node (expected 2+) — worker nodes may not have joined"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    FAILURES+=("Only 1 swarm node Ready")
  else
    _fail "docker node ls shows no Ready nodes AND swarm-state.md doesn't document NOT_NEEDED"
  fi
fi

# docker-stack.yml exists and has been touched (updated)
if [[ -f "$STACK_FILE" ]]; then
  _pass "docker-stack.yml exists"

  # Should not contain raw Tailscale IPs as swarm manager address
  if grep -q "100\.87\.14\.34\|100\.94\.226\.127\|--advertise-addr 100\." "$STACK_FILE" 2>/dev/null; then
    _fail "docker-stack.yml still contains Tailscale IPs as advertise addresses"
  else
    _pass "docker-stack.yml: no Tailscale advertise addresses"
  fi
else
  echo "  ⚠ docker-stack.yml not found at $STACK_FILE"
fi

print_summary "Sprint 09"
