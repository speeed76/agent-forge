# WORKDIR: wordsynk-automation-sys
# MODEL: sonnet
# PAUSE: no
# TIMEOUT: 900

# Sprint 01 — Infrastructure Reconnaissance + Oracle Fix

## Context

You are running as an autonomous agent inside the `wordsynk-automation-sys` project.

This is Sprint 01 of a 16-sprint d2a extraction pipeline. Your job is to:
1. Fix the Oracle LLM endpoint so cascade-router can reach it
2. Discover GCP SSH secret names
3. Read the infrastructure documentation
4. Create `mission-control/memory/infrastructure.md`

## Known Infrastructure (baked in — trust this)

| Machine | LAN IP | Tailscale IP | SSH user | Port | Role |
|---------|--------|-------------|----------|------|------|
| Mac Mini | 192.168.0.26 | 100.87.14.34 | pawelgiers | 22 | d2a control plane (THIS machine) |
| Mac Studio | 192.168.0.192 | 100.94.226.127 | pawelgiers | 22 | Oracle LLM (qwen3-coder:30b) |
| Ubuntu Server | 192.168.0.11 | 100.100.49.58 | pawel | 2222 | Shard LLM (qwen2.5-coder:14b) |
| MacBook Pro 2 | 192.168.0.43 | 100.119.96.105 | pawelgiers | 22 | Primary dev |
| MacBook Pro i5 | 192.168.0.48 | 100.85.94.81 | pawelgiers | 22 | Secondary dev |

All SSH uses `~/.ssh/id_ed25519`.

GCP projects: `thebigword-calendar` (Anthropic API keys), `personal-assistant-app-434609` (SSH keys + addresses).
Service account credentials: `~/.secrets/fleet-ssh-sa.json` (SSH secrets), `~/.secrets/fleet-agent-sa.json` (API keys).

Service ports: mission-control :3031, cascade-router :3032, specflow :3006/:3002, sprint-board :3030, oracle :11434, shard :11434

## Steps

### Step 1: Fix Oracle LAN Accessibility

Check if Mac Studio's Ollama is reachable on LAN:

```bash
curl -sf http://192.168.0.192:11434/api/tags
```

If this FAILS (connection refused or timeout), Ollama on Mac Studio is bound to localhost only.
Fix it via SSH:

```bash
ssh pawelgiers@192.168.0.192 "launchctl setenv OLLAMA_HOST '0.0.0.0'"
ssh pawelgiers@192.168.0.192 "launchctl stop homebrew.mxcl.ollama || true"
ssh pawelgiers@192.168.0.192 "launchctl start homebrew.mxcl.ollama"
sleep 5
curl -sf http://192.168.0.192:11434/api/tags
```

If launchctl approach fails, try:
```bash
ssh pawelgiers@192.168.0.192 "pkill ollama || true; sleep 2; OLLAMA_HOST=0.0.0.0 nohup ollama serve > /tmp/ollama.log 2>&1 &"
sleep 5
curl -sf http://192.168.0.192:11434/api/tags
```

Record result (working or not, what models are available).

### Step 2: Check Shard LAN Accessibility

```bash
curl -sf http://192.168.0.11:11434/api/tags
```

Record result.

### Step 3: Discover GCP SSH Secret Names

SSH to Mac Studio and check what SSH secret config exists:

```bash
ssh pawelgiers@192.168.0.192 "grep -i 'gcp_secret\|SECRET_NAME\|fleet-ssh' ~/.zshrc ~/.bashrc 2>/dev/null || echo 'no gcp secret refs found'"
ssh pawelgiers@192.168.0.192 "ls ~/.secrets/ 2>/dev/null || echo 'no .secrets dir'"
```

Also check on Mac Mini (this machine):
```bash
grep -i 'gcp_secret\|SECRET_NAME\|fleet-ssh' ~/.zshrc ~/.bashrc 2>/dev/null || echo 'no gcp secret refs found'
ls ~/.secrets/ 2>/dev/null
```

If `fleet-ssh-sa.json` exists and list permission is available:
```bash
GOOGLE_APPLICATION_CREDENTIALS=~/.secrets/fleet-ssh-sa.json \
  gcloud secrets list --project=personal-assistant-app-434609 --format="value(name)" 2>/dev/null || echo "list not available"
```

Record all secret names found.

### Step 4: Read pg-home-infrastructure Documentation

Use the GitHub CLI to read the infrastructure repo CLAUDE.md:

```bash
gh api repos/speeed76/pg-home-infrastructure/contents/CLAUDE.md --jq '.content' | base64 -d 2>/dev/null || echo "repo not accessible"
```

If accessible, also read machine files:
```bash
gh api repos/speeed76/pg-home-infrastructure/contents/ --jq '.[].name' 2>/dev/null
```

Record any additional infrastructure details found.

### Step 5: Create mission-control/memory/infrastructure.md

Create the file at `/Users/pawelgiers/Projects/mission-control/memory/infrastructure.md`.

First ensure the directory exists:
```bash
mkdir -p /Users/pawelgiers/Projects/mission-control/memory
```

Write a comprehensive infrastructure reference with these sections:
- **FLEET** — full table of all machines (LAN IP, Tailscale IP, SSH user, port, role)
- **SSH** — how to connect to each machine (exact commands)
- **ORACLE** — Oracle LLM endpoint status (was it LAN-accessible? what fix was applied? what's the correct endpoint now?)
- **SHARD** — Shard LLM endpoint status
- **SERVICES** — service port map
- **GCP_SECRETS** — project names, SA credential file paths, discovered secret names
- **SWARM** — placeholder section: "INVESTIGATION PENDING — see Sprint 08"
- **NOTES** — anything unusual discovered during recon

The file should be comprehensive enough that any future agent starting a session knows exactly how to reach every service and machine without any SSH or curl trial-and-error.

## Expected Outputs

1. Mac Studio Ollama is reachable at `http://192.168.0.192:11434/api/tags` (verified)
2. File created: `/Users/pawelgiers/Projects/mission-control/memory/infrastructure.md`
3. File contains sections: FLEET, SSH, ORACLE, SHARD, SERVICES, GCP_SECRETS, SWARM, NOTES
4. ORACLE section accurately reflects current state (what was broken, what was fixed, current correct endpoint)
