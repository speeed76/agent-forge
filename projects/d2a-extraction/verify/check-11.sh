#!/usr/bin/env bash
# Verify Sprint 11 — wordsynk: Clean Context
set -euo pipefail
source "$(dirname "$0")/common.sh"

LOG_FILE="${1:-}"
WORKDIR="${2:-$HOME/Projects/wordsynk-automation-sys}"

echo "Sprint 11 — wordsynk: Clean Context"

# CLAUDE.md pipeline refs ≤ 2
PIPELINE_REFS=$(grep -c "pipeline-safety\|Herald\|Arbiter\|Forge" "$WORKDIR/CLAUDE.md" 2>/dev/null || echo "0")
if [[ "$PIPELINE_REFS" -le 2 ]]; then
  _pass "CLAUDE.md pipeline refs: $PIPELINE_REFS (≤ 2 allowed)"
else
  _fail "CLAUDE.md has $PIPELINE_REFS pipeline refs (max 2: one archive note + one external ref)"
fi

# pipeline-safety.md NOT in wordsynk rules
if [[ -f "$WORKDIR/.claude/rules/pipeline-safety.md" ]]; then
  _fail ".claude/rules/pipeline-safety.md still exists in wordsynk (should be removed)"
else
  _pass ".claude/rules/pipeline-safety.md removed from wordsynk"
fi

# SESSION_NEXT.md NOT present
if [[ -f "$WORKDIR/SESSION_NEXT.md" ]]; then
  _fail "SESSION_NEXT.md still exists in wordsynk root (should be deleted)"
else
  _pass "SESSION_NEXT.md removed"
fi

# CLAUDE.md has d2a external reference
check_file "$WORKDIR/CLAUDE.md" ":3031\|mission-control\|d2a" "CLAUDE.md has d2a external reference"

# Git commit
check_git_commit "$WORKDIR" "pipeline\|d2a\|cleanup\|clean context\|remove" "wordsynk cleanup commit"

print_summary "Sprint 11"
