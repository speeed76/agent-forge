# WORKDIR: wordsynk-automation-sys
# MODEL: sonnet
# PAUSE: no
# TIMEOUT: 600

# Sprint 08 — Docker Swarm Investigation

## Context

The `docker-stack.yml` in wordsynk-automation-sys was configured using Tailscale IPs for the Docker Swarm.
This is wrong — Swarm should use LAN IPs (192.168.0.x).

Additionally, it's unclear whether Docker Swarm is actually needed given that the d2a pipeline uses GitHub Actions runners, not Docker Swarm services.

Sprint 08 investigates and documents the current state. Sprint 09 will fix it.

## Steps

### Step 1: Check Docker Swarm State

```bash
docker info 2>/dev/null | grep -E "Swarm:|Is Manager:|NodeID:|Managers:|Nodes:" || echo "docker info failed or not installed"
echo "---"
docker node ls 2>/dev/null || echo "NOT a swarm manager (or swarm not initialized)"
```

Record the full output verbatim.

### Step 2: Check Swarm Manager Config

If swarm is initialized:
```bash
docker info 2>/dev/null | grep -E "RemoteManagers:|Addr:|NodeAddr:" || true
```

What IP is the swarm manager using?

### Step 3: Read docker-stack.yml

```bash
cat docker-stack.yml 2>/dev/null || cat docker/docker-stack.yml 2>/dev/null || find . -name "docker-stack.yml" | head -5
```

Read the full file. Note:
- What services are defined?
- What placement constraints are used?
- What networks/volumes?
- Are Tailscale IPs referenced anywhere?
- Is this used for the d2a pipeline, booking automation, or both?

### Step 4: Check Install Scripts

```bash
cat /Users/pawelgiers/Projects/cortex/scripts/install-runner.sh 2>/dev/null | head -100 || echo "no install-runner.sh"
cat /Users/pawelgiers/Projects/cortex/scripts/*.sh 2>/dev/null | head -200 || echo "no scripts dir"
```

Does the install script use Docker Swarm? Or does it use direct docker run commands?

### Step 5: Check launchd/GHA Runner Configuration

```bash
# Check if GHA runners are running as launchd services
find ~/Library/LaunchAgents -name "*runner*" -o -name "*github*" 2>/dev/null
# Check for runner processes
ps aux | grep -E "Runner.Listener|actions-runner" | grep -v grep || echo "no GHA runner processes found"
# Check for runner directories
find ~/actions-runner ~/work ~/runners 2>/dev/null | head -20 || echo "standard runner paths not found"
find /Users/pawelgiers -maxdepth 3 -name "*.runner" -o -name "run.sh" 2>/dev/null | grep -v ".git" | head -10
```

### Step 6: Check for Tailscale in Swarm Config

```bash
grep -r "100\." docker-stack.yml 2>/dev/null | head -20 || echo "no Tailscale IPs in docker-stack.yml"
grep -r "tailscale\|100\.87\|100\.94\|100\.100" . 2>/dev/null | grep -v ".git" | head -20 || echo "no tailscale refs found"
```

### Step 7: Attempt Worker Node SSH Check

Check if worker nodes are reachable:
```bash
ssh -o ConnectTimeout=5 -o BatchMode=yes pawelgiers@192.168.0.192 "docker info 2>/dev/null | grep 'Swarm:'" 2>/dev/null && echo "Mac Studio Docker Swarm state above" || echo "Mac Studio SSH failed or Docker not available"
ssh -o ConnectTimeout=5 -o BatchMode=yes -p 2222 pawel@192.168.0.11 "docker info 2>/dev/null | grep 'Swarm:'" 2>/dev/null && echo "Ubuntu Server Docker Swarm state above" || echo "Ubuntu Server SSH failed or Docker not available"
```

### Step 8: Write swarm-state.md

Create `/Users/pawelgiers/Projects/mission-control/memory/swarm-state.md`.

Sections:

**CURRENT_STATE** — Paste verbatim output of `docker info` (swarm section) and `docker node ls`.

**MANAGER_IP** — What IP is the swarm manager advertising? (Tailscale or LAN?)

**NODE_STATUS** — For each expected node (Mac Mini, Mac Studio, Ubuntu), what's the current join status?

**DOCKER_STACK_ANALYSIS** — What does docker-stack.yml define? Is it being used? What services would it deploy?

**GHA_RUNNER_ANALYSIS** — How are GitHub Actions runners deployed? Launchd? Docker? Manual? Does the pipeline actually need Docker Swarm?

**DIAGNOSIS** — Root cause of the swarm misconfiguration (or confirmation that swarm isn't actually needed).

Possible diagnoses:
- "Swarm initialized with Tailscale IPs — needs reinit with LAN IPs"
- "Swarm not initialized — was never set up"
- "Swarm initialized correctly but workers not joined"
- "Swarm not needed — GHA runners use direct docker run, not swarm services"

**FIX_REQUIRED** — Boolean + what Sprint 09 should do. If swarm is not needed: "SKIP — document that docker-stack.yml is aspirational architecture, not current deployment". If swarm is needed but broken: describe exact fix steps.

## Expected Outputs

1. File created: `/Users/pawelgiers/Projects/mission-control/memory/swarm-state.md`
2. Contains "manager" keyword
3. Contains a "DIAGNOSIS" section with a clear finding
4. Contains "FIX_REQUIRED" section that Sprint 09 can act on
