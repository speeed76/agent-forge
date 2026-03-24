# WORKDIR: wordsynk-automation-sys
# MODEL: opus
# PAUSE: no
# TIMEOUT: 1200

# Sprint 09 — Docker Swarm Fix

## Context

Sprint 08 investigated Docker Swarm state and wrote `mission-control/memory/swarm-state.md` with a diagnosis.

Sprint 09 executes the fix (or documents why no fix is needed).

**Infrastructure for Swarm**:
- Manager: Mac Mini (192.168.0.26) — THIS machine
- Worker 1: Ubuntu Server — `ssh -p 2222 pawel@192.168.0.11`
- Worker 2: Mac Studio — `ssh pawelgiers@192.168.0.192`

## Steps

### Step 1: Read Sprint 08 Findings

```bash
cat /Users/pawelgiers/Projects/mission-control/memory/swarm-state.md
```

**Decision tree based on FIX_REQUIRED field**:

- If `FIX_REQUIRED: false` or "SKIP": Go directly to Step 6 (document conclusion)
- If `FIX_REQUIRED: true` with Tailscale fix: Execute Steps 2-5
- If `FIX_REQUIRED: true` with fresh init: Execute Steps 3-5

### Step 2: Reset Swarm (if misconfigured with Tailscale IPs)

If current swarm uses Tailscale IPs (`100.x.x.x`), reset it:

```bash
# Leave swarm on worker nodes first
ssh -o ConnectTimeout=10 pawelgiers@192.168.0.192 "docker swarm leave --force 2>/dev/null || echo 'not in swarm'" 2>/dev/null || echo "Mac Studio unreachable"
ssh -o ConnectTimeout=10 -p 2222 pawel@192.168.0.11 "docker swarm leave --force 2>/dev/null || echo 'not in swarm'" 2>/dev/null || echo "Ubuntu unreachable"

# Leave/destroy on manager
docker swarm leave --force 2>/dev/null || echo "was not in swarm"
sleep 3
```

### Step 3: Initialize Swarm on Mac Mini (Manager)

```bash
docker swarm init --advertise-addr 192.168.0.26
```

Capture the join token:
```bash
WORKER_TOKEN=$(docker swarm join-token worker -q)
echo "Worker token: $WORKER_TOKEN"
```

### Step 4: Join Worker Nodes

Add Ubuntu Server:
```bash
ssh -o ConnectTimeout=15 -p 2222 pawel@192.168.0.11 \
  "docker swarm join --token $WORKER_TOKEN 192.168.0.26:2377" 2>/dev/null \
  && echo "Ubuntu joined" \
  || echo "Ubuntu join FAILED — may need Docker installed or firewall rule"
```

Add Mac Studio:
```bash
ssh -o ConnectTimeout=15 pawelgiers@192.168.0.192 \
  "docker swarm join --token $WORKER_TOKEN 192.168.0.26:2377" 2>/dev/null \
  && echo "Mac Studio joined" \
  || echo "Mac Studio join FAILED"
```

Verify:
```bash
sleep 3
docker node ls
```

### Step 5: Add Node Labels and Update docker-stack.yml

Add role labels to nodes:
```bash
# Get node IDs
docker node ls --format "{{.ID}} {{.Hostname}}"

# Label Mac Mini (manager) as control
docker node update --label-add role=control $(docker node ls --format "{{.ID}}" --filter "role=manager" | head -1)

# Label Ubuntu as compute
UBUNTU_NODE=$(docker node ls --format "{{.ID}} {{.Hostname}}" | grep -i ubuntu | awk '{print $1}')
if [[ -n "$UBUNTU_NODE" ]]; then
  docker node update --label-add role=compute "$UBUNTU_NODE"
fi

# Label Mac Studio as compute
STUDIO_NODE=$(docker node ls --format "{{.ID}} {{.Hostname}}" | grep -v ubuntu | grep -v "$(hostname)" | awk '{print $1}' | head -1)
if [[ -n "$STUDIO_NODE" ]]; then
  docker node update --label-add role=compute "$STUDIO_NODE"
fi
```

Update docker-stack.yml placement constraints:
- Change any Tailscale IP references to use `node.labels.role` constraints instead
- Add `node.role == manager` constraint for management services
- Add `node.labels.role == compute` for worker services

Read and update the file. If it already uses label-based constraints (not IPs), no change needed.

### Step 6: Update swarm-state.md

Update `/Users/pawelgiers/Projects/mission-control/memory/swarm-state.md`:

Add a new section **SPRINT09_RESULT**:

If swarm was fixed:
```
## SPRINT09_RESULT
Status: FIXED
Date: [today]
Manager: Mac Mini (192.168.0.26)
Workers: Ubuntu Server, Mac Studio
Worker token: [token]
docker node ls output: [paste]
```

If swarm was not needed:
```
## SPRINT09_RESULT
Status: NOT_NEEDED
Date: [today]
Reason: GHA runners use direct docker run, not Swarm services.
docker-stack.yml is aspirational architecture — label as such.
Action taken: Added comment to docker-stack.yml noting aspirational status.
```

### Step 7: Handle "Swarm Not Needed" Case

If the investigation showed Swarm is not needed for current operations:

1. Add a comment header to docker-stack.yml:
```yaml
# ASPIRATIONAL ARCHITECTURE — Not currently deployed
# This file describes the target Docker Swarm topology for the d2a pipeline.
# Current deployment: GHA runners use direct docker run commands.
# To deploy when ready: docker stack deploy -c docker-stack.yml d2a
```

2. Note this clearly in swarm-state.md.

## Expected Outputs

**If swarm was fixed**:
1. `docker node ls` shows 2-3 Ready nodes
2. docker-stack.yml updated with label-based placement constraints
3. swarm-state.md has SPRINT09_RESULT section with token

**If swarm not needed**:
1. swarm-state.md has SPRINT09_RESULT section with "NOT_NEEDED" and reason
2. docker-stack.yml has aspirational comment header
3. Verify script will accept "documented as not needed" as a passing result
