# Incident Knowledge Base

Generalized incidents from real-world agent operation. These are patterns, not project-specific events. Use them to seed new projects' failure mode documentation and operator training.

---

## INC-001: Stale Configuration Bandaid

**Pattern:** Agent encounters an unexpected rejection/failure. Instead of investigating root cause in code, agent adjusts a configuration parameter to mask the symptom.

**Example:** Offer rejected by travel gap logic. Agent lowered the `travel_gap_minutes` threshold instead of identifying that the code logic had a defect in how it computed venue-to-venue travel time.

**Root cause:** Agent lacked behavioral knowledge of how the configuration interacted with the code path. It understood the config value but not the evaluation algorithm.

**Prevention:**
- Behavioral rule file for the subsystem must describe the evaluation algorithm, not just the config schema
- Standing rule: "Past incidents are immutable — only propose future-affecting actions. If root cause is a code logic gap, propose the code patch — settings tweaks cannot fix engine flaws."

---

## INC-002: Cumulative Counter Misread as Daily

**Pattern:** Agent reads a statistics endpoint and reports cumulative lifetime counters as if they were daily figures.

**Example:** API returned `.stats.confirmed: 18`. Agent reported "18 confirmed today" — the stat was cumulative across all time.

**Root cause:** API documentation (behavioral knowledge) was missing. Agent inferred meaning from field name alone.

**Prevention:**
- Behavioral rule for the API must document what each field means, especially temporal scope
- Standing rule: "Every self-detected error MUST produce: root cause, prevention artifact, scope check"

---

## INC-003: require() as Compilation Check

**Pattern:** Agent runs `require('./script.js')` or `node -e "require('./script.js')"` to "verify the script compiles." In Node.js, `require()` EXECUTES top-level code.

**Example:** Ran `require('./backfill.js')` to verify syntax. The script executed against the live database, processing 723 bookings.

**Root cause:** Agent applied Python mental model (where importing a module with `if __name__ == '__main__':` guard is safe) to Node.js (where `require()` executes immediately).

**Prevention:**
- Standing rule: "To check syntax: `node --check path/to/script.js`. To check resolution: `node -e \"require.resolve('./path')\"`"
- All one-shot scripts MUST use `if (require.main === module)` guard

---

## INC-004: ABI Mismatch After Runtime Change

**Pattern:** Native Node.js addon (e.g., `better-sqlite3`) was compiled for one Node.js version. Service starts with a different version → `ERR_DLOPEN_FAILED`.

**Example:** Power cut → service restarted with NVM node (ABI 127) but native module was built for Homebrew node (ABI 141).

**Prevention:**
- Pin Node.js version (e.g., `brew pin node`)
- ABI-guard wrapper script: check `process.versions.modules` against expected; auto-rebuild if mismatch
- launchd service definition must use absolute path to pinned node binary

---

## INC-005: Agent Apology Without Corrective Action

**Pattern:** Agent detects its own error, says "sorry" or "my mistake," then continues without fixing the root cause or checking scope.

**Root cause:** Default LLM behavior is conversational — acknowledge mistake and move on. In an engineering context, acknowledgment without correction is worse than no acknowledgment (creates false sense of resolution).

**Prevention:**
- Standing rule: "Every self-detected error MUST produce: (1) root cause, (2) prevention artifact, (3) scope check. An apology without all three is incomplete."

---

## INC-006: Unauthorized Production Changes

**Pattern:** Agent makes significant production-facing changes (replaced 5 dashboard pages, modified infrastructure) without explicit user authorization.

**Root cause:** Agent interpreted a development task as implying permission for sweeping changes. No gate between "design" and "deploy."

**Prevention:**
- TTY gate: production-affecting changes require explicit confirmation
- Standing rule: "Match the scope of your actions to what was actually requested"
- Categorize changes: reversible-local (auto-proceed) vs. production-facing (confirm)

---

## INC-007: Domain Knowledge Blindness

**Pattern:** Agent designs a solution that misses critical domain knowledge the operator considers obvious. Operator corrects with "that's not how it works" and must teach domain fundamentals.

**Example:** Agent designed court scheduling filters using naive time/distance assumptions. Missed: morning sessions are 10-13:00, non-trial hearings wrap in ~1h, 60-min structural lunch gap, return-path economics for corridor courts.

**Root cause:** Behavioral knowledge for the domain was never captured. Agent had structural knowledge (which files to edit) but not domain knowledge (how courts actually work).

**Prevention:**
- Domain glossary (DOMAIN.md) with business rules
- Behavioral rule files must include domain heuristics, not just code behavior
- When operator corrects domain understanding, immediately capture it in a rule file

---

## INC-008: Dirty Tree on Session Start

**Pattern:** New session starts on a branch with uncommitted changes from a previous session. Agent either: (a) commits the orphaned changes without context, or (b) starts new work on a dirty tree.

**Prevention:**
- `/start` protocol MUST include git health check before any work
- Standing rule: "Fix git state before briefing — push + board sync BEFORE briefing output"
- Check: status clean, tracking remote, no stale stashes, mainline connected

---

## INC-009: Exploratory Paralysis

**Pattern:** Agent spends 20+ turns reading files, running searches, and building context before doing any productive work. Often re-reads the same files from different angles.

**Root cause:** Missing Tier 2 behavioral knowledge. Agent is performing information foraging (Ko et al. 2006) without being able to retain results.

**Prevention:**
- Path-scoped behavioral rules that auto-load when relevant files are touched
- Pre-computed flow narratives that describe cross-file interactions
- Session startup should inject behavioral context, not just structural orientation

---

## INC-010: Silent Context Loss on Compaction

**Pattern:** Long session hits context limit, system compacts prior messages. Agent loses behavioral understanding it built up through extensive reading. Produces lower-quality output or makes errors it wouldn't have made earlier in the session.

**Prevention:**
- Critical behavioral knowledge must be in persistent files (rules, memory), not just in conversation
- Mid-session checkpoints: if agent has done deep exploration, write a behavioral summary before continuing
- HiAgent pattern: when completing a subgoal, summarize observations and replace detailed content with summary
