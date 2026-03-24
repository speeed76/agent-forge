#!/usr/bin/env bash
# Verify Sprint 12 — wordsynk: Reconnection Config
set -euo pipefail
source "$(dirname "$0")/common.sh"

LOG_FILE="${1:-}"
WORKDIR="${2:-$HOME/Projects/wordsynk-automation-sys}"

echo "Sprint 12 — wordsynk: Reconnection Config"

# d2a.config.json exists
check_file "$WORKDIR/d2a.config.json" "" "d2a.config.json"

# Valid JSON
check_json "$WORKDIR/d2a.config.json" "d2a.config.json"

# Contains required keys
check_json_key "$WORKDIR/d2a.config.json" "endpoint" "d2a.config.json.endpoint"
check_json_key "$WORKDIR/d2a.config.json" "targetRepo" "d2a.config.json.targetRepo"
check_json_key "$WORKDIR/d2a.config.json" "projectName" "d2a.config.json.projectName"

# Endpoint points to :3031
check_file "$WORKDIR/d2a.config.json" "3031\|localhost:3031" "d2a.config.json endpoint is :3031"

# agents/worker/contexts/ directory exists
check_dir "$WORKDIR/agents/worker/contexts" "agents/worker/contexts/"

# CLAUDE.md mentions context files or d2a.config
check_file "$WORKDIR/CLAUDE.md" "d2a.config\|contexts\|Forge context\|forge context" "CLAUDE.md mentions context files"

# Git commit
check_git_commit "$WORKDIR" "d2a.config\|config\|reconnect" "wordsynk config commit"

print_summary "Sprint 12"
