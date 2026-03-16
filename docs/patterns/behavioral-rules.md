# Pattern: Behavioral Rule Files

## Problem
Structural knowledge (where files are, what functions exist) is easy to maintain but insufficient. The agent needs to understand HOW components work — operational semantics, data flows, edge cases, failure modes — without reading hundreds of lines of source code each session.

## Solution
Dense behavioral summary files that auto-load when the relevant source code is accessed.

## Structure

Each behavioral rule file contains five sections:

### 1. Behavioral Contract
Dense operational semantics. Not "what the function is called" but "what happens when it runs."

**Good example:**
```
evaluateOffer() acquires mutex, fetches active preset from DB, runs filters
in order: enabled → time_window → travel_gap (InPerson only) → client_allowlist
→ min_pay. First rejection halts. Accept triggers 2-5s human delay then API call.
```

**Bad example:**
```
evaluateOffer() is in decision_service.js and takes an offer object as parameter.
It returns a result object with accepted: boolean and reason: string.
```

The bad example restates the function signature. The good example describes behavior.

### 2. Domain Terms
Glossary for this bounded context. Terms that mean something specific here.

```
- **preset**: Named collection of filter rules. One active at a time. Loaded from DB.
- **pay floor**: Minimum acceptable total_pay. Derived from Rate Card v7 only (never historical DB).
```

### 3. Flow Narrative
The primary data path through this subsystem, numbered steps.

```
1. FCM notification → POST /notification → upsert offer in SQLite
2. evaluateNewOffers() cron (30s) picks up unevaluated offers
3. Active preset filters applied in sequence
4. Pass → human delay (2-5s) → PUT /api/accept
5. Logged to decision_log with full filter trace
```

### 4. Failure Modes
Symptom → Cause → Fix table. The knowledge that prevents repeat incidents.

```
| Symptom | Cause | Fix |
|---------|-------|-----|
| Valid offer rejected | Stale travel_gap for venue | Check venue postcodes |
| Double-accept race | Mutex scope too narrow | Verify mutex in evaluateNewOffers() |
```

### 5. Decision References
Links to ADRs explaining WHY things are built this way.

```
- [0002] Travel gap uses venue-to-venue Distance Matrix, not home-to-venue
- [0005] Rate Card v7 is sole source for pay floors
```

## Density Target

- 30-80 lines per rule file
- Compression ratio: 1 line of rule per 10-25 lines of source code
- If > 80 lines, split into sub-contexts
- If < 20 lines, may not need its own file

## Maintenance

- Agent updates behavioral summaries during session wrap
- When source changes structurally, agent flags rule files for review
- Behavioral summaries describe WHAT and WHY, not HOW (implementation details change; behavior is more stable)
- Version: last reviewed date in a comment at the bottom
