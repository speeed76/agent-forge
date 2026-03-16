# /start — Session Start Protocol

## Step 1: Git Health Check
Run these commands and evaluate results:
```bash
git branch --show-current
git status --short | head -20
git stash list
git log --oneline -3
git merge-base main HEAD >/dev/null 2>&1 && echo "MAINLINE=connected" || echo "MAINLINE=DISCONNECTED"
```

### Fix Before Proceeding
| Issue | Action |
|-------|--------|
| Dirty working tree | Commit staged work or stash |
| Behind remote | `git pull --rebase` |
| MAINLINE=DISCONNECTED | Investigate — do not proceed |
| Stale stashes | Inspect; drop if contents committed |
| Unpushed > 5 | Push immediately |

**If any git issue found: fix and push BEFORE the briefing.**

## Step 2: Session Continuity
Check if SESSION_NEXT.md exists:
- If yes: read it, this is a continuation session
- If no: orientation mode — check recent git log and ask operator for direction

## Step 3: Briefing
Output a compact block (< 15 lines):
- Git: branch, clean/dirty, behind/ahead
- Mode: sprint / orientation / continuation
- Goal: what this session will accomplish
- First task: what to start on

## Step 4: Execute
- Sprint mode: begin first task immediately
- Orientation mode: ask operator for direction
- Continuation: resume from handoff point
