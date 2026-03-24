# WORKDIR: mission-control
# MODEL: sonnet
# PAUSE: no
# TIMEOUT: 600

# Sprint 13 — mission-control Pre-flight Health Check

## Context

All infrastructure work is complete. Before running the E2E test, verify that all services are healthy and that the mission-control context infrastructure is complete.

WORKDIR: `/Users/pawelgiers/Projects/mission-control`

## Steps

### Step 1: Verify Context Infrastructure

```bash
echo "=== Context Infrastructure Check ==="
# CLAUDE.md
[ -f "CLAUDE.md" ] && echo "✓ CLAUDE.md exists ($(wc -l < CLAUDE.md) lines)" || echo "✗ CLAUDE.md MISSING"

# Rules
[ -f ".claude/rules/pipeline-safety.md" ] && echo "✓ pipeline-safety.md exists" || echo "✗ pipeline-safety.md MISSING"

# Commands
[ -f ".claude/commands/start.md" ] && echo "✓ start.md exists" || echo "✗ start.md MISSING"
[ -f ".claude/commands/wrap.md" ] && echo "✓ wrap.md exists" || echo "✗ wrap.md MISSING"

# Memory
[ -f "memory/MEMORY.md" ] && echo "✓ MEMORY.md exists" || echo "✗ MEMORY.md MISSING"
[ -f "memory/pipeline.md" ] && echo "✓ pipeline.md exists ($(wc -l < memory/pipeline.md) lines)" || echo "✗ pipeline.md MISSING"
[ -f "memory/services.md" ] && echo "✓ services.md exists" || echo "✗ services.md MISSING"
[ -f "memory/specflow.md" ] && echo "✓ specflow.md exists" || echo "✗ specflow.md MISSING"
[ -f "memory/infrastructure.md" ] && echo "✓ infrastructure.md exists" || echo "✗ infrastructure.md MISSING"
[ -f "memory/d2a-audit.md" ] && echo "✓ d2a-audit.md exists" || echo "✗ d2a-audit.md MISSING"
```

### Step 2: Service Health Checks

Run each check and record the result:

```bash
echo ""
echo "=== Service Health Checks ==="

# mission-control :3031
MC=$(curl -sf http://localhost:3031/health 2>/dev/null && echo "HEALTHY" || echo "DOWN")
echo "mission-control :3031 → $MC"

# cascade-router :3032
CR=$(curl -sf http://localhost:3032/health 2>/dev/null && echo "HEALTHY" || echo "DOWN")
echo "cascade-router :3032 → $CR"

# specflow :3006
SF=$(curl -sf http://localhost:3006/health 2>/dev/null && echo "HEALTHY" || echo "DOWN")
echo "specflow :3006 → $SF"

# sprint-board :3030
SB=$(curl -sf http://localhost:3030/api/projects 2>/dev/null && echo "HEALTHY" || echo "DOWN")
echo "sprint-board :3030 → $SB"

# Oracle LLM (Mac Studio LAN)
OR=$(curl -sf http://192.168.0.192:11434/api/tags 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'HEALTHY ({len(d[\"models\"])} models)')" 2>/dev/null || echo "DOWN")
echo "Oracle LLM :11434 → $OR"

# Shard LLM (Ubuntu Server)
SH=$(curl -sf http://192.168.0.11:11434/api/tags 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'HEALTHY ({len(d[\"models\"])} models)')" 2>/dev/null || echo "DOWN")
echo "Shard LLM :11434 → $SH"
```

### Step 3: Diagnose and Fix Failing Services

For each service that is DOWN, attempt to fix:

**mission-control (:3031)**:
```bash
# Find plist or startup method
find ~/Library/LaunchAgents -name "*mission-control*" 2>/dev/null | head -3
pm2 list 2>/dev/null | grep mission-control || true
# Try restarting
launchctl stop com.wordsynk.mission-control 2>/dev/null; launchctl start com.wordsynk.mission-control 2>/dev/null || true
sleep 3
curl -sf http://localhost:3031/health || echo "still down — manual fix needed"
```

**cascade-router (:3032)**:
```bash
# Check if it's running from new location (mission-control) or old (wordsynk)
ps aux | grep cascade-router | grep -v grep
launchctl stop com.wordsynk.cascade-router 2>/dev/null; launchctl start com.wordsynk.cascade-router 2>/dev/null || true
sleep 3
curl -sf http://localhost:3032/health || echo "still down"
```

**specflow (:3006)**:
```bash
find ~/Library/LaunchAgents -name "*specflow*" 2>/dev/null
launchctl stop com.wordsynk.specflow 2>/dev/null; launchctl start com.wordsynk.specflow 2>/dev/null || true
sleep 3
curl -sf http://localhost:3006/health || echo "still down"
```

**Oracle (Mac Studio)**:
```bash
# Sprint 01 should have fixed this — check LAN binding
ssh -o ConnectTimeout=5 pawelgiers@192.168.0.192 "curl -sf http://127.0.0.1:11434/api/tags >/dev/null && echo 'ollama running locally' || echo 'ollama not running'" 2>/dev/null
# If ollama is running but not LAN-accessible, re-apply fix from Sprint 01
ssh pawelgiers@192.168.0.192 "launchctl setenv OLLAMA_HOST '0.0.0.0' && launchctl stop homebrew.mxcl.ollama && launchctl start homebrew.mxcl.ollama" 2>/dev/null
sleep 5
curl -sf http://192.168.0.192:11434/api/tags | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d['models']), 'models')"
```

### Step 4: Re-run Health Checks After Fixes

```bash
echo ""
echo "=== Post-Fix Health Status ==="
services=(
  "http://localhost:3031/health|mission-control"
  "http://localhost:3032/health|cascade-router"
  "http://localhost:3006/health|specflow"
  "http://192.168.0.192:11434/api/tags|oracle-llm"
)

for entry in "${services[@]}"; do
  url="${entry%|*}"
  name="${entry#*|}"
  if curl -sf "$url" >/dev/null 2>&1; then
    echo "  ✓ $name"
  else
    echo "  ✗ $name (still down)"
  fi
done
```

### Step 5: Write Health Report

Create `memory/health-check-$(date +%Y-%m-%d).md`:

```
# Health Check — [DATE]

## Context Infrastructure
[paste Step 1 output]

## Service Health
[paste Step 4 output]

## Issues Found
[numbered list of anything that was down or degraded]

## Fixes Applied
[what was done to fix failing services]

## Blockers for E2E Test
[anything that must be fixed before Sprint 15 can run]
[if nothing: "None — all critical services healthy"]

## Recommendation
[PROCEED with Sprint 15 / HOLD until [specific issue] is resolved]
```

### Step 6: Verify Critical Path

For the E2E test to work, these MUST be healthy:
- mission-control :3031 (accepts pipeline POSTs)
- cascade-router :3032 (routes LLM calls)
- At least one LLM backend (Oracle OR Shard OR Claude API key)

```bash
MC_OK=$(curl -sf http://localhost:3031/health >/dev/null 2>&1 && echo "OK" || echo "FAIL")
CR_OK=$(curl -sf http://localhost:3032/health >/dev/null 2>&1 && echo "OK" || echo "FAIL")
echo "Critical path: mission-control=$MC_OK cascade-router=$CR_OK"

if [ "$MC_OK" = "FAIL" ] || [ "$CR_OK" = "FAIL" ]; then
  echo "CRITICAL PATH BROKEN — E2E test will fail. Fix required before Sprint 15."
else
  echo "Critical path healthy — E2E test can proceed."
fi
```

## Expected Outputs

1. `memory/health-check-[DATE].md` — health report file created
2. Report contains service status for all 6 services
3. `curl -sf http://localhost:3031/health` returns 200 or JSON with status field
4. Report has a "Recommendation" section (PROCEED or HOLD)
