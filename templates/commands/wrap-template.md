# /wrap — Session Wrap Protocol

Work through every step in order. Do not skip steps.

## Step 1: Git Cleanup
1. Check `git status` for uncommitted changes
2. Commit outstanding work (atomic commits by domain)
3. Push all to remote
4. Verify remote is up-to-date: `git log --oneline origin/BRANCH..HEAD` should be empty
5. Drop stale stashes if contents already committed

## Step 2: Behavioral Knowledge Checkpoint
For each subsystem deeply explored this session:
1. Does a behavioral rule file exist in `.claude/rules/`?
2. If no: write one using the behavioral-rule template
3. If yes: does it need updating based on what was learned?
4. Update the `<!-- Last reviewed: -->` date

## Step 3: Decision Records
For significant "why" decisions made this session:
1. Write a Y-statement ADR in `docs/decisions/`
2. Format: "In the context of [X], facing [Y], we decided [Z]..."
3. Include rejected alternatives

## Step 4: Incident Records
For any self-detected errors this session:
1. Record with structured format: trigger → root_cause → prevention → scope_check
2. Ensure a prevention artifact was created (rule file update, code guard, standing rule)

## Step 5: Stale Check
Review `.claude/rules/` files for the domains worked on:
1. Is any behavioral knowledge now outdated?
2. Were source files changed that would invalidate existing summaries?
3. Flag stale files for update

## Step 6: Session Continuation (if needed)
If work will continue in a future session:
1. Write SESSION_NEXT.md with: current state, next steps, anything that would be lost
2. Include the git branch to continue on

## Step 7: Summary
Output a brief wrap summary:
- Commits: N commits pushed to [branch]
- Knowledge: N rule files created/updated, N ADRs written
- Incidents: N recorded (or "none")
- Continuation: SESSION_NEXT.md written / session complete
