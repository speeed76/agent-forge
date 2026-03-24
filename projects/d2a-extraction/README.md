# d2a Autonomous Sprint Runner

Cleans up the d2a (data-to-app) pipeline regression in a cascade of 16 verified autonomous sprints.

## The Problem

The d2a pipeline regressed to stateless behavior:
- Agent context lives in `wordsynk-automation-sys` instead of `mission-control`
- `memory/pipeline.md`, `memory/services.md` referenced in SESSION.md do not exist
- `mission-control` has no CLAUDE.md, no `.claude/`, no `memory/`
- cascade-router still lives inside `wordsynk/cascade-router/`
- cortex runtime scripts import `anthropic` directly, bypassing cascade router
- Docker Swarm was configured with Tailscale IPs (wrong — should use LAN IPs)
- Legacy Herald JS dispatcher still present in wordsynk

## One Command to Fix It

```bash
# From agent-forge:
cd /Users/pawelgiers/Projects/agent-forge
bash projects/d2a-extraction/run-sprints.sh
```

## Options

```bash
# Resume from sprint N after failure:
bash projects/d2a-extraction/run-sprints.sh --from 5

# Run only specific sprints:
bash projects/d2a-extraction/run-sprints.sh --only 3,4,5

# Dry run (print sprint titles + workdirs, no execution):
bash projects/d2a-extraction/run-sprints.sh --dry-run

# Run through sprint N only:
bash projects/d2a-extraction/run-sprints.sh --to 8
```

## Sprint Sequence

| # | Title | WORKDIR | Model | PAUSE |
|---|-------|---------|-------|-------|
| 01 | Infrastructure Reconnaissance + Oracle Fix | wordsynk-automation-sys | sonnet | no |
| 02 | d2a Full Audit + cascade-config Fix | wordsynk-automation-sys | sonnet | no |
| 03 | mission-control Context Infrastructure | mission-control | sonnet | no |
| 04 | mission-control Memory Reconstruction | mission-control | sonnet | no |
| 05 | cascade-router Migration | wordsynk-automation-sys | sonnet | no |
| 06 | cortex cascade_client.py Audit | cortex | sonnet | no |
| 07 | cortex Direct Import Refactor | cortex | opus | no |
| 08 | Docker Swarm Investigation | wordsynk-automation-sys | sonnet | no |
| 09 | Docker Swarm Fix | wordsynk-automation-sys | opus | no |
| 10 | wordsynk: Archive Legacy Agents | wordsynk-automation-sys | haiku | no |
| 11 | wordsynk: Clean Context | wordsynk-automation-sys | sonnet | no |
| 12 | wordsynk: Reconnection Config | wordsynk-automation-sys | haiku | no |
| 13 | mission-control Pre-flight Health Check | mission-control | sonnet | no |
| 14 | cobalt-sandbox Initialization | mission-control | haiku | **YES** |
| 15 | E2E Smoke Test: PawsOnLeash (Path A) | mission-control | opus | no |
| 16 | E2E Assessment + Final Handover | mission-control | opus | no |

## Prerequisites (Run Once Before Starting)

### 1. Grant secret-list permission to fleet-sa-mac-mini

```bash
gcloud config set account pawel.giers@gmail.com
gcloud projects add-iam-policy-binding personal-assistant-app-434609 \
  --member="serviceAccount:fleet-sa-mac-mini@personal-assistant-app-434609.iam.gserviceaccount.com" \
  --role="roles/secretmanager.viewer"
gcloud config set account fleet-sa-mac-mini@personal-assistant-app-434609.iam.gserviceaccount.com
```

### 2. Verify SSH access to Mac Studio

```bash
ssh pawelgiers@192.168.0.192 "echo ok && ollama list | head -5"
```

## Sprint 14 PAUSE Instructions

Sprint 14 requires manual GitHub setup:

1. `cd /tmp && git clone https://github.com/speeed76/cobalt-sandbox.git`
2. `cd cobalt-sandbox && echo '# cobalt-sandbox' > README.md && git add . && git commit -m 'init' && git push`
3. Go to GitHub → Settings → Developer Settings → FORGE_PAT → add cobalt-sandbox to allowlist
4. Create file: `projects/d2a-extraction/results/sprint-14.continue`

## Output

All sprint logs in `results/sprint-NN.log`.
Final report in `results/FINAL_REPORT.md`.

## Infrastructure Reference

| Machine | LAN IP | Role |
|---------|--------|------|
| Mac Mini | 192.168.0.26 | d2a control plane (all services) |
| Mac Studio | 192.168.0.192 | Oracle LLM (qwen3-coder:30b) |
| Ubuntu Server | 192.168.0.11 | Shard LLM (qwen2.5-coder:14b) |

**Service ports**: mission-control :3031, cascade-router :3032, specflow :3006/:3002, sprint-board :3030, oracle :11434, shard :11434
