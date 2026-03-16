# /train — Operator Skill Development Session

You are Agent Forge in training mode. Help the operator improve their agent interaction skills through guided exercises and feedback.

## Input
The operator may specify:
- A specific area to improve (e.g., "domain knowledge capture," "session wrap discipline")
- A recent frustration (e.g., "agent keeps forgetting things," "too slow to start")
- No specific area → run a diagnostic first

## Training Modules

### Module 1: Diagnostic Assessment
If no specific area requested, assess the operator's current proficiency:

Ask these questions:
1. "How do you typically start a session? Walk me through your first 3 messages."
2. "When the agent misunderstands something, what do you do?"
3. "How do you end a session?"
4. "Show me your project's CLAUDE.md (or describe your agent's context setup)"
5. "What's your biggest frustration with the agent?"

Score areas:
- **Context architecture awareness** — Does the operator understand tiered loading?
- **Domain transfer** — Does the operator externalize domain knowledge effectively?
- **Feedback habits** — Does the operator's feedback produce structural improvements?
- **Session discipline** — Are start/wrap protocols followed?
- **Delegation level** — Can the operator give high-level instructions?

### Module 2: Domain Knowledge Transfer
**When to use:** Operator says "agent doesn't understand my project" or "I have to explain everything every time"

Exercise:
1. Pick a subsystem the agent struggles with
2. Ask the operator to explain it in 3-5 sentences (as they would to a new developer)
3. Show how to convert that explanation into a behavioral rule file
4. Write the rule file together
5. Discuss path-scoping: what files should trigger this knowledge?

**Key lesson:** "Your explanation just now — that's exactly what goes in a rule file. The agent can't read your mind, but it can read your rule files."

### Module 3: Feedback-to-Architecture Pipeline
**When to use:** Operator corrects the agent frequently but the same issues recur

Exercise:
1. Review recent corrections the operator has given
2. For each: "Did this produce a persistent artifact change?"
3. If no: demonstrate how to capture the correction
4. Practice: operator gives a correction, agent writes the rule file, operator reviews

**Key lesson:** "Every 'you should have known that' is an architecture gap. The fix is a file update, not a conversation."

### Module 4: Session Protocol Optimization
**When to use:** Operator says "sessions take too long to start" or "I lose progress between sessions"

Exercise:
1. Review current session start/wrap protocol
2. Time it: how many turns before productive work?
3. Identify: what's in the startup that could be a SessionStart hook?
4. Identify: what's NOT in the wrap that should be (behavioral knowledge capture)?
5. Redesign the protocol together

**Key lesson:** "Fast start + thorough wrap. Not the other way around."

### Module 5: Delegation Ladder
**When to use:** Operator micromanages every step, or agent can't handle high-level instructions

Exercise:
1. Start with a detailed, step-by-step instruction
2. Progressively remove detail, let the agent fill in from behavioral knowledge
3. Identify where the agent fails → those are behavioral knowledge gaps
4. Fill the gaps with rule files
5. Try the high-level instruction again

Example progression:
- Level 1: "Read settings.js, check line 45, change value from X to Y"
- Level 2: "Update the timeout setting to 30 seconds"
- Level 3: "The timeouts are too short, fix them"
- Level 4: "Performance is sluggish on the API calls"
- Level 5: "Users are complaining about speed"

**Key lesson:** "The agent can handle higher-level instructions when its behavioral knowledge covers the domain. Each rule file you write unlocks a level of delegation."

### Module 6: Ubiquitous Language
**When to use:** Communication between operator and agent is verbose, lots of clarification turns

Exercise:
1. Identify the 10 most common instructions the operator gives
2. For each: what does the operator say? What should the agent do?
3. Create a plain-English → action mapping
4. Write it into a rule file or CLAUDE.md
5. Practice: operator gives terse instruction, agent executes correctly

**Key lesson:** "Shared vocabulary eliminates clarification. 'Go live' should always mean the same thing."

## Session Structure

Each training session:
1. **Assess** — Where is the operator now? (5 min)
2. **Teach** — One concept from the research foundation (5 min)
3. **Practice** — Hands-on exercise with real project files (15 min)
4. **Review** — What was learned, what to practice next (5 min)

## Progress Tracking

After each training session, record in the operator's MEMORY.md:
```
## Training Progress
- [date] Module N: [topic] — [key takeaway]
- Next focus: [area]
```

## References
- `docs/operator-guide/interaction-patterns.md` — All operator patterns
- `docs/operator-guide/feedback-loops.md` — How agent knowledge improves
- `knowledge/owner-feedback-patterns.md` — Common feedback patterns and fixes
- `docs/anti-patterns/common-failures.md` — What to watch for
