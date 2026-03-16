# /wrap — Session Wrap Protocol

Work through every step in order. Do not skip steps.

## Model Routing

| Phase | Model | Why |
|-------|-------|-----|
| Builds + scripts + health | `haiku` | Bash execution, pass/fail |
| Write session entries | `sonnet` | Templated writing with session context |
| Update CLAUDE.md files | `sonnet` | Targeted doc edits |
| [Tracker reconciliation] | `haiku` | Script execution |
| Performance review | main context | Requires full conversation analysis |
| Final confirmation | main context | Assemble + report |

## Step 1: Haiku — Preflight Checks

Launch Haiku subagent (`model: "haiku"`, `subagent_type: "Bash"`):
```
Run these commands and return all output:
1. [build command — e.g., cd project && npm run build 2>&1 | tail -8]
2. [test command — e.g., cd project && npm test 2>&1 | tail -20]
3. [codemap/context snapshot — e.g., python3 scripts/codemap.py update]
4. [health check — e.g., bash scripts/agent-health.sh]
```

## Step 2: Sonnet — Write Session Entry

Launch Sonnet subagent (`model: "sonnet"`):

Read SESSION.md. Insert at TOP:

**Handover block:**
```
## Next Session Handover — [date] [time]
### Focus: [one-line description]
### State at session close
[2-4 sentences]
### Exact first action
[one concrete sentence + command]
### Files touched this session that matter next session
[bulleted list]
### Decisions / context to preserve
[reasoning, failed attempts, mid-investigation state]
```

**Wrap entry:**
```
## Session Wrap — [date]
### Work completed
[numbered list — what changed and why, not just file names]
### Files modified
| File | Change |
|------|--------|
### Open issues / next session priorities
[bulleted list]
### System state at close
- Build: [from Step 1]
- Services: [running/stopped]
```

## Step 3: Sonnet — Update CLAUDE.md (if needed)

Only if source code was modified. Launch Sonnet subagent:
- Remove completed TODOs, add new ones
- Update architecture sections if changed
- State current facts, not changelog entries

## Step 4: Behavioral Knowledge Checkpoint

For each subsystem deeply explored this session:
1. Does a behavioral rule file exist in `.claude/rules/`?
2. If no: write one using the behavioral-rule template
3. If yes: does it need updating based on what was learned?
4. Update the `<!-- Last reviewed: -->` date

## Step 5: Git Wrap (MANDATORY — never skip)

Launch Haiku subagent:
```
1. git status --short | head -20
2. git branch --show-current
3. git log --oneline @{upstream}..HEAD 2>/dev/null || echo "NO_UPSTREAM"
4. git stash list

If uncommitted changes: stage and commit.
If unpushed commits: git push origin $(git branch --show-current)

Verify:
5. git status --short         # must be empty
6. git log --oneline @{upstream}..HEAD  # must be empty
7. git branch -vv | grep "^\*"
```

**Exit criteria:** Working tree clean, 0 unpushed commits, no stale stashes.

## Step 6: [Tracker Reconciliation — if applicable]

Compare tracker state vs actual commits. PATCH any drift. Post session_end event.

## Step 7: Performance Review (MANDATORY)

Review the full conversation for:
- Prompting errors, omissions, operational rule violations
- Structural session mistakes (context management, scope creep)
- What the better approach would have been

Append findings to `[OPERATOR_FEEDBACK.md]`. Focus: mistakes and improvements, not accomplishments. A session with no errors worth noting is itself worth documenting.

## Step 8: Final Health Check

Launch Haiku subagent:
```
[health check script]
```
If any FAIL: run with `--fix` flag.

## Step 9: Confirm to User

Assemble outputs from all subagents. Report:
- What was written to SESSION.md
- What was updated in CLAUDE.md files
- Build/test results (pass/fail)
- **Git state:** branch, pushed (yes/no), clean (yes/no)
- [Tracker: reconciled/correct/total]
- Health check result
- Confirm: **"Session is safe to close."**
