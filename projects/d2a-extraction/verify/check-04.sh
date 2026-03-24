#!/usr/bin/env bash
# Verify Sprint 04 — mission-control Memory Reconstruction
set -euo pipefail
source "$(dirname "$0")/common.sh"

LOG_FILE="${1:-}"
WORKDIR="${2:-$HOME/Projects/mission-control}"

MC_MEMORY="$HOME/Projects/mission-control/memory"

echo "Sprint 04 — mission-control Memory Reconstruction"

# All 4 required memory files exist
check_file "$MC_MEMORY/MEMORY.md" "" "memory/MEMORY.md"
check_file "$MC_MEMORY/pipeline.md" "" "memory/pipeline.md"
check_file "$MC_MEMORY/services.md" "" "memory/services.md"
check_file "$MC_MEMORY/specflow.md" "" "memory/specflow.md"

# pipeline.md is substantive (> 80 lines)
check_file_minlines "$MC_MEMORY/pipeline.md" 80 "memory/pipeline.md (>= 80 lines)"

# pipeline.md contains key sections
check_file "$MC_MEMORY/pipeline.md" "ARCHITECTURE\|architecture\|cortex\|Cortex" "pipeline.md has architecture section"
check_file "$MC_MEMORY/pipeline.md" "FORGE_PAT\|forge.pat\|FORGE PAT" "pipeline.md mentions FORGE_PAT"
check_file "$MC_MEMORY/pipeline.md" "cascade\|Cascade" "pipeline.md mentions cascade"

# services.md contains port references
check_file "$MC_MEMORY/services.md" ":3031\|3031" "services.md has :3031"
check_file "$MC_MEMORY/services.md" ":3032\|3032" "services.md has :3032"

# MEMORY.md has content
check_file_minlines "$MC_MEMORY/MEMORY.md" 10 "MEMORY.md (>= 10 lines)"

print_summary "Sprint 04"
