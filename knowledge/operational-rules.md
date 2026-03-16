# Operational Rules

Rules that emerged from real-world agent operation. These are universal — they apply to any project, not a specific codebase.

---

## Rule 1: API-First for Live Operations

Any request touching live data, rules, decisions, or engine state must use the project's API, never direct database access. Direct DB is read-only diagnostics only.

**Origin:** Multiple incidents where direct SQLite writes caused state inconsistencies that the application layer didn't know about.

## Rule 2: Plain English → API Mapping

Establish a mapping table from natural language instructions to API calls. The agent should interpret immediately without asking clarification.

Example:
| User says | Agent does |
|-----------|------------|
| "go live" | `PUT /settings {"enabled": true}` |
| "pause" | `PUT /settings {"enabled": false}` |

**Benefit:** Eliminates 2-3 clarification turns per request. The operator speaks in domain language; the agent translates to API calls.

## Rule 3: Check State Before Changing State

Before modifying any system configuration, read the current state first. Flag contradictions (e.g., "set strategy" when engine is disabled).

**Origin:** Missed auto-accept because the engine was disabled. Agent set up rules without checking if the engine was running.

## Rule 4: Git Is Agent-Owned

The human does not run git commands. The agent manages branches, commits, pushes, and PRs.

**Protocol:**
- On session start: health check (status, tracking, stashes, mainline connection)
- During work: commit atomically by domain, push after milestones, verify branch before commit
- On session wrap: push all, verify remote, drop stale stashes
- Never accumulate > 5 unpushed commits
- Never commit directly to main

## Rule 5: Push Before Briefing

When session start fixes a dirty tree (commit, stash, etc.), the corrective git actions must execute BEFORE the briefing output. The user should never need to prompt for push.

**Origin:** Session committed a fix but deferred push until user prompted.

## Rule 6: Apology → Action Protocol

When the agent detects its own error, "sorry" is a trigger, not a resolution. Every self-detected error MUST produce:
1. Root cause — what specific data/assumption was wrong
2. Prevention — a concrete artifact change
3. Scope check — did the same flaw contaminate other output?

## Rule 7: Past Incidents Are Immutable

Explain what happened (forensic). Frame ALL corrective actions as future prevention. If root cause is a code logic gap, propose the code patch. Never change a setting "to fix" a past incident.

## Rule 8: Never require() to Verify Compilation

`require()` in Node.js executes top-level code. Use `node --check` for syntax verification. All one-shot scripts must use `if (require.main === module)` guard.

## Rule 9: Visual-First SPA Changes

Before making ANY UI/design change to a single-page application: capture screenshots first, read them, then design the patch. Never patch UI blind.

## Rule 10: Domain Knowledge Capture on Correction

When the operator corrects the agent's understanding ("that's not how it works"), immediately capture the corrected knowledge in a behavioral rule file. Not in the conversation, not in a comment — in a persistent file that loads automatically.

## Rule 11: Operator Feedback Is Architecture Signal

When the operator says any variant of:
- "you should have known that"
- "we discussed this before"
- "that's not how it works"
- "why are you exploring that again?"

This is not a conversational correction — it is an architecture signal that behavioral knowledge is missing from the persistent context. The fix is always a rule file update.

## Rule 12: Token Budget Awareness

Every token in the always-loaded context displaces a token of working memory. Behavioral content belongs in path-scoped rules, not root CLAUDE.md. API references belong in domain rules, not global memory.

## Rule 13: Session Wrap Must Generate Behavioral Artifacts

Session wrap is not just git cleanup and status. The agent must:
- Update behavioral summaries for subsystems it deeply explored
- Write new ADRs for significant decisions made
- Flag any rule files that may be stale based on code changes observed
- Record incidents with structured format

## Rule 14: No Exploratory Paralysis

If the agent is reading its 4th file without having produced any output, it's missing behavioral context. Stop reading, check if a rule file exists for this domain. If not, that's the root problem — not more source code reading.

## Rule 15: Scope Matching

Match the scope of actions to what was actually requested. A bug fix doesn't need surrounding code cleaned up. A filter change doesn't need the test framework restructured. Authorization for one action does not imply authorization for adjacent actions.
