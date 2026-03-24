# WORKDIR: wordsynk-automation-sys
# MODEL: sonnet
# PAUSE: no
# TIMEOUT: 900

# Sprint 05 — cascade-router Migration

## Context

The cascade-router service (port :3032) still physically lives inside `wordsynk-automation-sys/cascade-router/`.
It should live in `mission-control/cascade-router/` since it's a d2a infrastructure component, not a booking automation component.

Sprint 05 migrates it safely:
1. Stop the service
2. Copy the directory to mission-control
3. Update the launchd plist to point to the new location
4. Reload and verify

**CRITICAL**: This service must keep running. The cascade-router is used by every LLM call in the d2a pipeline. Verify health at every step.

## Steps

### Step 1: Verify Current State

```bash
# Check service is running
curl -sf http://localhost:3032/health || echo "cascade-router NOT running"

# Check current location
ls cascade-router/
cat cascade-router/package.json | python3 -c "import json,sys; d=json.load(sys.stdin); print('name:', d.get('name'), 'version:', d.get('version'))"

# Check plist location and content
find ~/Library/LaunchAgents -name "*cascade-router*" 2>/dev/null
cat ~/Library/LaunchAgents/com.wordsynk.cascade-router.plist 2>/dev/null || echo "no launchd plist found"

# Check if running as pm2 or other process manager
pm2 list 2>/dev/null | grep cascade || echo "not in pm2"
ps aux | grep cascade-router | grep -v grep || echo "no cascade-router process"
```

Record: where the service is running from, what process manager, what plist path.

### Step 2: Create Target Directory

```bash
mkdir -p /Users/pawelgiers/Projects/mission-control/cascade-router
```

### Step 3: Stop cascade-router

Stop the service gracefully:

```bash
# Try launchd first
launchctl stop com.wordsynk.cascade-router 2>/dev/null && echo "stopped via launchd" || echo "launchd stop failed"

# Wait for process to die
sleep 3

# Verify stopped
curl -sf http://localhost:3032/health && echo "STILL RUNNING — need to force kill" || echo "stopped successfully"

# Force kill if still running
pkill -f "cascade-router" 2>/dev/null || true
sleep 2
```

### Step 4: Copy cascade-router to mission-control

```bash
# Copy everything except node_modules (will reinstall)
rsync -av --exclude='node_modules' --exclude='.git' \
  cascade-router/ \
  /Users/pawelgiers/Projects/mission-control/cascade-router/

# Verify copy
ls /Users/pawelgiers/Projects/mission-control/cascade-router/
ls /Users/pawelgiers/Projects/mission-control/cascade-router/data/
```

### Step 5: Install dependencies in new location

```bash
cd /Users/pawelgiers/Projects/mission-control/cascade-router
npm install 2>&1 | tail -5
```

### Step 6: Update launchd plist

Read the current plist:
```bash
cat ~/Library/LaunchAgents/com.wordsynk.cascade-router.plist
```

Update the ProgramArguments path: change the wordsynk path to the mission-control path.

The WorkingDirectory entry should also be updated.

If the plist references:
- `/Users/pawelgiers/Projects/wordsynk-automation-sys/cascade-router`

Change to:
- `/Users/pawelgiers/Projects/mission-control/cascade-router`

After editing, reload:
```bash
launchctl unload ~/Library/LaunchAgents/com.wordsynk.cascade-router.plist
launchctl load ~/Library/LaunchAgents/com.wordsynk.cascade-router.plist
sleep 5
```

If no launchd plist exists, start directly:
```bash
cd /Users/pawelgiers/Projects/mission-control/cascade-router
nohup node server.js > /tmp/cascade-router.log 2>&1 &
sleep 3
```

### Step 7: Verify Service Health

```bash
curl -sf http://localhost:3032/health
echo ""
# Also test the cascade resolve endpoint
curl -sf "http://localhost:3032/api/cascade/resolve?tier=L2" || curl -sf "http://localhost:3032/api/cascade" || echo "resolve endpoint not responding"
```

The health check must succeed. If it fails, check:
```bash
cat /tmp/cascade-router.log 2>/dev/null | tail -20
# OR check launchd logs
log show --predicate 'subsystem == "com.apple.launchd"' --last 5m 2>/dev/null | grep cascade || true
```

### Step 8: Update memory/services.md

In `/Users/pawelgiers/Projects/mission-control/memory/services.md`, update the cascade-router entry:
- Status: RUNNING
- WORKDIR: /Users/pawelgiers/Projects/mission-control/cascade-router (updated from wordsynk)
- Note: "Migrated from wordsynk-automation-sys in Sprint 05"

## Expected Outputs

1. `/Users/pawelgiers/Projects/mission-control/cascade-router/` exists with all files
2. `http://localhost:3032/health` responds (service running from new location)
3. launchd plist updated to point to new path (if plist existed)
4. `memory/services.md` updated with new cascade-router path
