# /start — Session Start Protocol

## Model Routing

| Phase | Model | Why |
|-------|-------|-----|
| Data gathering | `haiku` | Read files, run scripts, parse output |
| Mode decision + briefing | main context | Requires judgment |

## Step 1: Haiku Data Gather

Launch a Haiku subagent (`model: "haiku"`, `subagent_type: "Bash"`):

```
Gather session startup data. Run these commands and return ALL output:

1. [read session state file — e.g., head -50 SESSION.md]
2. [health check script — e.g., bash scripts/agent-health.sh]
3. [service status script — e.g., bash scripts/session-status.sh]
4. [continuation check — e.g., test -s SESSION_NEXT.md && echo "SPRINT=exists" || echo "SPRINT=empty"]

Git health (MANDATORY — run all):
5. git branch --show-current
6. git branch -vv
7. git status --short | head -20
8. git stash list
9. git log --oneline -3
10. git merge-base main HEAD >/dev/null 2>&1 && echo "MAINLINE=connected" || echo "MAINLINE=DISCONNECTED"
```

## Step 1B: Git Health Evaluation (MANDATORY)

Using the Haiku output, fix problems **before any work begins**:

| Issue | Action |
|-------|--------|
| Dirty working tree | Commit staged work or stash. Never start on dirty tree. |
| Behind remote | `git pull --rebase` before starting. |
| MAINLINE=DISCONNECTED | **STOP.** Investigate and fix before proceeding. |
| Stale stashes | Inspect. Drop if contents already committed. |
| Unpushed > 5 | Push immediately. |
| Wrong branch for sprint | Switch to correct branch. |

## Step 2: Mode Decision

Using the Haiku output, determine mode:

**If [agent detection] reports "active agent"** → **Co-pilot mode.**
Do NOT begin sprint work. Ask operator what to focus on.

**If SESSION_NEXT.md exists with tasks** → **Sprint mode:**
- Read SESSION_NEXT.md
- Create TaskList entries from the sprint table
- [Board/tracker sync if applicable]
- Begin executing immediately

**If SESSION_NEXT.md does NOT exist** → **Orientation mode:**
- Read [ROADMAP.md or equivalent]
- Check recent git log
- Do NOT begin work. Ask operator for direction.

## Step 3: [Board/Tracker Sync — sprint mode only]

1. If SESSION_NEXT.md has a task mapping section → verify IDs exist on tracker. Post session_start.
2. If mapping missing → check tracker for matching sprint. If not found, create tasks.
3. If tracker offline → WARN and defer.

## Step 4: Briefing

Output a single compact block (< 20 lines):
- Services: [status of key services]
- Git: branch, clean/dirty, pushed
- Mode: sprint / orientation / co-pilot
- Goal: what this session will accomplish
- First task: what to start on (or suggested priorities)

Do not give a full project overview. Do not re-explain architecture.

## Step 5: Execute

- **Sprint mode:** Execute first task immediately (unless it requires a decision).
- **Orientation mode:** Ask operator what to focus on.
- **Co-pilot mode:** Ask operator what to focus on. Do NOT touch sprint tasks.
