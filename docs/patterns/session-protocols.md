# Pattern: Session Protocols

## Problem
Knowledge evaporates between sessions. Without explicit handoff, each session starts from scratch.

## Solution
Lightweight session start and wrap protocols that manage knowledge persistence.

## Session Start Protocol

### Lightweight (Hook-Based, Automatic)
SessionStart hook injects ~200 tokens automatically:
- Current git branch + clean/dirty status
- Whether SESSION_NEXT.md exists (continuation vs fresh)
- Last 3 MEMORY.md operational rules

### Full (Command-Based, User-Invoked)
`/start` command for sprint or complex sessions:
1. Git health check (status, tracking, stashes, mainline)
2. Fix any git issues BEFORE briefing
3. Push corrective actions BEFORE briefing
4. Read session continuation file if exists
5. Create task list from sprint goals
6. Brief the operator (< 20 lines)

### Key Rules
- Git fix BEFORE briefing (never defer push to after briefing)
- If dirty tree: commit or stash, push, then brief
- Total startup should be < 5 turns for light sessions, < 10 for sprints

## Session Wrap Protocol

### Required Steps
1. **Git:** Commit outstanding changes, push all, verify remote
2. **Behavioral knowledge:** Update rule files for subsystems deeply explored this session
3. **ADRs:** Write Y-statement ADRs for significant decisions made
4. **Incidents:** Record any self-detected errors with structured format
5. **Stale check:** Flag any rule files that may be outdated based on code changes
6. **Session next:** If continuation needed, write handoff file

### Behavioral Knowledge Checkpoint
This is the critical step most projects skip. Before wrapping:
- Did the agent build deep understanding of any subsystem? → Write/update its behavioral rule file
- Did the operator correct any domain understanding? → Capture in rule file immediately
- Did any "I didn't know that" moment occur? → Capture in appropriate knowledge file

### Anti-Patterns
- Wrap = just git push (no knowledge persistence)
- Wrap = 30-minute documentation update (too heavy)
- No wrap at all (knowledge loss guaranteed)

## Session Continuation

### Handoff File
`SESSION_NEXT.md` — written during wrap, read during start:
- What was being worked on
- What's next
- Anything that would be lost if only documentation were read
- Git branch to continue on

### Memory Updates
During wrap, update auto-memory topic files:
- `memory/MEMORY.md` — new operational rules (if earned through incidents)
- `memory/<topic>.md` — domain-specific learnings

### ADR Updates
During wrap, append new decisions to `docs/decisions/`:
- Only for decisions the agent would need to reconstruct behavior
- Use Y-statement format
- Include rejected alternatives (prevents re-proposing)
