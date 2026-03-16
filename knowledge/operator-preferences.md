# Operator Preferences — Pawel Giers

Derived from 70+ sessions of real-world agent operation. These preferences inform every scaffolded architecture.

## Interaction Style

**Autonomy level: Maximum.** Pawel points the agent at a problem and expects independent execution. He does not micromanage steps. Typical directive: "start whenever you're ready" or "run your magick." The agent must be self-sufficient from session one.

**Communication: Dense and structured.** Prefers tables, metrics, and structured output over prose. No fluff. Say what changed and why, not what you're about to do.

**Feedback as architecture signal.** When Pawel corrects the agent, that correction must become a permanent knowledge artifact (rule file, standing rule, invariant). An apology without a prevention artifact is incomplete.

## Agent Ownership Principles

### 1. Git is Agent-Owned

The agent handles all git operations. The operator never runs git commands, chooses branches, or makes commits. The agent must be git-aware at every step.

**Scaffold directive:** Every project gets:
- Agent git protocol in root CLAUDE.md (branch model, commit conventions)
- Git health check as Step 1 of `/start` (branch, status, stashes, mainline connection)
- Git cleanup as mandatory step in `/wrap` (commit, push, verify remote)
- Pre-commit hooks for credential protection
- Branch model: `main` (stable) + `feat/<name>` (work). Never commit directly to main.

### 2. Sprint Discipline Guard

The agent is a process enforcer, not a servant. During focused work, it protects the process from the operator's own impulses, distractions, and scope creep.

**Scaffold directive:** Every project with sprint/task workflows gets:
- Request classification table: ON-PATH / PROCESS / ADJACENT / DEVIATION / SCOPE CREEP / PROCESS VIOLATION
- `sudo:` override mechanism for ADJACENT/DEVIATION (operator acknowledges the override)
- Hard blocks for PROCESS VIOLATION (no override — skipping tests, committing with failures, etc.)
- Override logging: `[SUDO] FP-{N} override: {description}`

### 3. Model Delegation

Explicit cost optimization through tiered model routing. Never use Opus for tasks Haiku can handle.

**Scaffold directive:** Every project's slash commands get model routing tables:
- `/start`: Haiku for data gathering (scripts, git, health checks), main context for decisions
- `/wrap`: Haiku for builds/scripts, Sonnet for writing docs, main context for confirmation
- Exploration: Haiku subagents (`subagent_type: "Explore"`)
- Code review: Sonnet subagents

### 4. Performance Review

The agent reviews the operator's performance, not just its own. This creates a feedback loop where the operator improves their agent interaction skills.

**Scaffold directive:** `/wrap` includes a `/perf-review` step that:
- Reviews the full conversation for prompting errors, omissions, and operational rule violations
- Appends findings to a feedback file (e.g., `OPERATOR_FEEDBACK.md`)
- Focus: mistakes and better approaches, not accomplishments
- Mandatory even in short sessions

### 5. Incident-Driven Safety Rules

Every incident produces a permanent 1-line safety rule in the invariants file. The detailed incident narrative lives in a separate incident report. This prevents repeat failures without bloating always-loaded context.

**Scaffold directive:** Every project gets:
- `invariants.md` rule file (always loaded) for safety rules
- `docs/incidents/` directory for detailed incident reports
- Error protocol: trigger → root_cause → prevention artifact → scope_check
- Each prevention artifact = new invariant rule with incident reference

### 6. Governance Hierarchy

Multi-document authority needs explicit precedence. The highest-level document wins conflicts.

**Scaffold directive:** For projects with layered governance docs:
- Establish authority chain in invariants (e.g., MISSION > STRATEGY > ROADMAP)
- Higher-level docs are immutable — supersede with new entries, never edit
- ADRs are append-only events (Zimmermann Y-statement format)

### 7. Verification Standard

"Every sprint must produce something a human can verify." No synthetic-only testing. The deliverable is a diff the human reviews, a curl command they can run, or a screenshot they can inspect.

**Scaffold directive:** Sprint and task protocols include:
- Verification artifact per task (what can the human check?)
- Integration tests use real DB / real services where possible
- No mocking the thing you're testing
- Preflight/postflight gate scripts

## Session Protocol Preferences

### /start should:
1. Run git health check (fix before anything else)
2. Detect session mode (sprint / orientation / continuation / co-pilot)
3. Sync with external trackers (board, CI) if present
4. Output a compact briefing (< 20 lines)
5. Begin executing immediately (sprint mode) or ask for direction (orientation mode)

### /wrap should:
1. Verify builds pass
2. Snapshot codebase state (codemap, context regen)
3. Write session entry + handover block
4. Update CLAUDE.md files if architecture changed
5. Git cleanup (commit, push, verify remote — mandatory, never skip)
6. Reconcile external trackers
7. Run performance review
8. Final health check
9. Confirm to user: "Session is safe to close."

### Session continuity:
- Handover block at top of SESSION.md with: state, exact next action, files that matter, decisions to preserve
- `/res` command for fast resume (skip full orientation, go straight to work)
- Co-pilot mode detection (if another agent is running, don't interfere)
