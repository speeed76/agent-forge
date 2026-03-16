# Feedback Loops: How Agent Knowledge Improves Over Time

## The Knowledge Flywheel

```
  Operator corrects agent
         ↓
  Agent captures correction in rule file
         ↓
  Rule file loads next session
         ↓
  Agent handles similar situation correctly
         ↓
  Operator trust increases → higher-level delegation
         ↓
  Agent encounters new edge cases
         ↓
  Repeat
```

This flywheel only works if corrections are PERSISTED. Conversation corrections without rule file updates break the cycle.

---

## Feedback Loop 1: Domain Knowledge Transfer

### Trigger
Operator says "that's not how it works" and explains the correct model.

### Agent Response
1. Acknowledge the correction
2. Restate the corrected model to verify understanding
3. Ask: "Should I capture this in the behavioral rule file for [domain]?"
4. Write the correction to `.claude/rules/<domain>.md`
5. If the correction affects other domains, update those too

### Verification
Next session: agent should handle similar situations without correction.

---

## Feedback Loop 2: Incident → Prevention

### Trigger
Agent makes an error (detects itself or operator flags it).

### Agent Response (Apology → Action Protocol)
1. Root cause: What specific assumption/data was wrong?
2. Prevention: What artifact change prevents recurrence?
3. Scope check: Did the same flaw affect other outputs?

### Artifact Changes
- New standing rule in MEMORY.md
- Updated behavioral rule file
- New code guard (if code logic gap)
- New ADR (if decision was wrong)

### Verification
Track incident patterns. If same class recurs, the prevention artifact was insufficient.

---

## Feedback Loop 3: Session Wrap → Session Start

### Trigger
End of productive session.

### Agent Response
1. Update behavioral summaries for explored subsystems
2. Write ADRs for significant decisions
3. Record incidents
4. Write session continuation file

### Verification
Next session start should reference what was learned. If the agent re-explores the same subsystems, the wrap was insufficient.

---

## Feedback Loop 4: Operator Skill Development

### Trigger
Operator provides vague instructions and expects detailed execution.

### Agent Response
Identify the communication gap and suggest clearer patterns:
- "When you say 'set up strategy,' I need: target days, delivery methods, pay thresholds, and distance limits."
- After several sessions: establish shorthand. "Strategy for tomorrow" = specific well-defined action.

### Verification
Over time, operator instructions become more concise and agent responses more accurate. Fewer clarification turns per task.

---

## Measuring Improvement

### Leading Indicators (track per session)
- Turns to first productive output (lower is better)
- Operator corrections per session (fewer is better)
- Source files read to complete a task (fewer means better Tier 2)
- "You should have known that" occurrences (should trend to zero)

### Lagging Indicators (track per week/sprint)
- Rule files created/updated (should grow then stabilize)
- Incident records (should decrease over time)
- ADRs written (should grow steadily)
- Agent autonomy level (how complex a task can be delegated without briefing)

### Red Flags
- Corrections NOT resulting in rule file updates
- Same incident class recurring
- Rule files growing but agent still exploring
- Operator reverting to micromanagement
