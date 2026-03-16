# /res — Session Resume Protocol

Focused session resume. Faster than `/start` — skip full orientation, go straight to the work.

## Model Routing

| Phase | Model | Why |
|-------|-------|-----|
| Data gathering | `haiku` | Read files, run scripts, parse output |
| Briefing + work | main context | Decision-making, task execution |

## Step 1: Haiku Data Gather

Launch Haiku subagent (`model: "haiku"`, `subagent_type: "Bash"`):
```
Gather session resume data. Run these commands and return ALL output:

1. [read handover block — e.g., head -50 SESSION.md]
2. [health check — e.g., bash scripts/agent-health.sh]
3. [service status — e.g., bash scripts/session-status.sh]
4. [agent detection — e.g., bash scripts/agent-detect.sh]
5. [tracker drift check — e.g., bash scripts/board-drift-check.sh]
```

## Step 2: Brief

Using the Haiku output:

```
**Resuming from:** [what was being worked on at session close]
**Next action:** [the exact first action from the handover block]
**Services:** [status of key services]
**[Tracker]:** [active sprint + done/total, or "offline"]
**Health:** [pass / N issues]
**Blockers:** [any flagged issues, or "none"]
```

- If agent detected → co-pilot mode. Do NOT begin sprint work.
- If health FAIL → run fix script before continuing.
- Do not give a full project overview. Do not re-explain architecture.

## Step 3: Execute

Begin the first ready task immediately unless it requires a user decision.
