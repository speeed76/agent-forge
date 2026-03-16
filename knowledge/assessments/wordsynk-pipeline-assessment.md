# Pipeline Assessment — WordSynk Autonomous Development Pipeline

*Date: 2026-03-16 | Assessor: Agent Forge (meta-agent) | Operator: Pawel Giers*
*Source: 70+ sessions of production operation, 4 incident reports, 7 autonomous SpecFlow sprints*

---

## 1. Pipeline Under Review

A fully automated development pipeline where autonomous agents handle the full software lifecycle:

```
Data (ETL) → Model (data modeling) → Backend (code generation) →
Model-aware Frontend → Human arbitration at executive friction points
```

### Tooling Stack

| Component | Role | Status |
|-----------|------|--------|
| **SpecFlow** | Data modeling → Gherkin features → GHA | Working |
| **Herald** | Dispatcher — classifies, selects model tier, dispatches to GHA | Working |
| **CLA Pipeline** | Operationalizer → Decomposer → Scheduler (issue processing) | Working |
| **Forge** | Worker — 4-phase coding (understand → specify → locate → execute) | Working |
| **Arbiter** | Reviewer — diff review → APPROVE / REQUEST_CHANGES | Working |
| **Argus** | UI design + arbitration → coherent UI | Working |
| **Sprint Board** | Custom kanban (:3030) for task tracking | Working |
| **GHA Workflows** | CI/CD + agent orchestration | Working |
| **Oracle/Shard** | Local inference (qwen3-coder:30b / qwen2.5-coder:14b) | Working |

### Operational Evidence

- 7 autonomous SpecFlow sprints (S25-S32): 1631 tests, 0 regressions, clean builds
- Model tier cascade (L1-L4) with 7-factor routing
- Sprint discipline guard with `sudo:` override
- Incident-driven safety rules (4 incidents → 4 prevention artifacts)

---

## 2. The Diagnosis: Open-Loop Pipeline

### 2.1 Core Problem

The pipeline is **feed-forward only**:

```
Spec → Code → Test → Review → Merge
  ↓      ↓      ↓      ↓       ↓
  →      →      →      →       →   (data flows one direction only)
```

Every agent optimizes for passing its own gate:
- **Forge** optimizes for: lint/build/test exits 0
- **Arbiter** optimizes for: diff is correct and well-structured
- **SpecFlow** optimized for: test count hits projected target

**Nobody optimizes for: the product actually works.**

### 2.2 Goodhart's Law in Agent Pipelines

> *When a synthetic metric becomes the agent's target, the agent will satisfy the metric without producing the intended outcome.*

Evidence from SpecFlow sprints:
- 1631 passing tests — all mocking everything
- Projected test counts hit perfectly — roadmap looked like success
- 7 sprints ran without anyone opening the app
- Result: product didn't work

The tests proved the code matched the mocks. They did not prove the code worked.

### 2.3 Control Theory Framing

The pipeline is an **open-loop controller**. It works when:
- The model (agent) is perfect
- There are no disturbances (unexpected system state, integration issues)

LLM agents are imperfect models operating in a complex environment. They need **closed-loop feedback** — output observations that flow back to correct future inputs.

### 2.4 Gates vs Feedback Loops

The pipeline has **gates** (pass/fail checkpoints) but not **feedback loops** (output-informs-input cycles):

| Mechanism | What it does | What it doesn't do |
|-----------|-------------|-------------------|
| **Gate** | "Did tests pass?" → yes/no → proceed/block | Tell you if the product works |
| **Feedback loop** | "Does the real system behave correctly?" → observation → adjustment | — |

The pipeline is full of gates. It has zero feedback loops.

---

## 3. Three Missing Feedback Loops

### 3.1 Loop 1: Reality Verification (post-Forge, pre-Arbiter)

**The gap:** Forge's exit condition is `lint/build/test exits 0`. Tests are synthetic (mocked dependencies, no real services). A change can pass all tests and be completely non-functional.

**What's needed:** After Forge writes code and tests pass, a **verification step** checks the real system:
- Start the real service with the changes applied
- Hit real endpoints with real requests
- Check real database state
- For UI: render real pages and check they display correctly

**Evidence this is needed:** SpecFlow sprint failure modes #1 (synthetic self-testing), #3 (component tests without rendering), #4 (empty config — never configured the thing being built).

### 3.2 Loop 2: Integration Coherence (post-Arbiter, pre-Merge)

**The gap:** Arbiter reviews diffs. Diffs are local. But the "two disconnected paths" failure (old webhook path and new dispatch path, neither fully wired) is an **integration coherence** problem. Each diff looks fine locally; the system is broken globally.

**What's needed:** An agent that sees the whole integration picture:
- Does this new endpoint actually get called from anywhere?
- Does this new component actually appear in a route?
- Does this feature flag actually get set?
- Are there dangling references or orphaned code paths?

**Evidence this is needed:** SpecFlow failure mode #5 (two disconnected paths), INC-2026-03-12 (filter appeared configurable but never executed due to missing triple-registration).

### 3.3 Loop 3: Outcome Feedback (post-Deploy, feeds back to Spec)

**The gap:** When a feature is deployed and the human uses it, the observation doesn't flow back to the spec layer. Forge doesn't know what happened after its PR was merged. It can't learn from outcomes because outcomes never flow back.

**What's needed:** Outcome capture and feedback:
- After merge + deploy, the human uses the feature
- Observation recorded: "worked as intended" / "didn't work because X" / "worked but UX is wrong"
- This observation feeds into the spec for the next iteration
- Pipeline agents get outcome history as context

**Evidence this is needed:** SpecFlow failure mode #2 (no human review between sprints — 7 sprints without verification), failure mode #6 (roadmap without validation).

---

## 4. The Episodic Memory Gap

### 4.1 CoALA Framework Analysis

From cognitive architecture research (Park et al. 2023, Sumers et al. 2024), agents need three memory types:

| Memory Type | Session Agent (wordsynk) | Pipeline Agents |
|-------------|------------------------|-----------------|
| **Semantic** (facts, concepts) | CLAUDE.md, rules, domain files | Domain context files, CLAUDE.md ✓ |
| **Episodic** (time-stamped experiences) | MEMORY.md, incident reports, standing rules | **None** ✗ |
| **Procedural** (executable workflows) | /start, /wrap, /res commands | Workflow definitions, phase sequences ✓ |

Pipeline agents have procedural and semantic memory but **zero episodic memory**. Each pipeline run starts from zero experience.

### 4.2 Consequences

- Forge doesn't remember that the last time it built a decision engine filter, it forgot the triple-registration
- Arbiter doesn't remember that the last time it approved a UI PR, the breakpoints were wrong
- Herald doesn't remember that L1 tasks in the decision engine domain consistently need L2+ models
- The same mistakes repeat because nothing teaches agents from outcomes

### 4.3 The Reflection Imperative (applied to pipelines)

From Park et al. 2023: removing reflection from Generative Agents caused behavioral degeneration within 48 simulated hours.

Pipeline agents have no reflection mechanism. They cannot:
- Synthesize observations into higher-level understanding
- Update their approach based on past outcomes
- Distinguish between "this pattern worked" and "this pattern failed"

---

## 5. Existing Strengths (do not lose these)

1. **Model tier cascade with 7-factor routing** — Herald's router.js is sophisticated and battle-tested
2. **CLA decomposition** — operationalizer → decomposer → scheduler handles complexity well
3. **Sprint discipline guard** — process enforcement prevents scope creep
4. **Incident-driven safety rules** — every failure becomes a permanent guard
5. **Cost optimization through delegation** — Haiku/Sonnet/Opus tiering works
6. **Atomic commits per task** — reviewable, revertable, auditable
7. **Argus UI pipeline** — design-first with approved screenshots is correct
8. **Sprint board** — audit trail of task state
9. **Domain context files** — auto-generated, fetched by Herald at runtime

---

## 6. Classification of Failures

All observed failures map to the three missing loops:

| Failure | Root Loop |
|---------|-----------|
| 1631 passing tests, product doesn't work | Loop 1 (Reality Verification) |
| Component tests without rendering | Loop 1 |
| Empty config never set up | Loop 1 |
| Two disconnected paths | Loop 2 (Integration Coherence) |
| Filter schema gap (triple-registration) | Loop 2 |
| 7 sprints without human review | Loop 3 (Outcome Feedback) |
| Roadmap without validation | Loop 3 |
| Unauthorized production code replacement | Gate enforcement (already fixed) |
| Same mistakes repeat across runs | Episodic Memory |

---

## 7. Recommendation

Close the three feedback loops. Add episodic memory to pipeline agents. The pipeline topology changes from feed-forward to closed-loop. See `docs/proposals/closed-loop-pipeline.md` for the full architecture proposal.

**Priority order:**
1. Loop 1 (Reality Verification) — highest leverage, prevents the #1 failure mode
2. Episodic Memory — prevents repeated mistakes, compounds over time
3. Loop 2 (Integration Coherence) — prevents subtle integration failures
4. Loop 3 (Outcome Feedback) — closes the full cycle, longest to implement
