#!/usr/bin/env bash
# Verify Sprint 16 — E2E Assessment + Final Handover
set -euo pipefail
source "$(dirname "$0")/common.sh"

LOG_FILE="${1:-}"
WORKDIR="${2:-$HOME/Projects/mission-control}"

MC="$HOME/Projects/mission-control"
MC_MEMORY="$MC/memory"

echo "Sprint 16 — E2E Assessment + Final Handover"

# post-extraction-assessment.md exists
check_file "$MC_MEMORY/post-extraction-assessment.md" "" "memory/post-extraction-assessment.md"

# Contains overall verdict
check_file "$MC_MEMORY/post-extraction-assessment.md" \
  "OVERALL_VERDICT\|EXTRACTION COMPLETE\|PARTIAL\|FAILED\|overall verdict" \
  "assessment has overall verdict"

# Contains extraction summary
check_file "$MC_MEMORY/post-extraction-assessment.md" \
  "EXTRACTION_SUMMARY\|extraction summary\|accomplished" \
  "assessment has extraction summary"

# SESSION_NEXT.md exists in mission-control root
check_file "$MC/SESSION_NEXT.md" "" "mission-control/SESSION_NEXT.md"

# SESSION_NEXT.md has priorities
check_file "$MC/SESSION_NEXT.md" \
  "Priority\|priority\|Next Session\|next session\|Top\|top" \
  "SESSION_NEXT.md has next priorities"

# MEMORY.md updated (has recent date or sprint reference)
check_file "$MC_MEMORY/MEMORY.md" \
  "Sprint\|sprint\|extraction\|2026" \
  "MEMORY.md updated with extraction results"

# All core memory files still present
check_file "$MC_MEMORY/pipeline.md" "" "memory/pipeline.md"
check_file "$MC_MEMORY/services.md" "" "memory/services.md"
check_file "$MC_MEMORY/MEMORY.md" "" "memory/MEMORY.md"
check_file "$MC_MEMORY/infrastructure.md" "" "memory/infrastructure.md"

print_summary "Sprint 16"
