# WORKDIR: mission-control
# MODEL: sonnet
# PAUSE: no
# TIMEOUT: 900

# Sprint 03 — mission-control Context Infrastructure

## Context

Sprints 01-02 fixed Oracle endpoint and produced audit files.
Sprint 03 gives `mission-control` its agent context infrastructure: CLAUDE.md, rules, and commands.

`mission-control` is the d2a (data-to-app) control plane at `/Users/pawelgiers/Projects/mission-control`.
It is NOT a booking automation system — it orchestrates the pipeline that turns data specs into deployed applications.

The pipeline flow:
1. Operator POSTs spec to mission-control `:3031/api/pipeline/run`
2. mission-control routes LLM calls through cascade-router `:3032`
3. cascade-router selects: Oracle (qwen3-coder:30b on Mac Studio), Shard (qwen2.5-coder:14b on Ubuntu), or Claude API
4. cortex runtime executes: decomposer → scheduler → operationalizer → cla (code linting assistant)
5. specflow `:3006` manages spec lifecycle
6. Forge agent (GHA runner) generates PRs to target repos
7. Sentinel validates, Arbiter merges/rejects
8. sprint-board `:3030` tracks progress

## Steps

### Step 1: Survey Current State

```bash
ls -la /Users/pawelgiers/Projects/mission-control/ 2>/dev/null || echo "EMPTY — creating from scratch"
ls /Users/pawelgiers/Projects/mission-control/.claude/ 2>/dev/null || echo "no .claude dir"
```

Also read the wordsynk agents/CLAUDE.md for pipeline context clues:
```bash
cat /Users/pawelgiers/Projects/wordsynk-automation-sys/agents/CLAUDE.md 2>/dev/null | head -100 || echo "not found"
```

### Step 2: Create Directory Structure

```bash
mkdir -p /Users/pawelgiers/Projects/mission-control/{.claude/rules,.claude/commands,memory}
```

### Step 3: Create mission-control/CLAUDE.md

Write a comprehensive CLAUDE.md for mission-control. This is the always-loaded root context. It should be a navigation map + safety rules (NOT behavioral detail — that belongs in rules files).

Required sections:
1. **Identity** — what mission-control is (d2a control plane), what it is NOT (booking system)
2. **Service Map** — all services with ports, health endpoints, brief description
3. **Pipeline Flow** — 7-step data path (spec → POST → cascade → cortex → forge → sentinel → arbiter)
4. **Repository Map** — which repos this pipeline touches and their roles
5. **Domain Navigation** — table: "When working on X, read Y"
6. **Safety Rules** — cascade router invariant (NEVER bypass), Docker sandbox rules, build gates
7. **Standing Protocols** — session start/wrap commands

The CLAUDE.md should be at least 120 lines. Reference `.claude/rules/pipeline-safety.md` for behavioral contracts.

Write to: `CLAUDE.md` (you are already in mission-control WORKDIR)

### Step 4: Create .claude/rules/pipeline-safety.md

This rule file auto-loads when working on any pipeline-related code.

Frontmatter:
```yaml
---
paths:
  - "**/*.py"
  - "**/*.js"
  - "**/*.ts"
  - "cascade-router/**"
  - "cortex/**"
  - "memory/**"
---
```

Content sections:
1. **Behavioral Contract** — cascade router is mandatory for all LLM calls. Direct `import anthropic` in runtime code = violation. The cascade router resolves tier (L1/L2/L3) to the correct backend. It handles fallback automatically.
2. **Domain Terms** — Oracle (Mac Studio qwen3-coder:30b), Shard (Ubuntu qwen2.5-coder:14b), tier (L1=cheapest, L3=best), spec (input data spec), FORGE_PAT (GitHub token for Forge agent), cobalt-relay/cobalt-sandbox (target repos)
3. **Flow Narrative** — 6-step cascade flow: spec POST → mission-control validates → cascade-router resolves tier → cortex runtime executes → forge generates PR → sentinel/arbiter validate
4. **Failure Modes** — Oracle unreachable (check LAN IP 192.168.0.192:11434, not Tailscale), cascade-router down (restart plist), FORGE_PAT expired (check GitHub PAT), cortex import error (check cascade_client.py)
5. **Decision References** — "cascade-router migration: see Sprint 05 log"

### Step 5: Create .claude/commands/start.md

A `/start` command for beginning a mission-control session:

```
---
description: Begin a mission-control session — load state, check services, orient
---
```

Steps:
1. Read `memory/MEMORY.md` for session state
2. Read `memory/pipeline.md` for current pipeline status
3. Run health checks: `:3031`, `:3032`, Oracle, Shard
4. Read latest `memory/health-check-*.md` if exists
5. Report: service statuses, current sprint (from sprint-board if running), any blocking issues
6. Confirm: "Ready. [N services healthy]. Current focus: [from MEMORY.md]"

### Step 6: Create .claude/commands/wrap.md

A `/wrap` command for ending a mission-control session:

```
---
description: End a mission-control session — update memory, write handover
---
```

Steps:
1. Update `memory/MEMORY.md` — current pipeline state, any incidents
2. Update `memory/pipeline.md` — latest FORGE_PAT status, any new violations
3. Update `memory/services.md` — any service status changes
4. Write `SESSION_NEXT.md` — top 3 tasks for next session, blockers, relevant log files
5. Commit all memory changes: `git add memory/ SESSION_NEXT.md && git commit -m "session wrap: [date]"`

## Expected Outputs

1. `CLAUDE.md` — at least 120 lines, contains all required sections
2. `.claude/rules/pipeline-safety.md` — has YAML frontmatter + 5 content sections
3. `.claude/commands/start.md` — has frontmatter + 5-step protocol
4. `.claude/commands/wrap.md` — has frontmatter + 5-step protocol
5. All files contain "cascade router" reference (verifies behavioral focus)
