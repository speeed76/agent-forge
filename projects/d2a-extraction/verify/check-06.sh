#!/usr/bin/env bash
# Verify Sprint 06 — cortex cascade_client.py Audit
set -euo pipefail
source "$(dirname "$0")/common.sh"

LOG_FILE="${1:-}"
WORKDIR="${2:-$HOME/Projects/cortex}"

CORTEX="$HOME/Projects/cortex"

echo "Sprint 06 — cortex cascade_client.py Audit"

# Refactor plan file exists
check_file "$CORTEX/memory/cascade-refactor-plan.md" "" "cortex/memory/cascade-refactor-plan.md"

# Contains required sections
check_file "$CORTEX/memory/cascade-refactor-plan.md" \
  "operationalizer\|operationalizer.py" \
  "cascade-refactor-plan.md mentions operationalizer"

check_file "$CORTEX/memory/cascade-refactor-plan.md" \
  "cla\|cla.py" \
  "cascade-refactor-plan.md mentions cla"

check_file "$CORTEX/memory/cascade-refactor-plan.md" \
  "refactor_steps\|refactor steps\|## refactor" \
  "cascade-refactor-plan.md has refactor_steps section"

check_file "$CORTEX/memory/cascade-refactor-plan.md" \
  "CURRENT_STATE\|current state\|## Current" \
  "cascade-refactor-plan.md has CURRENT_STATE section"

check_file "$CORTEX/memory/cascade-refactor-plan.md" \
  "cascade_client\|cascade client" \
  "cascade-refactor-plan.md mentions cascade_client"

# cascade_client.py exists
check_file "$CORTEX/runtime/cascade_client.py" "" "cortex/runtime/cascade_client.py exists"

print_summary "Sprint 06"
