# WORKDIR: mission-control
# MODEL: sonnet
# PAUSE: no
# TIMEOUT: 900

# Sprint 04 — mission-control Memory Reconstruction

## Context

Sprint 03 created the context infrastructure (CLAUDE.md, rules, commands).
Sprint 04 reconstructs the missing memory files that SESSION.md references but don't exist.

The wordsynk SESSION.md has been used for d2a pipeline handovers, but references memory files in `mission-control/memory/` that never existed. This sprint synthesizes that history into proper memory.

Source material to read:
- `/Users/pawelgiers/Projects/wordsynk-automation-sys/SESSION.md` — session history
- `/Users/pawelgiers/Projects/wordsynk-automation-sys/agents/CLAUDE.md` — pipeline behavioral context
- `/Users/pawelgiers/Projects/mission-control/memory/d2a-audit.md` — audit from Sprint 02
- `/Users/pawelgiers/Projects/mission-control/memory/infrastructure.md` — infra from Sprint 01

## Steps

### Step 1: Read All Source Material

Read the following files fully:

```bash
cat /Users/pawelgiers/Projects/wordsynk-automation-sys/SESSION.md
cat /Users/pawelgiers/Projects/wordsynk-automation-sys/agents/CLAUDE.md 2>/dev/null || echo "not found"
cat /Users/pawelgiers/Projects/mission-control/memory/d2a-audit.md
cat /Users/pawelgiers/Projects/mission-control/memory/infrastructure.md
```

Also check if SESSION_NEXT.md exists in wordsynk:
```bash
cat /Users/pawelgiers/Projects/wordsynk-automation-sys/SESSION_NEXT.md 2>/dev/null || echo "not found"
```

And read cortex README if it exists:
```bash
cat /Users/pawelgiers/Projects/cortex/README.md 2>/dev/null | head -100 || echo "no cortex README"
```

### Step 2: Create memory/MEMORY.md

This is the always-loaded project memory for mission-control.
Keep it under 200 lines — it's a navigation map + current state, NOT a log.

Required sections:
- **CURRENT STATE** — What sprint we're on, what's working, what's broken
- **PIPELINE STATUS** — Brief: is the d2a pipeline functional? Last known good state?
- **KNOWN ISSUES** — Numbered list of outstanding problems (from audit)
- **FORGE_PAT STATUS** — Is FORGE_PAT configured? When does it expire? What repos can it access?
- **COBALT STATUS** — cobalt-relay state, cobalt-sandbox state (from session history)
- **LINKS** — "For X, read Y" navigation table

Write to: `memory/MEMORY.md`

### Step 3: Create memory/pipeline.md

Dense behavioral summary of the d2a pipeline. This replaces re-reading wordsynk SESSION.md every session.

Required sections:
- **ARCHITECTURE** — Component map with responsibilities (not ports — those are in services.md)
- **CORTEX BOOTSTRAP** — How cortex runtime initializes, what it reads, what it requires
- **DUAL_PATH_SCAFFOLD** — The two scaffold paths (Path A: greenfield cobalt-sandbox, Path B: existing cobalt-relay). What triggers each. What differs.
- **FORGE_PAT** — Where it's stored, how it's injected into GHA runners, what happens if it's missing/expired
- **KNOWN VIOLATIONS** — Any architectural violations discovered (direct anthropic imports, missing cascade client usage, etc.)
- **PHASE_LOCK** — Build gates that must not be bypassed. What happens if you skip them.
- **INCIDENT_HISTORY** — Any incidents from wordsynk SESSION.md that affected the pipeline (brief: date, symptom, fix)

Write to: `memory/pipeline.md` (must be > 80 lines)

### Step 4: Create memory/services.md

Service registry. Authoritative reference for all services and their status.

Format for each service:
```
## service-name
- Port: NNNN
- Health: GET http://localhost:NNNN/health
- Process: launchd plist / pm2 / docker service
- Plist/config: path/to/config
- WORKDIR: /path/to/service
- Status: [RUNNING/STOPPED/UNKNOWN] — last verified Sprint NN
- Notes: anything important
```

Services to document (at minimum):
- mission-control (:3031)
- cascade-router (:3032)
- specflow (:3006 and :3002)
- sprint-board (:3030)
- oracle — Mac Studio (192.168.0.192:11434)
- shard — Ubuntu Server (192.168.0.11:11434)

For running services: verify health with curl before writing status.

Write to: `memory/services.md` (must contain ":3031" and ":3032")

### Step 5: Create memory/specflow.md

SpecFlow product facts. What is SpecFlow in this context? What does it do?

Read any specflow-related files to understand:
```bash
find /Users/pawelgiers/Projects -name "specflow*" -o -name "*specflow*" 2>/dev/null | grep -v ".git" | head -20
ls /Users/pawelgiers/Projects/specflow/ 2>/dev/null || echo "no specflow dir"
```

Sections:
- **PRODUCT** — What SpecFlow is (data spec lifecycle manager for d2a pipeline)
- **PORTS** — :3006 (main), :3002 (if different function)
- **API** — Key endpoints (if discoverable from code or README)
- **INTEGRATION** — How mission-control interacts with specflow
- **STATUS** — Current operational status

Write to: `memory/specflow.md`

## Expected Outputs

1. `memory/MEMORY.md` — current state, known issues, links table
2. `memory/pipeline.md` — > 80 lines, contains all 7 required sections
3. `memory/services.md` — contains ":3031" and ":3032" with full service entries
4. `memory/specflow.md` — product facts for SpecFlow
