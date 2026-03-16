# Anti-Patterns in Agent Context Architecture

Patterns that consistently degrade agent performance. Detected through operational experience and validated against research literature.

---

## AP-01: Monolithic CLAUDE.md

**Symptom:** Root CLAUDE.md exceeds 300 lines. Contains behavioral knowledge, API references, incident history, and safety rules in one file.

**Why it fails:** Everything loads at session start, consuming 3,000+ tokens of working memory. Most content is irrelevant to the current task. Adherence drops as file grows — agent starts ignoring sections.

**Fix:** Tier the content. Root CLAUDE.md = navigation + safety (< 150 lines). Domain knowledge → path-scoped rules. API references → domain rule files. Incidents → MEMORY.md.

---

## AP-02: Behavioral Knowledge in Comments Only

**Symptom:** The only documentation of HOW a component works lives in inline source code comments. Agent must read the full source file to access behavioral knowledge.

**Why it fails:** Comments don't load until the file is read. By then, the agent has already consumed thousands of tokens on the source file itself. Comments are also often incomplete — they explain tricky sections but not the overall behavioral contract.

**Fix:** Extract behavioral knowledge into `.claude/rules/` files with path frontmatter. These load BEFORE the source file is read, giving the agent context to understand the source efficiently.

---

## AP-03: No Tier 2 (Missing Behavioral Layer)

**Symptom:** `.claude/rules/` directory doesn't exist or is empty. Agent reads 5+ source files before producing output. Operator frequently says "you should have known that."

**Why it fails:** The agent has structural knowledge (WHERE) and can access source (WHAT) but has no efficient path to behavioral knowledge (HOW). Every session requires re-deriving behavior from source code.

**Fix:** Create behavioral rule files for each bounded context. 30-80 lines each. Path-scoped to auto-load.

---

## AP-04: Over-Engineered Session Startup

**Symptom:** Session start protocol takes 15+ turns. Multiple health checks, status reads, board syncs, and orientation steps before any productive work.

**Why it fails:** Burns context tokens on ceremony. Operator frustration ("this is taking too long to start"). Agent may hit compaction before finishing real work.

**Fix:** Lightweight SessionStart hook for basic orientation (200 tokens). Full `/start` only for sprint sessions. Most work doesn't need a ceremony.

---

## AP-05: Apology Without Correction

**Symptom:** Agent detects error, says "sorry" or "my mistake," continues without fixing root cause or checking scope.

**Why it fails:** Creates false sense of resolution. Same error class recurs in future sessions. Operator loses trust.

**Fix:** Standing rule: every self-detected error → root cause + prevention artifact + scope check. Apology is trigger, not resolution.

---

## AP-06: Configuration Bandaid

**Symptom:** Agent encounters unexpected behavior, adjusts a config parameter instead of investigating the code logic.

**Why it fails:** Config change masks the symptom but doesn't fix the cause. May introduce new problems (e.g., lowering a threshold makes the system accept bad inputs).

**Fix:** Standing rule: if root cause is code logic, propose code fix. Settings cannot fix code defects. Only change settings to genuinely improve future behavior.

---

## AP-07: Scope Creep in Execution

**Symptom:** User requests a bug fix; agent also refactors surrounding code, adds tests, updates documentation, and cleans up imports.

**Why it fails:** Unauthorized changes. Operator can't review what actually changed for the bug vs. what was "improved." May introduce new bugs in "cleaned up" code.

**Fix:** Scope matching rule: actions match what was requested. Bug fix = fix the bug. Period.

---

## AP-08: Duplicated Knowledge

**Symptom:** Same information appears in CLAUDE.md, MEMORY.md, and a domain CLAUDE.md file. When one is updated, others become stale.

**Why it fails:** Three sources of truth → no source of truth. Agent may follow the stale version. Maintenance burden multiplied.

**Fix:** Single-source principle. Each piece of knowledge lives in ONE file. Other files link to it. Domain glossary → DOMAIN.md. API reference → domain rule file. Safety rules → root CLAUDE.md.

---

## AP-09: Exploratory Paralysis

**Symptom:** Agent spends 20+ turns reading source files, running searches, and exploring before producing any output. Often re-reads the same files from different angles.

**Why it fails:** Information foraging without retention (Ko et al. 2006). Each read costs tokens but the understanding is not persisted. By the time the agent acts, context may be near capacity.

**Fix:** If reading 4th file without output → stop. Check if behavioral rule exists. If not, THAT is the problem. Write a behavioral summary from what's been read so far, then continue with the summary in context.

---

## AP-10: Implicit Knowledge Syndrome

**Symptom:** Operator holds critical domain knowledge implicitly ("I just know how courts schedule"). Agent cannot access it because it was never written down. Every task requires operator briefing.

**Why it fails:** Agent can never become autonomous in that domain. Operator bottleneck on every decision.

**Fix:** DDD knowledge crunching. When operator corrects agent, capture the corrected model immediately. The operator's words are the raw material for behavioral rules.

---

## AP-11: Flat Memory (No Episodic Records)

**Symptom:** MEMORY.md contains facts and rules but no incident records. Same class of error recurs across sessions.

**Why it fails:** Without episodic memory, the agent has no "I tried this before and it failed" awareness. It re-proposes rejected approaches and repeats errors (Pink et al. 2025).

**Fix:** Structured incident records with trigger → root_cause → prevention → scope_check. Each incident produces a concrete artifact change.

---

## AP-12: Session Wrap = Git Push Only

**Symptom:** Session wrap consists of committing and pushing code changes. No behavioral knowledge capture, no ADRs, no incident records.

**Why it fails:** All understanding built during the session evaporates. Next session starts from scratch for any subsystem deeply explored.

**Fix:** Wrap protocol must include behavioral knowledge checkpoint: what was learned? What rule files need updating? What decisions were made?
