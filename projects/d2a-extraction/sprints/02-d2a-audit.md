# WORKDIR: wordsynk-automation-sys
# MODEL: sonnet
# PAUSE: no
# TIMEOUT: 900

# Sprint 02 — d2a Full Audit + cascade-config Fix

## Context

Sprint 01 fixed the Oracle LAN binding and created `mission-control/memory/infrastructure.md`.

Sprint 02 fixes the cascade-router Oracle endpoint and produces a comprehensive audit of all d2a-touching code.

**Critical misconfiguration known**: `cascade-config.json` Oracle backend is currently set to `http://100.94.226.127:11434/v1` (Mac Studio Tailscale IP). Mac Studio's Ollama is now LAN-accessible at `http://192.168.0.192:11434`. The Tailscale address is wrong because Mac Studio's Ollama was only bound to localhost — now that it's fixed to `0.0.0.0`, the correct endpoint is the LAN IP.

Relevant paths:
- `cascade-config.json` → `cascade-router/data/cascade-config.json`
- `cascade-router/` → full service at `wordsynk-automation-sys/cascade-router/`
- `mission-control/` → `/Users/pawelgiers/Projects/mission-control/`

## Steps

### Step 1: Fix cascade-config.json Oracle Endpoint

Read the current cascade-config.json:
```bash
cat cascade-router/data/cascade-config.json
```

Find the Oracle backend entry. It should have a URL containing `100.94.226.127:11434`.

Update it to use the LAN IP:
- Find: `http://100.94.226.127:11434`
- Replace with: `http://192.168.0.192:11434`

Use a targeted edit to change only the Oracle URL. Do NOT change any other fields.

After updating, verify the change:
```bash
grep "11434" cascade-router/data/cascade-config.json
```

### Step 2: Restart cascade-router

Check if cascade-router is running:
```bash
curl -sf http://localhost:3032/health || echo "not running"
```

If it's running via launchd, restart it to pick up the config change:
```bash
launchctl stop com.wordsynk.cascade-router 2>/dev/null || true
sleep 2
launchctl start com.wordsynk.cascade-router 2>/dev/null || true
sleep 3
curl -sf http://localhost:3032/health || echo "still not running after restart"
```

If launchd isn't used, find and restart the process:
```bash
pgrep -f "cascade-router" || echo "not running as process"
# If it's a node process, check:
pm2 list 2>/dev/null || echo "no pm2"
```

### Step 3: Audit All d2a-Touching Files

Read the following files to build a complete picture of the d2a pipeline:

**mission-control** (`/Users/pawelgiers/Projects/mission-control/`):
```bash
ls /Users/pawelgiers/Projects/mission-control/ 2>/dev/null || echo "mission-control is EMPTY or missing"
ls /Users/pawelgiers/Projects/mission-control/memory/ 2>/dev/null || echo "no memory dir"
```

**wordsynk SESSION.md** — read for pipeline context:
```bash
cat SESSION.md | head -200
```

**wordsynk agents/** — survey what's there:
```bash
find agents/ -name "*.js" -o -name "*.py" -o -name "*.ts" | head -30
ls agents/
```

**cortex** (`/Users/pawelgiers/Projects/cortex/`):
```bash
ls /Users/pawelgiers/Projects/cortex/ 2>/dev/null || echo "cortex not found"
find /Users/pawelgiers/Projects/cortex/runtime/ -name "*.py" 2>/dev/null | head -20
grep -l "import anthropic" /Users/pawelgiers/Projects/cortex/runtime/*.py 2>/dev/null || echo "no direct anthropic imports"
```

**cascade-router status**:
```bash
ls cascade-router/
cat cascade-router/data/cascade-config.json | python3 -m json.tool | head -60
```

### Step 4: Capture Docker/Swarm State

```bash
docker info 2>/dev/null | grep -E "Swarm:|Manager:|Nodes:|Is Manager" || echo "docker info failed"
docker node ls 2>/dev/null || echo "not a swarm manager or swarm not initialized"
```

Record the full output — Sprint 08 will analyze it in detail.

### Step 5: Write d2a-audit.md

Create `/Users/pawelgiers/Projects/mission-control/memory/d2a-audit.md` with these sections:

**ORACLE_FIX** — Document what was wrong (Tailscale IP, localhost-only Ollama) and what was changed (LAN IP, 0.0.0.0 binding). Include the old URL, new URL, and verification result.

**GAPS** — List all missing/broken things found:
- memory files that SESSION.md references but don't exist
- missing CLAUDE.md files
- missing .claude/ directories
- any broken service endpoints

**DIRECT_IMPORTS** — List every Python file in cortex/runtime that does `import anthropic` or `anthropic.Anthropic()`. Include file path + line numbers.

**CASCADE_ROUTER_LOCATION** — Current location of cascade-router/, whether it's still in wordsynk, what needs to move.

**LEGACY** — List legacy files/dirs in wordsynk that should be archived (dispatcher/, worker.py, reviewer.py, etc.)

**SWARM_STATE** — Paste the docker info / docker node ls output verbatim. Note: "detailed analysis in Sprint 08"

**SUMMARY** — Numbered list of all issues to fix, in priority order.

## Expected Outputs

1. `cascade-router/data/cascade-config.json` — Oracle URL updated to `http://192.168.0.192:11434/v1`
2. File created: `/Users/pawelgiers/Projects/mission-control/memory/d2a-audit.md`
3. d2a-audit.md contains sections: ORACLE_FIX, GAPS, DIRECT_IMPORTS, CASCADE_ROUTER_LOCATION, LEGACY, SWARM_STATE, SUMMARY
4. cascade-router health check at `:3032` responds (if service was running)
