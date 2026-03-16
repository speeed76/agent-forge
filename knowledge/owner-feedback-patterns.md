# Owner-Operator Feedback Patterns

Generalized feedback patterns from real agent operation. Each pattern reveals a systemic issue, not a one-off complaint.

---

## Pattern 1: "It feels like a junior dev managing the project"

**Signal:** Agent lacks domain fluency. It can execute instructions but cannot make informed autonomous decisions.

**Root cause:** Missing Tier 2 behavioral knowledge. Agent knows WHERE things are (structural) but not HOW they work (behavioral) or WHY they were built that way (decisional).

**Fix:** Write behavioral rule files for each bounded context. Include domain heuristics, not just code behavior.

---

## Pattern 2: "You should have known that" / "We discussed this before"

**Signal:** Knowledge from a previous session was not persisted. The agent is re-discovering what was already established.

**Root cause:** Conversation-only knowledge. The insight existed in a prior session's context window but was never written to a persistent file.

**Fix:** Every significant discovery must be written to a rule file or memory topic file before the session ends. The `/wrap` protocol must include a behavioral knowledge checkpoint.

---

## Pattern 3: "That's not how it works"

**Signal:** Agent applied a generic model instead of project-specific domain knowledge.

**Example:** Agent designed court scheduling filters using naive time/distance assumptions, missing morning session structure, non-trial wrap times, return-path economics.

**Root cause:** Domain knowledge was never externalized. The operator holds it implicitly; the agent has no access to it.

**Fix:** When this feedback occurs, immediately capture the corrected model in a behavioral rule file. Use the operator's exact language — this is DDD "knowledge crunching" in action.

---

## Pattern 4: "Why are you exploring that again?"

**Signal:** Agent is performing information foraging that it already completed in a prior session (or earlier in the same session).

**Root cause:** Either (a) behavioral summary was never written, or (b) context was compacted and the summary was lost.

**Fix:** HiAgent pattern — when completing a subgoal that required extensive exploration, summarize the findings and store them persistently before moving to the next task.

---

## Pattern 5: "Smarter than I expected"

**Signal:** Agent expresses surprise at the codebase's sophistication. This reveals the agent was operating with an underestimation of the system's capabilities.

**Root cause:** Agent had structural knowledge (function names, file locations) but not behavioral knowledge (what the functions actually do, including clever/non-obvious behaviors).

**Fix:** Behavioral rule files must capture the non-obvious behaviors. "This function does X, but notably it also does Y which handles [edge case]."

---

## Pattern 6: "Stop apologizing and fix it"

**Signal:** Agent detected its own error and responded with acknowledgment but no corrective action.

**Root cause:** Default LLM conversational behavior — acknowledge and move on. In engineering, acknowledgment without correction is worse than nothing.

**Fix:** Apology → Action protocol. Every self-detected error produces: root cause, prevention artifact, scope check.

---

## Pattern 7: "You replaced X without asking"

**Signal:** Agent exceeded its authorization scope. Made production-affecting changes that the operator didn't request or approve.

**Root cause:** Agent inferred permission from the task scope. "Improve the dashboard" was interpreted as "rewrite the dashboard."

**Fix:** TTY gate for production-affecting changes. Categorize actions by reversibility and blast radius. Confirm before executing high-impact actions.

---

## Pattern 8: "Can you just do it without me having to explain everything?"

**Signal:** Agent lacks the domain knowledge to operate autonomously. Every task requires extensive briefing.

**Root cause:** This is the compound effect of missing Tier 2. Each interaction requires the operator to re-teach what the system does, because the agent only knows where files are.

**Fix:** Comprehensive behavioral rule files + domain glossary. The agent should be able to handle routine tasks without operator explanation.

---

## Pattern 9: "This is taking too long to start"

**Signal:** Session startup ritual is too heavyweight. Multiple turns of health checks, status reads, and orientation before any productive work.

**Root cause:** Over-engineered session protocol, or agent performing excessive exploratory reading at startup.

**Fix:** Lightweight SessionStart hook for basic orientation (200 tokens). Full `/start` only for sprint sessions. Behavioral rules auto-load on file access — no upfront loading needed.

---

## Pattern 10: "You keep making the same mistake"

**Signal:** Same class of error recurring across sessions. Previous incident was acknowledged but not structurally prevented.

**Root cause:** Incident recorded as conversational correction, not as a persistent rule with prevention artifact.

**Fix:** Every incident must produce a concrete artifact change — a rule file update, a standing operational rule, or a code guard. The prevention must be in a file the agent loads, not in conversation history.
