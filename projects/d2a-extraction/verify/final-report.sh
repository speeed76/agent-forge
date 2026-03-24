#!/usr/bin/env bash
# Generate final report after all sprints complete
# Usage: bash verify/final-report.sh <results_dir>
set -euo pipefail

RESULTS_DIR="${1:-$(dirname "$0")/../results}"
REPORT_FILE="$RESULTS_DIR/FINAL_REPORT.md"

MC="$HOME/Projects/mission-control"
MC_MEMORY="$MC/memory"

echo "Generating final report → $REPORT_FILE"

{
  echo "# d2a Extraction Sprint — Final Report"
  echo ""
  echo "Generated: $(date -u '+%Y-%m-%d %H:%M UTC')"
  echo ""

  # ── Run Summary ──────────────────────────────────────────────────────────
  echo "## Sprint Run Summary"
  echo ""
  if [[ -f "$RESULTS_DIR/run-summary.txt" ]]; then
    TOTAL=$(grep -c "Sprint" "$RESULTS_DIR/run-summary.txt" 2>/dev/null || echo "0")
    PASSED=$(grep -c "PASS" "$RESULTS_DIR/run-summary.txt" 2>/dev/null || echo "0")
    echo "| Sprint | Status | Timestamp |"
    echo "|--------|--------|-----------|"
    while IFS= read -r line; do
      if [[ "$line" =~ Sprint\ ([0-9]+):\ (PASS|FAIL) ]]; then
        num="${BASH_REMATCH[1]}"
        status="${BASH_REMATCH[2]}"
        ts=$(echo "$line" | grep -o '[0-9T:Z-]*$' || echo "unknown")
        ICON="✓"
        [[ "$status" == "FAIL" ]] && ICON="✗"
        echo "| $ICON Sprint $num | $status | $ts |"
      fi
    done < "$RESULTS_DIR/run-summary.txt"
    echo ""
    echo "**Total: $PASSED / $TOTAL sprints passed**"
  else
    echo "_No run summary found._"
  fi
  echo ""

  # ── Infrastructure Status ────────────────────────────────────────────────
  echo "## Infrastructure Status"
  echo ""
  echo "| Service | Check | Status |"
  echo "|---------|-------|--------|"

  _check_svc() {
    local name="$1"
    local url="$2"
    if curl -sf "$url" >/dev/null 2>&1; then
      echo "| $name | $url | ✓ HEALTHY |"
    else
      echo "| $name | $url | ✗ DOWN |"
    fi
  }

  _check_svc "mission-control" "http://localhost:3031/health"
  _check_svc "cascade-router" "http://localhost:3032/health"
  _check_svc "specflow" "http://localhost:3006/health"
  _check_svc "sprint-board" "http://localhost:3030/api/projects"
  _check_svc "Oracle LLM" "http://192.168.0.192:11434/api/tags"
  _check_svc "Shard LLM" "http://192.168.0.11:11434/api/tags"
  echo ""

  # ── Context Infrastructure ───────────────────────────────────────────────
  echo "## mission-control Context Infrastructure"
  echo ""
  echo "| File | Status | Lines |"
  echo "|------|--------|-------|"

  _check_file() {
    local label="$1"
    local path="$2"
    if [[ -f "$path" ]]; then
      local lines
      lines=$(wc -l < "$path" | tr -d ' ')
      echo "| $label | ✓ exists | $lines |"
    else
      echo "| $label | ✗ MISSING | — |"
    fi
  }

  _check_file "CLAUDE.md" "$MC/CLAUDE.md"
  _check_file ".claude/rules/pipeline-safety.md" "$MC/.claude/rules/pipeline-safety.md"
  _check_file ".claude/commands/start.md" "$MC/.claude/commands/start.md"
  _check_file ".claude/commands/wrap.md" "$MC/.claude/commands/wrap.md"
  _check_file "memory/MEMORY.md" "$MC_MEMORY/MEMORY.md"
  _check_file "memory/pipeline.md" "$MC_MEMORY/pipeline.md"
  _check_file "memory/services.md" "$MC_MEMORY/services.md"
  _check_file "memory/specflow.md" "$MC_MEMORY/specflow.md"
  _check_file "memory/infrastructure.md" "$MC_MEMORY/infrastructure.md"
  _check_file "memory/d2a-audit.md" "$MC_MEMORY/d2a-audit.md"
  _check_file "memory/swarm-state.md" "$MC_MEMORY/swarm-state.md"
  echo ""

  # ── wordsynk Cleanup ─────────────────────────────────────────────────────
  echo "## wordsynk Cleanup Status"
  echo ""
  WS="$HOME/Projects/wordsynk-automation-sys"

  echo "| Item | Status |"
  echo "|------|--------|"

  [[ -d "$WS/agents/_archive/dispatcher-herald-legacy" ]] \
    && echo "| Herald dispatcher archived | ✓ done |" \
    || echo "| Herald dispatcher archived | ✗ not done |"

  [[ ! -d "$WS/agents/dispatcher" ]] \
    && echo "| agents/dispatcher/ removed | ✓ done |" \
    || echo "| agents/dispatcher/ removed | ✗ still exists |"

  [[ -f "$WS/d2a.config.json" ]] \
    && echo "| d2a.config.json created | ✓ done |" \
    || echo "| d2a.config.json created | ✗ missing |"

  [[ ! -f "$WS/.claude/rules/pipeline-safety.md" ]] \
    && echo "| pipeline-safety.md removed | ✓ done |" \
    || echo "| pipeline-safety.md removed | ✗ still present |"

  [[ ! -f "$WS/SESSION_NEXT.md" ]] \
    && echo "| SESSION_NEXT.md deleted | ✓ done |" \
    || echo "| SESSION_NEXT.md deleted | ✗ still present |"
  echo ""

  # ── E2E Test Results ─────────────────────────────────────────────────────
  echo "## E2E Test Results"
  echo ""
  E2E_REPORT=$(ls "$MC_MEMORY"/e2e-results-*.md 2>/dev/null | tail -1)
  if [[ -n "$E2E_REPORT" ]]; then
    echo "Report: \`$(basename $E2E_REPORT)\`"
    echo ""
    # Extract verdict line
    VERDICT=$(grep -i "VERDICT\|verdict" "$E2E_REPORT" 2>/dev/null | head -3)
    if [[ -n "$VERDICT" ]]; then
      echo "**Verdict**: $VERDICT"
    else
      echo "_No VERDICT section found in E2E report_"
    fi
  else
    echo "_No E2E results found._"
  fi
  echo ""

  # ── Post-Extraction Assessment ───────────────────────────────────────────
  echo "## Post-Extraction Assessment"
  echo ""
  if [[ -f "$MC_MEMORY/post-extraction-assessment.md" ]]; then
    VERDICT=$(grep -i "OVERALL_VERDICT\|EXTRACTION COMPLETE\|overall verdict" \
      "$MC_MEMORY/post-extraction-assessment.md" 2>/dev/null | head -3)
    echo "**Assessment file**: \`memory/post-extraction-assessment.md\`"
    echo ""
    echo "**Overall verdict**: $VERDICT"
  else
    echo "_Post-extraction assessment not found._"
  fi
  echo ""

  # ── Log File Index ───────────────────────────────────────────────────────
  echo "## Log Files"
  echo ""
  echo "All logs in: \`$RESULTS_DIR/\`"
  echo ""
  for log in "$RESULTS_DIR"/sprint-*.log; do
    [[ -f "$log" ]] || continue
    SPRINT=$(basename "$log" .log)
    LINES=$(wc -l < "$log" | tr -d ' ')
    echo "- \`$(basename $log)\` — $LINES lines"
  done
  echo ""

  # ── Next Steps ───────────────────────────────────────────────────────────
  echo "## Next Steps"
  echo ""
  if [[ -f "$MC/SESSION_NEXT.md" ]]; then
    echo "_From \`mission-control/SESSION_NEXT.md\`_:"
    echo ""
    head -30 "$MC/SESSION_NEXT.md"
  else
    echo "_SESSION_NEXT.md not created — Sprint 16 may not have completed._"
    echo ""
    echo "Manual next steps:"
    echo "1. Review any failed sprints in the Run Summary above"
    echo "2. Check service health and fix DOWN services"
    echo "3. Re-run failed sprints: \`bash run-sprints.sh --from N\`"
  fi
  echo ""
  echo "---"
  echo ""
  echo "_Generated by d2a Autonomous Sprint Runner — agent-forge_"

} > "$REPORT_FILE"

echo "Final report written to: $REPORT_FILE"
echo ""
cat "$REPORT_FILE"
