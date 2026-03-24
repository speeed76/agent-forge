#!/usr/bin/env bash
# Shared verification functions for d2a-extraction sprint checks
# Usage: source verify/common.sh

PASS_COUNT=0
FAIL_COUNT=0
FAILURES=()

# ── Core assertions ──────────────────────────────────────────────────────────

check_file() {
  # check_file <path> [pattern] [label]
  local path="$1"
  local pattern="${2:-}"
  local label="${3:-$path}"

  if [[ ! -f "$path" ]]; then
    _fail "FILE MISSING: $label ($path)"
    return 1
  fi

  if [[ -n "$pattern" ]]; then
    if ! grep -q "$pattern" "$path" 2>/dev/null; then
      _fail "PATTERN NOT FOUND in $label: '$pattern'"
      return 1
    fi
  fi

  _pass "file: $label"
  return 0
}

check_dir() {
  # check_dir <path> [label]
  local path="$1"
  local label="${2:-$path}"

  if [[ ! -d "$path" ]]; then
    _fail "DIR MISSING: $label ($path)"
    return 1
  fi

  _pass "dir: $label"
  return 0
}

check_file_minlines() {
  # check_file_minlines <path> <min_lines> [label]
  local path="$1"
  local min="$2"
  local label="${3:-$path}"

  if [[ ! -f "$path" ]]; then
    _fail "FILE MISSING: $label"
    return 1
  fi

  local actual
  actual=$(wc -l < "$path" | tr -d ' ')
  if [[ "$actual" -lt "$min" ]]; then
    _fail "FILE TOO SHORT: $label has $actual lines (need >= $min)"
    return 1
  fi

  _pass "file-minlines: $label ($actual >= $min lines)"
  return 0
}

check_file_not_contains() {
  # check_file_not_contains <path> <pattern> [label]
  local path="$1"
  local pattern="$2"
  local label="${3:-$path}"

  if [[ ! -f "$path" ]]; then
    _fail "FILE MISSING: $label"
    return 1
  fi

  local count
  count=$(grep -c "$pattern" "$path" 2>/dev/null || echo "0")
  if [[ "$count" -gt 0 ]]; then
    _fail "PATTERN STILL PRESENT in $label: '$pattern' ($count occurrences)"
    return 1
  fi

  _pass "not-contains: $label (no '$pattern')"
  return 0
}

check_file_count_le() {
  # check_file_count_le <path> <pattern> <max_count> [label]
  local path="$1"
  local pattern="$2"
  local max="$3"
  local label="${4:-$path}"

  if [[ ! -f "$path" ]]; then
    _fail "FILE MISSING: $label"
    return 1
  fi

  local count
  count=$(grep -c "$pattern" "$path" 2>/dev/null || echo "0")
  if [[ "$count" -gt "$max" ]]; then
    _fail "TOO MANY OCCURRENCES in $label: '$pattern' found $count times (max $max)"
    return 1
  fi

  _pass "count-le: $label ('$pattern' count $count <= $max)"
  return 0
}

check_url() {
  # check_url <url> [label]
  local url="$1"
  local label="${2:-$url}"

  if curl -sf "$url" >/dev/null 2>&1; then
    _pass "url: $label"
    return 0
  else
    _fail "URL DOWN: $label ($url)"
    return 1
  fi
}

check_url_contains() {
  # check_url_contains <url> <pattern> [label]
  local url="$1"
  local pattern="$2"
  local label="${3:-$url}"

  local body
  body=$(curl -sf "$url" 2>/dev/null || echo "")
  if [[ -z "$body" ]]; then
    _fail "URL NOT RESPONDING: $label ($url)"
    return 1
  fi

  if echo "$body" | grep -q "$pattern" 2>/dev/null; then
    _pass "url-contains: $label ('$pattern')"
    return 0
  else
    _fail "URL MISSING PATTERN: $label expected '$pattern' in response"
    return 1
  fi
}

check_cmd() {
  # check_cmd <label> <cmd...>
  local label="$1"
  shift
  local cmd=("$@")

  if "${cmd[@]}" >/dev/null 2>&1; then
    _pass "cmd: $label"
    return 0
  else
    _fail "CMD FAILED: $label (${cmd[*]})"
    return 1
  fi
}

check_json() {
  # check_json <path> [label]
  local path="$1"
  local label="${2:-$path}"

  if [[ ! -f "$path" ]]; then
    _fail "FILE MISSING: $label"
    return 1
  fi

  if python3 -m json.tool "$path" >/dev/null 2>&1; then
    _pass "json: $label"
    return 0
  else
    _fail "INVALID JSON: $label"
    return 1
  fi
}

check_json_key() {
  # check_json_key <path> <key> [label]
  local path="$1"
  local key="$2"
  local label="${3:-$path}"

  if [[ ! -f "$path" ]]; then
    _fail "FILE MISSING: $label"
    return 1
  fi

  local val
  val=$(python3 -c "import json; d=json.load(open('$path')); print(d.get('$key', 'MISSING'))" 2>/dev/null || echo "MISSING")
  if [[ "$val" == "MISSING" ]]; then
    _fail "JSON KEY MISSING: '$key' in $label"
    return 1
  fi

  _pass "json-key: $label has '$key' = '$val'"
  return 0
}

check_no_pattern_in_file() {
  # check_no_pattern_in_file <path> <pattern> [label]
  check_file_not_contains "$@"
}

check_git_commit() {
  # check_git_commit <repo_path> <pattern_in_message> [label]
  local repo="$1"
  local pattern="$2"
  local label="${3:-git commit}"

  local msg
  msg=$(git -C "$repo" log --oneline -1 2>/dev/null || echo "")
  if echo "$msg" | grep -qi "$pattern"; then
    _pass "git-commit: $label"
    return 0
  else
    _fail "GIT COMMIT NOT FOUND: $label (looking for '$pattern' in '$msg')"
    return 1
  fi
}

# ── Internal helpers ──────────────────────────────────────────────────────────

_pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  ✓ $1"
}

_fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  FAILURES+=("$1")
  echo "  ✗ $1"
}

print_summary() {
  local sprint_label="${1:-Sprint}"
  echo ""
  echo "─── $sprint_label Verification ───────────────────────────────────"
  echo "  Passed: $PASS_COUNT"
  echo "  Failed: $FAIL_COUNT"

  if [[ ${#FAILURES[@]} -gt 0 ]]; then
    echo ""
    echo "  Failures:"
    for f in "${FAILURES[@]}"; do
      echo "    • $f"
    done
    echo ""
    return 1
  else
    echo "  All checks passed."
    echo ""
    return 0
  fi
}
