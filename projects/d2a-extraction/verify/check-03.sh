#!/usr/bin/env bash
# Verify Sprint 03 — mission-control Context Infrastructure
set -euo pipefail
source "$(dirname "$0")/common.sh"

LOG_FILE="${1:-}"
WORKDIR="${2:-$HOME/Projects/mission-control}"

MC="$HOME/Projects/mission-control"

echo "Sprint 03 — mission-control Context Infrastructure"

# CLAUDE.md exists and has content
check_file "$MC/CLAUDE.md" "" "CLAUDE.md"
check_file_minlines "$MC/CLAUDE.md" 100 "CLAUDE.md (>= 100 lines)"

# CLAUDE.md contains required sections
check_file "$MC/CLAUDE.md" "cascade router\|cascade-router\|:3032" "CLAUDE.md mentions cascade router"
check_file "$MC/CLAUDE.md" "pipeline-safety\|pipeline safety" "CLAUDE.md references pipeline-safety rule"
check_file "$MC/CLAUDE.md" ":3031\|mission-control" "CLAUDE.md has service ports"

# pipeline-safety rule file
check_file "$MC/.claude/rules/pipeline-safety.md" "" ".claude/rules/pipeline-safety.md"
check_file "$MC/.claude/rules/pipeline-safety.md" "cascade router\|cascade-router" "pipeline-safety.md mentions cascade router"
check_file "$MC/.claude/rules/pipeline-safety.md" "paths:" "pipeline-safety.md has YAML frontmatter paths"

# start command
check_file "$MC/.claude/commands/start.md" "" ".claude/commands/start.md"

# wrap command
check_file "$MC/.claude/commands/wrap.md" "" ".claude/commands/wrap.md"

# directory structure
check_dir "$MC/.claude/rules" ".claude/rules/"
check_dir "$MC/.claude/commands" ".claude/commands/"
check_dir "$MC/memory" "memory/"

print_summary "Sprint 03"
