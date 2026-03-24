#!/usr/bin/env bash
# Verify Sprint 10 — wordsynk: Archive Legacy Agents
set -euo pipefail
source "$(dirname "$0")/common.sh"

LOG_FILE="${1:-}"
WORKDIR="${2:-$HOME/Projects/wordsynk-automation-sys}"

AGENTS="$WORKDIR/agents"

echo "Sprint 10 — wordsynk: Archive Legacy Agents"

# _archive directory exists
check_dir "$AGENTS/_archive" "agents/_archive/"

# dispatcher-herald-legacy exists in archive
check_dir "$AGENTS/_archive/dispatcher-herald-legacy" "agents/_archive/dispatcher-herald-legacy/"

# dispatcher NO LONGER in active location
if [[ -d "$AGENTS/dispatcher" ]]; then
  _fail "agents/dispatcher/ still exists in active location (should be in _archive)"
else
  _pass "agents/dispatcher/ removed from active location"
fi

# _archive README exists
check_file "$AGENTS/_archive/README.md" "superseded\|archived\|Archived" "agents/_archive/README.md"

# Something is in dispatcher-herald-legacy
LEGACY_COUNT=$(ls "$AGENTS/_archive/dispatcher-herald-legacy/" 2>/dev/null | wc -l | tr -d ' ')
if [[ "$LEGACY_COUNT" -gt 0 ]]; then
  _pass "dispatcher-herald-legacy has $LEGACY_COUNT files"
else
  _fail "dispatcher-herald-legacy/ is empty"
fi

# Git commit with archive in message
check_git_commit "$WORKDIR" "archive\|legacy\|dispatcher" "wordsynk archive commit"

print_summary "Sprint 10"
