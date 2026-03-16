# Operator Interaction Patterns

How to work effectively with an LLM code agent. Patterns derived from 70+ sessions of real-world operation.

---

## Principle 1: Domain Knowledge Is Your Responsibility to Surface

The agent cannot read your mind. If you know that "court sessions are 10-13:00 with a 60-min lunch gap," that knowledge must be externalized — either spoken in conversation or written in a rule file.

**Pattern:** When the agent proposes something that misses domain knowledge, don't just correct it. Capture the correction:
1. Explain the correct model
2. Ask the agent to write it into the appropriate rule file
3. Verify the rule file captures the nuance

**Anti-pattern:** Correcting in conversation and expecting the agent to "remember" next session. Conversation is volatile; rule files persist.

---

## Principle 2: Feedback Is Architecture Signal

Every time you say "you should have known that," you've identified a gap in the agent's behavioral knowledge layer. The fix is always structural:

| Your feedback | Agent should do |
|---------------|----------------|
| "You should have known that" | Write/update behavioral rule file |
| "We discussed this before" | Check if it's in a persistent file; if not, write it |
| "That's not how it works" | Capture corrected model in rule file |
| "Why are you exploring again?" | Write behavioral summary from current understanding |
| "This is taking too long" | Check if Tier 2 exists for this domain |

---

## Principle 3: Speak in Domain Language

Establish a mapping from your natural language to the system's API/operations. The agent should interpret immediately without clarification.

**Good:** "Go live" → agent enables the system
**Bad:** "Can you check if the system is currently active and if so what the status is and then maybe we should enable it if it's not already running"

The more concise your instruction, the faster the agent acts. This is not about being terse — it's about shared vocabulary. A ubiquitous language (DDD) where "go live" always means the same thing.

---

## Principle 4: Inspect, Don't Micromanage

Give the agent the goal, not the steps. If you need to dictate every step, the agent's behavioral knowledge is insufficient.

**Good:** "Set up strategy for tomorrow — morning InPerson within 50km, evening remote"
**Bad:** "First read the current settings, then read the presets, then create a new preset with these exact rules..."

If the agent can't handle the high-level instruction, that's a signal to improve its behavioral rules, not to add more steps to your prompt.

---

## Principle 5: Correct Early, Correct Loudly

When the agent is going in the wrong direction, stop it immediately. Don't wait to see if it course-corrects. The longer a wrong approach runs, the more context tokens are wasted.

**Pattern:** If the agent's first step seems wrong, say "stop — that's wrong because X."

**Anti-pattern:** Letting the agent complete a 20-step process, then saying "actually, that whole approach was wrong."

---

## Principle 6: Review the Agent's Self-Assessment

The agent should detect its own errors and apply the Apology → Action protocol. When it says "sorry," check that it produces:
1. Root cause
2. Prevention artifact
3. Scope check

If it just says "sorry" and moves on, prompt: "What's the prevention artifact?"

---

## Principle 7: Session Start Should Be Fast

If your agent takes 15+ turns to start working, the session protocol is over-engineered. A lightweight hook should inject basic orientation automatically. Full start ceremonies should be reserved for sprint sessions.

**Target:** First productive output within 3 turns for routine work.

---

## Principle 8: Invest in Wrap

Session wrap is where knowledge persists. Rushing wrap means the next session starts from scratch. A good wrap takes 5 minutes and saves 30 minutes next session.

**Minimum wrap checklist:**
- [ ] Code committed and pushed
- [ ] Behavioral summaries updated for explored subsystems
- [ ] New ADRs written for significant decisions
- [ ] Incidents recorded with structured format
- [ ] Session continuation file written if needed

---

## Principle 9: Trust Then Verify

Let the agent make decisions within its behavioral knowledge. Don't pre-approve every step. But do verify the outputs — especially for production-affecting changes.

**Escalation model:**
- Local, reversible: agent proceeds autonomously
- Production-visible: agent confirms before executing
- Destructive: agent asks permission explicitly

---

## Principle 10: The Agent Gets Better When You Make It Better

Agent performance is not fixed. It improves when:
- You capture domain corrections in rule files (not just conversation)
- You invest in session wrap (behavioral knowledge persists)
- You provide clear, domain-language instructions (reduces ambiguity)
- You review and prune MEMORY.md (keeps always-loaded context relevant)
- You let the agent maintain its own knowledge (it can write rule files)

It degrades when:
- You correct in conversation without persisting
- You skip session wrap
- You micromanage every step (agent never builds autonomy)
- You let MEMORY.md grow unchecked (noise drowns signal)
