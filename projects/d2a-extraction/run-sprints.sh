#!/usr/bin/env bash
# d2a Autonomous Sprint Runner
# Usage: bash run-sprints.sh [--from N] [--to N] [--only N,M,...] [--dry-run]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPRINTS_DIR="$SCRIPT_DIR/sprints"
VERIFY_DIR="$SCRIPT_DIR/verify"
RESULTS_DIR="$SCRIPT_DIR/results"

# Full model IDs for short names
MODEL_SONNET="claude-sonnet-4-6"
MODEL_OPUS="claude-opus-4-6"
MODEL_HAIKU="claude-haiku-4-5-20251001"

# Base directory for relative WORKDIRs
PROJECTS_BASE="$HOME/Projects"

# ─── CLI arg parsing ─────────────────────────────────────────────────────────
FROM_SPRINT=1
TO_SPRINT=16
ONLY_SPRINTS=""
DRY_RUN=false

usage() {
  echo "Usage: $0 [--from N] [--to N] [--only N,M,...] [--dry-run]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --from)    FROM_SPRINT="$2"; shift 2 ;;
    --to)      TO_SPRINT="$2"; shift 2 ;;
    --only)    ONLY_SPRINTS="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown argument: $1"; usage ;;
  esac
done

# ─── Helper functions ─────────────────────────────────────────────────────────

resolve_model() {
  local short="$1"
  case "$short" in
    sonnet) echo "$MODEL_SONNET" ;;
    opus)   echo "$MODEL_OPUS" ;;
    haiku)  echo "$MODEL_HAIKU" ;;
    *)      echo "$short" ;;  # pass through if already a full ID
  esac
}

parse_frontmatter() {
  local file="$1"
  local key="$2"
  grep "^# ${key}:" "$file" 2>/dev/null | head -1 | sed "s/^# ${key}: *//" | tr -d '\r'
}

get_sprint_file() {
  local num="$1"
  local padded
  padded=$(printf "%02d" "$num")
  find "$SPRINTS_DIR" -name "${padded}-*.md" 2>/dev/null | head -1
}

get_sprint_numbers() {
  if [[ -n "$ONLY_SPRINTS" ]]; then
    echo "$ONLY_SPRINTS" | tr ',' '\n' | sed 's/[[:space:]]//g' | sort -n
  else
    seq "$FROM_SPRINT" "$TO_SPRINT"
  fi
}

resolve_workdir() {
  local raw="$1"
  # Expand ~
  raw="${raw/#\~/$HOME}"
  # If already absolute, use as-is
  if [[ "$raw" == /* ]]; then
    echo "$raw"
  else
    echo "$PROJECTS_BASE/$raw"
  fi
}

# ─── Sprint execution ─────────────────────────────────────────────────────────

run_sprint() {
  local num="$1"
  local padded
  padded=$(printf "%02d" "$num")

  local sprint_file
  sprint_file=$(get_sprint_file "$num")

  if [[ -z "$sprint_file" || ! -f "$sprint_file" ]]; then
    echo "ERROR: No sprint file found for sprint $num in $SPRINTS_DIR"
    return 1
  fi

  # Parse frontmatter
  local raw_workdir model_short pause_flag timeout sprint_title
  raw_workdir=$(parse_frontmatter "$sprint_file" "WORKDIR")
  model_short=$(parse_frontmatter "$sprint_file" "MODEL")
  pause_flag=$(parse_frontmatter "$sprint_file" "PAUSE")
  timeout=$(parse_frontmatter "$sprint_file" "TIMEOUT")
  sprint_title=$(grep "^# Sprint" "$sprint_file" | head -1 | sed 's/^# Sprint [0-9]* — //' | sed 's/^# //')

  local workdir full_model
  workdir=$(resolve_workdir "$raw_workdir")
  full_model=$(resolve_model "$model_short")
  timeout="${timeout:-900}"
  pause_flag="${pause_flag:-no}"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Sprint $padded — $sprint_title"
  echo "  WORKDIR: $workdir"
  echo "  MODEL:   $full_model"
  echo "  TIMEOUT: ${timeout}s"
  [[ "$pause_flag" == "yes" ]] && echo "  PAUSE:   YES (human step required)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY RUN] Skipping execution"
    return 0
  fi

  # ── Handle PAUSE step ────────────────────────────────────────────────────
  if [[ "$pause_flag" == "yes" ]]; then
    local continue_file="$RESULTS_DIR/sprint-${padded}.continue"
    echo ""
    echo "⏸  PAUSE — Human action required before Sprint $padded can run."
    echo ""

    # Print Pause Instructions section from sprint file
    local in_section=false
    while IFS= read -r line; do
      if [[ "$line" =~ ^##\ Pause\ Instructions ]]; then
        in_section=true
        echo "── Pause Instructions ───────────────────────────────────────────"
        continue
      fi
      if [[ "$in_section" == true ]]; then
        [[ "$line" =~ ^## ]] && break
        echo "$line"
      fi
    done < "$sprint_file"

    echo ""
    echo "When done, create the continue file:"
    echo "  touch $continue_file"
    echo ""
    echo "Or re-run from this sprint:"
    echo "  bash $SCRIPT_DIR/run-sprints.sh --from $num"
    echo ""

    local waited=0
    while [[ ! -f "$continue_file" ]]; do
      echo -n "Waiting for $continue_file ... (${waited}s elapsed)\r"
      sleep 10
      waited=$((waited + 10))
    done
    echo ""
    echo "Continue file found. Running sprint $padded..."
  fi

  # ── Verify workdir ───────────────────────────────────────────────────────
  if [[ ! -d "$workdir" ]]; then
    echo "ERROR: WORKDIR does not exist: $workdir"
    echo "  Create it first, then re-run: bash $SCRIPT_DIR/run-sprints.sh --from $num"
    return 1
  fi

  local log_file="$RESULTS_DIR/sprint-${padded}.log"
  echo "Running sprint in $workdir ..."
  echo "Log: $log_file"
  echo ""

  # ── Execute claude ───────────────────────────────────────────────────────
  _run_claude_sprint "$sprint_file" "$workdir" "$full_model" "$timeout" "$log_file"
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    echo ""
    echo "WARNING: Sprint $padded exited with code $exit_code. Retrying once..."
    local retry_log="$RESULTS_DIR/sprint-${padded}-retry.log"

    _run_claude_sprint "$sprint_file" "$workdir" "$full_model" "$timeout" "$retry_log"
    local retry_exit=$?

    if [[ $retry_exit -ne 0 ]]; then
      echo ""
      echo "ERROR: Sprint $padded failed after retry (exit $retry_exit)"
      echo "  Log: $retry_log"
      return 1
    fi

    cp "$retry_log" "$log_file"
    echo "Retry succeeded. Using retry log as canonical."
  fi

  # ── Run verification ─────────────────────────────────────────────────────
  local check_script="$VERIFY_DIR/check-${padded}.sh"
  if [[ -f "$check_script" ]]; then
    echo ""
    echo "Running verification: check-${padded}.sh ..."
    local check_exit=0
    bash "$check_script" "$log_file" "$workdir" 2>&1 || check_exit=$?

    if [[ $check_exit -ne 0 ]]; then
      echo ""
      echo "VERIFICATION FAILED — Sprint $padded"
      echo "  Check script:  $check_script"
      echo "  Sprint log:    $log_file"
      echo "  Fix the issue, then re-run: bash $SCRIPT_DIR/run-sprints.sh --from $num"
      return 1
    fi

    echo "✓ Sprint $padded — verification passed"
  else
    echo "WARNING: No check script at $check_script — skipping verification"
  fi

  # Write sprint summary to results
  echo "Sprint $padded: PASS — $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$RESULTS_DIR/run-summary.txt"
  return 0
}

_with_timeout() {
  local secs="$1"; shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$secs" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$secs" "$@"
  else
    # No timeout binary available — run unbounded
    "$@"
  fi
}

_run_claude_sprint() {
  local sprint_file="$1"
  local workdir="$2"
  local model="$3"
  local timeout_sec="$4"
  local log_file="$5"

  local exit_code=0
  # Pipe sprint file via stdin to avoid quoting issues with multi-line content.
  # Unset CLAUDECODE to allow launching claude from within a claude session.
  (
    unset CLAUDECODE
    cd "$workdir"
    _with_timeout "$timeout_sec" claude \
      --print \
      --model "$model" \
      --dangerously-skip-permissions \
      < "$sprint_file" \
      2>&1
  ) | tee "$log_file"
  exit_code=${PIPESTATUS[0]}

  return $exit_code
}

# ─── Main ─────────────────────────────────────────────────────────────────────

mkdir -p "$RESULTS_DIR"

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║              d2a Autonomous Sprint Runner                       ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
  echo "DRY RUN MODE — printing sprint plan only (no execution)"
fi

SPRINT_NUMS=$(get_sprint_numbers)
TOTAL=$(echo "$SPRINT_NUMS" | wc -l | tr -d ' ')
COMPLETED=0

echo "" > "$RESULTS_DIR/run-summary.txt"

for num in $SPRINT_NUMS; do
  sprint_file=$(get_sprint_file "$num")
  if [[ -z "$sprint_file" ]]; then
    echo "WARNING: Sprint $num has no file in $SPRINTS_DIR — skipping"
    continue
  fi

  if ! run_sprint "$num"; then
    echo ""
    echo "═══════════════════════════════════════════════════════════════════"
    echo "  STOPPED at sprint $num"
    echo "  Completed: $COMPLETED / $TOTAL"
    echo "  Resume:    bash $SCRIPT_DIR/run-sprints.sh --from $num"
    echo "═══════════════════════════════════════════════════════════════════"
    exit 1
  fi

  COMPLETED=$((COMPLETED + 1))
done

echo ""
echo "═══════════════════════════════════════════════════════════════════"
echo "  ALL SPRINTS COMPLETE — $COMPLETED / $TOTAL"
echo "═══════════════════════════════════════════════════════════════════"

if [[ -f "$VERIFY_DIR/final-report.sh" ]] && [[ "$DRY_RUN" == "false" ]]; then
  echo ""
  echo "Generating final report..."
  bash "$VERIFY_DIR/final-report.sh" "$RESULTS_DIR"
fi

exit 0
