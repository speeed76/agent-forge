# Closed-Loop Agent Pipeline — Architecture Proposal

*Date: 2026-03-16 | Author: Agent Forge | Operator: Pawel Giers*
*Prerequisite: Read `knowledge/assessments/wordsynk-pipeline-assessment.md` for the diagnosis.*

---

## 1. Design Thesis

The current pipeline is feed-forward: Spec → Code → Test → Review → Merge. Agents optimize for their own gates, not for product correctness. The fix is three feedback loops that close the circuit between "what was built" and "does it actually work."

**Principle:** Every pipeline stage that transforms input into output must verify its output against reality, not just against its own test suite.

---

## 2. Architecture Overview

### 2.1 Current (Open-Loop)

```
Herald → CLA → Forge → Arbiter → Merge
                 ↓        ↓
              tests    diff review
              (mock)   (local)
```

### 2.2 Proposed (Closed-Loop)

```
Herald → CLA → Forge → Sentinel → Arbiter → Weaver → Merge
                 ↓         ↓          ↓         ↓        ↓
              tests    real system  diff +    integration  outcome
              (mock)   verification  context   coherence   capture
                 ↑         |          |         |          |
                 |         ↓          ↓         ↓          ↓
                 ←──── Pipeline Memory ←────────←──── Outcome Log
```

### 2.3 New Components

| Agent | Role | Loop | When |
|-------|------|------|------|
| **Sentinel** | Reality verification — runs the real system, checks it works | Loop 1 | After Forge, before Arbiter |
| **Weaver** | Integration coherence — checks the change fits the whole system | Loop 2 | After Arbiter, before Merge |
| **Pipeline Memory** | Episodic memory — records what happened, feeds future runs | All | Persistent, updated every run |
| **Outcome Log** | Post-deploy observation capture | Loop 3 | After merge, async |

Existing agents (Herald, CLA, Forge, Arbiter, Argus) are unchanged. The new components are additive.

---

## 3. Sentinel — Reality Verification Agent

### 3.1 Purpose

Sentinel answers the question Forge cannot: **"Does the change actually work in the real system?"**

Forge exits when `lint/build/test` passes. Sentinel exits when the real system demonstrates correct behavior.

### 3.2 Operating Model

```
Forge output (branch with passing tests)
  ↓
Sentinel reads:
  1. The PR diff (what changed)
  2. The task spec from the issue (what was intended)
  3. Pipeline Memory for this subsystem (past failures)
  ↓
Sentinel executes:
  4. Start the real service(s) affected by the change
  5. Run reality checks (see §3.3)
  6. Collect evidence (responses, screenshots, DB state)
  ↓
Sentinel outputs:
  7. PASS: evidence artifacts attached to the PR
  8. FAIL: specific failure description → Forge revision cycle
  9. INCONCLUSIVE: flag for human review
```

### 3.3 Reality Checks by Domain

The checks Sentinel runs depend on which domain was touched:

**Backend (offer-server):**
```bash
# Start service with test database
cd offer-server && npm start &
sleep 3

# Smoke test: health + key endpoints
curl -sf http://localhost:3003/health
curl -sf http://localhost:3003/api/decision/settings
curl -sf http://localhost:3003/api/dashboard/offers

# If decision engine changed: run a real evaluation cycle
curl -X POST http://localhost:3003/api/decision/evaluate-preview

# If API route changed: verify the route is mounted and responds
curl -sf http://localhost:3003/<new-route>

# If ETL changed: ingest a fixture and verify DB state
node etl/import_history.js --offers-only
sqlite3 data/test.db "SELECT count(*) FROM offers"
```

**Frontend (dashboard):**
```bash
# Build + start dev server
cd dashboard && npm run build && npm run dev &
sleep 5

# Verify the page renders (not just builds)
# Use Playwright or curl to check HTTP 200 + content
curl -sf http://localhost:3000/<affected-route> | grep -q "<expected-content>"

# If UI component changed: screenshot capture
# Playwright: await page.screenshot({ path: 'evidence/sentinel-check.png' })
```

**Decision engine:**
```bash
# Verify filter triple-registration (the INC-2026-03-12 check)
node -e "require('./services/decision/decision_filters')"

# If filter added: create a test preset and evaluate against a fixture offer
curl -X PUT http://localhost:3003/api/decision/presets/test-sentinel \
  -H 'Content-Type: application/json' \
  -d '{"rules": {"<new_filter>": <test_value>}}'
curl -X POST http://localhost:3003/api/decision/evaluate-preview
# Check the evaluation log includes the new filter
```

### 3.4 Evidence Artifacts

Sentinel attaches evidence to the PR as a comment:

```markdown
## Sentinel Verification — [PASS/FAIL]

### Checks performed
- [x] Service starts cleanly (offer-server :3003)
- [x] Health endpoint responds
- [x] Affected route `/api/decision/presets` responds correctly
- [x] Filter triple-registration verified
- [ ] ~~Evaluation preview~~ — FAIL: new filter `min_rate` not in evaluateFilter() switch

### Evidence
- Response: `GET /api/decision/settings` → `{"enabled": true, "active_preset": "default"}`
- Screenshot: [link to artifact]

### Verdict
**FAIL** — `min_rate` filter passes schema validation but has no evaluator handler.
Returning to Forge for revision.
```

### 3.5 Sentinel Infrastructure

| Property | Value |
|----------|-------|
| **Runner** | Same `forge-pod` GHA runner (has the codebase + services) |
| **Model** | Sonnet (needs reasoning about what to check, but not full Opus) |
| **Timeout** | 5 minutes (service startup + checks) |
| **Inputs** | PR diff, task spec, domain context, pipeline memory |
| **Outputs** | PASS (evidence) / FAIL (failure + revision instructions) / INCONCLUSIVE (flag for human) |
| **Cost** | ~$0.05-0.15 per run (Sonnet + bash execution) |

### 3.6 Failure Mode

If Sentinel itself fails (timeout, infrastructure issue), it outputs INCONCLUSIVE and the pipeline falls back to the current flow (Arbiter reviews without Sentinel evidence). The pipeline degrades gracefully, never blocks.

---

## 4. Weaver — Integration Coherence Agent

### 4.1 Purpose

Weaver answers the question Arbiter cannot: **"Does this change fit the system as a whole?"**

Arbiter reviews diffs (local correctness). Weaver checks that the diff is properly integrated into the broader system (global coherence).

### 4.2 Operating Model

```
Arbiter APPROVE
  ↓
Weaver reads:
  1. The full file(s) changed (not just diff)
  2. The files that REFERENCE the changed files (reverse dependencies)
  3. Route mount map (app.js), navigation config, test index
  4. Pipeline Memory for integration failures
  ↓
Weaver checks:
  5. Connectivity — is new code reachable from entry points?
  6. Registration — are new components/routes/filters registered?
  7. Consistency — do naming conventions and patterns match?
  8. Orphan detection — did the change create dead code?
  ↓
Weaver outputs:
  9. COHERENT: no issues found
  10. INCOHERENT: specific integration gaps → return to Forge
  11. WARNING: potential issues flagged for human review
```

### 4.3 Coherence Checks

**Connectivity checks:**
- New API route defined → is it mounted in `app.js`?
- New React component created → is it imported in a page/layout?
- New service function exported → is it called from a route handler?
- New database migration → is the new table/column used in code?

**Registration checks (domain-specific):**
- New decision filter → exists in FILTER_SCHEMA + evaluateFilter() + FILTER_FIELDS? (triple-registration)
- New SWR hook → is it used in a component?
- New dashboard endpoint → is it called from `lib/api.ts` or a hook?

**Pattern consistency:**
- New endpoint follows existing naming convention (`/api/domain/resource`)
- New component uses `cn()` utility, not inline `className` strings
- New test file follows existing test structure

**Orphan detection:**
- Did the change remove an import but leave the file?
- Did the change create a new export that nothing imports?
- Did the change add a feature flag that's never checked?

### 4.4 Weaver Infrastructure

| Property | Value |
|----------|-------|
| **Runner** | Same `forge-pod` GHA runner |
| **Model** | Sonnet (code analysis + pattern matching) |
| **Timeout** | 2 minutes (static analysis, no service startup) |
| **Inputs** | Changed files, reverse dependency graph, domain context, pipeline memory |
| **Outputs** | COHERENT / INCOHERENT (gaps) / WARNING (potential issues) |
| **Cost** | ~$0.03-0.08 per run (Sonnet, read-only) |

### 4.5 Implementation Strategy

Weaver can start as a set of **deterministic checks** (grep/ast-based) before evolving into a full LLM agent:

**Phase 1 — Deterministic:**
```bash
# Check: new routes are mounted
new_routes=$(grep -r "router\.\(get\|post\|put\|patch\|delete\)" --include="*.js" -l)
for route_file in $new_routes; do
  route_name=$(basename "$route_file" .js)
  grep -q "$route_name" app.js || echo "INCOHERENT: $route_file not mounted in app.js"
done

# Check: decision filter triple-registration
filters_in_schema=$(node -e "require('./services/decision/decision_filters').FILTER_SCHEMA.forEach(f => console.log(f.name))")
filters_in_evaluator=$(grep "case '" services/decision/filter_evaluator.js | sed "s/.*case '//;s/'.*//" )
# diff the two lists
```

**Phase 2 — LLM-assisted:** Sonnet reads the full context and checks for subtle integration issues that deterministic checks miss.

---

## 5. Pipeline Memory — Episodic Memory for Agents

### 5.1 Purpose

Pipeline Memory gives agents what the session agent already has: the ability to learn from past outcomes. Each pipeline run records what happened; future runs read the relevant history.

### 5.2 Structure

```
pipeline-memory/
  index.md                  # Summary stats + pointers
  domains/
    decision-engine.md      # Outcomes for decision engine tasks
    dashboard-ui.md         # Outcomes for dashboard tasks
    backend-api.md          # Outcomes for API/backend tasks
    fleet-devices.md        # Outcomes for device/fleet tasks
  incidents/
    forge-missed-triple-reg.md
    forge-disconnected-paths.md
    ...
```

### 5.3 Memory Entry Format

Each pipeline run appends to the relevant domain file:

```markdown
## Run #147 — 2026-03-16

**Issue:** #892 — Add min_rate filter to decision engine
**Agent:** Forge (L2, Sonnet 4.6)
**Outcome:** FAIL → PASS (1 revision)

### What happened
- Forge added filter to FILTER_SCHEMA and FILTER_FIELDS but missed evaluateFilter() switch case
- Sentinel caught it: filter was configurable but never executed
- Revision: Forge added the switch case + test

### Lesson (auto-generated)
Decision engine filters require triple-registration. When adding a filter, always check:
1. FILTER_SCHEMA in decision_filters.js
2. evaluateFilter() in filter_evaluator.js
3. FILTER_FIELDS in nl_interpreter.js

### Tags
domain:decision-engine, failure:incomplete-registration, agent:forge, revisions:1
```

### 5.4 Memory Injection

When Herald dispatches a task, it includes relevant pipeline memory in the context:

```python
# In Herald's dispatch logic
domain = classify_domain(issue)
memory = read_pipeline_memory(domain, limit=5)  # last 5 outcomes for this domain

# Injected into Forge's context
forge_context = f"""
{domain_context}

## Pipeline Memory — Recent outcomes for {domain}
{memory}

## Important: Known failure patterns for this domain
{extract_lessons(memory)}
"""
```

### 5.5 Memory Maintenance

- **Append:** Every pipeline run appends an outcome entry (Sentinel/Weaver/merge result)
- **Summarize:** Every 20 runs, compress old entries into summary + lessons (keep full detail for last 10)
- **Promote:** When a lesson appears 3+ times, promote it to a standing rule in the domain context file
- **Prune:** Entries older than 90 days with no recurring pattern → archive

### 5.6 Memory Budget

Each domain memory file: target < 100 lines (last 5-10 detailed entries + summary of older patterns). The injected context per Forge run: ~200-400 tokens (lessons + last 3 outcomes).

---

## 6. Outcome Log — Post-Deploy Feedback

### 6.1 Purpose

Capture what happens after a PR is merged and deployed. This is the longest feedback loop but the most valuable for spec quality.

### 6.2 Mechanism

**Lightweight approach (start here):**

After merge, the pipeline creates a follow-up issue:

```markdown
## Outcome Check — PR #123: Add min_rate filter

**Deployed:** 2026-03-16
**Feature:** Decision engine min_rate filter

### Verification checklist (human fills in)
- [ ] Feature works as intended
- [ ] No regressions observed
- [ ] UX is acceptable
- [ ] Performance is acceptable

### Observations
[Human writes 1-3 sentences after using the feature]

### Rating
- [ ] Ship it (no issues)
- [ ] Minor issues (note below)
- [ ] Major issues (revert or fix needed)
```

**Automated approach (future):**

A monitoring agent checks production metrics after deploy:
- Error rate change
- Response time change
- User interaction patterns (if telemetry exists)
- Comparison of actual behavior vs spec

### 6.3 Outcome → Spec Feedback

When the human fills in the outcome check:
- **Ship it:** Outcome recorded in pipeline memory as "success"
- **Minor issues:** Observation feeds into the next sprint's context. The spec writer sees: "Last time we touched this area, the human noted: {observation}"
- **Major issues:** Creates a high-priority fix issue. Pipeline memory records the failure pattern.

---

## 7. Argus Integration (UI Pipeline)

### 7.1 Current Argus Flow

```
Design brief (wordsynk-ui issue)
  → Prototype updated (wordsynk-ui PR)
    → Review at http://192.168.0.26:8888 (across devices)
      → design:approved label
        → Production issue created
          → Forge implements against UI_SPEC.md
            → Arbiter checks vs approved screenshot
              → Merge
```

### 7.2 Enhanced Flow with Sentinel + Weaver

```
Design brief (wordsynk-ui issue)
  → Prototype updated (wordsynk-ui PR)
    → Review across devices
      → design:approved label
        → Production issue created
          → Forge implements against UI_SPEC.md
            → Sentinel: renders real page, captures screenshot, compares vs approved screenshot
              → Arbiter: diff review + Sentinel evidence
                → Weaver: is the new component mounted in a route? breakpoints correct?
                  → Merge
                    → Outcome: human checks real UI, notes observations
```

**Key addition:** Sentinel captures a real screenshot and performs visual comparison against the approved screenshot from `wordsynk-ui/screenshots/`. This automates what Arbiter currently does manually (checking visual divergence).

### 7.3 Visual Comparison

Sentinel uses Playwright to:
1. Navigate to the affected route at three breakpoints (mobile, tablet, desktop)
2. Capture screenshots
3. Compare against approved screenshots (pixel diff or LLM visual comparison)
4. Flag divergence above threshold

This directly addresses Argus rule #6: *"when reviewing a UI PR, check that the implementation matches the approved screenshot. Reject if visually divergent on any breakpoint."*

---

## 8. Herald Dispatch Changes

### 8.1 Current Dispatch

```
Herald classifies → selects model tier → dispatches to GHA
  Inputs: issue body, routing signals
  Outputs: workflow_dispatch with worker_model, task_tier, inference_backend
```

### 8.2 Enhanced Dispatch

```
Herald classifies → selects model tier → injects pipeline memory → dispatches to GHA
  New inputs: pipeline memory for the classified domain
  New outputs: sentinel_checks (list of domain-specific reality checks)
```

Herald determines which Sentinel checks to run based on the domain:
- `domain:decision-engine` → triple-registration check, evaluation cycle, API smoke test
- `domain:dashboard-ui` → build, screenshot capture, visual comparison
- `domain:backend-api` → service startup, endpoint smoke test, DB state verification
- `domain:fleet-devices` → ADB connectivity, heartbeat verification

This list is stored in `agents/sentinel/checks/` as domain-specific check scripts.

---

## 9. GHA Workflow Changes

### 9.1 Current Workflow

```yaml
# agent-worker.yml
jobs:
  forge:
    steps:
      - Checkout
      - Setup environment
      - Run Forge (understand → specify → locate → execute)
      - Lint + Build + Test gate
      - Create PR
  arbiter:
    needs: forge
    steps:
      - Review PR diff
      - APPROVE or REQUEST_CHANGES
```

### 9.2 Proposed Workflow

```yaml
# agent-worker.yml (enhanced)
jobs:
  forge:
    steps:
      - Checkout
      - Setup environment
      - Inject pipeline memory for domain
      - Run Forge (understand → specify → locate → execute)
      - Lint + Build + Test gate
      - Create PR

  sentinel:
    needs: forge
    steps:
      - Checkout PR branch
      - Start affected service(s)
      - Run domain-specific reality checks
      - Capture evidence (responses, screenshots, DB state)
      - Post evidence to PR
      - PASS → continue / FAIL → trigger Forge revision

  arbiter:
    needs: sentinel
    steps:
      - Review PR diff + Sentinel evidence
      - APPROVE or REQUEST_CHANGES

  weaver:
    needs: arbiter
    if: arbiter.outcome == 'APPROVE'
    steps:
      - Run integration coherence checks
      - COHERENT → auto-merge / INCOHERENT → return to Forge / WARNING → flag for human

  outcome:
    needs: weaver
    if: weaver.outcome == 'COHERENT'
    steps:
      - Record pipeline run in pipeline memory
      - Create outcome check issue (for human follow-up)
```

---

## 10. Implementation Phases

### Phase 1: Sentinel MVP (highest leverage)

**Scope:** Add Sentinel as a GHA job between Forge and Arbiter. Start with deterministic checks only (no LLM reasoning).

**Deliverables:**
1. `agents/sentinel/` directory with domain-specific check scripts
2. `sentinel.py` runtime (reads diff, selects checks, runs them, posts evidence)
3. GHA workflow updated with `sentinel` job
4. Pipeline memory structure created (empty, starts collecting)

**Sentinel checks (Phase 1):**
- Service starts cleanly (backend changes)
- Affected endpoints respond with 200 (backend changes)
- `npm run build` succeeds with real data (frontend changes)
- Triple-registration verified (decision engine changes)

**Effort:** ~2 sprints. Reuses existing `forge-pod` infrastructure.

### Phase 2: Pipeline Memory

**Scope:** Create the memory structure, wire it into Herald dispatch and Forge context.

**Deliverables:**
1. `pipeline-memory/` directory structure
2. Memory append on every pipeline run (in the `outcome` job)
3. Herald reads domain memory and injects into Forge context
4. Memory summarization script (compress after 20 entries)

**Effort:** ~1 sprint. Mostly wiring + template.

### Phase 3: Weaver + Enhanced Sentinel

**Scope:** Add Weaver as a GHA job. Upgrade Sentinel from deterministic to LLM-assisted.

**Deliverables:**
1. `agents/weaver/` directory with coherence check logic
2. `weaver.py` runtime (reads full files + reverse dependencies, checks connectivity)
3. Sentinel upgraded: Sonnet-powered analysis of what to check based on the diff
4. Playwright-based screenshot capture for UI changes

**Effort:** ~2 sprints.

### Phase 4: Outcome Feedback Loop

**Scope:** Close the full loop. Post-merge outcome capture feeds back to specs.

**Deliverables:**
1. Outcome check issue template (auto-created after merge)
2. Outcome → pipeline memory wiring (human fills in → memory updated)
3. CLA spec writer reads outcome history for the domain
4. Dashboard widget showing pipeline health (success rate, revision rate, outcome scores)

**Effort:** ~2 sprints.

---

## 11. Cost Model

| Component | Model | Per-run cost | Runs/day (est.) | Daily cost |
|-----------|-------|-------------|-----------------|------------|
| Herald | Haiku | $0.01 | 5 | $0.05 |
| CLA | Haiku/Sonnet | $0.03 | 5 | $0.15 |
| Forge | L1-L4 varies | $0.50-4.00 | 5 | $2.50-20.00 |
| **Sentinel** | **Sonnet** | **$0.05-0.15** | **5** | **$0.25-0.75** |
| Arbiter | Sonnet | $0.10 | 5 | $0.50 |
| **Weaver** | **Sonnet** | **$0.03-0.08** | **5** | **$0.15-0.40** |
| **Total new cost** | | | | **$0.40-1.15/day** |

Sentinel + Weaver add ~$0.40-1.15/day to the pipeline. If they prevent even one Forge revision cycle per week ($0.50-4.00), they pay for themselves.

---

## 12. Success Metrics

| Metric | Current baseline | Target after Phase 2 | Target after Phase 4 |
|--------|-----------------|---------------------|---------------------|
| Forge revision rate | Unknown | < 30% | < 15% |
| Integration failures (post-merge) | Unknown | Track | < 5% |
| "Product doesn't work" incidents | ~monthly | Track | < 1/quarter |
| Human review time per PR | Manual | Reduced (Sentinel evidence) | Minimal (Sentinel + Weaver) |
| Pipeline memory entries | 0 | 50+ | 200+ |
| Lessons promoted to standing rules | 0 | 5+ | 20+ |

---

## 13. Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Sentinel is too slow | 5-minute timeout. INCONCLUSIVE falls back to current flow. |
| Sentinel gives false negatives (passes broken code) | Start conservative — more checks, not fewer. False negative = current behavior. |
| Sentinel gives false positives (fails working code) | INCONCLUSIVE path. Human reviews evidence. Tune over time. |
| Pipeline memory grows too large | 100-line budget per domain. Auto-summarize. 90-day archive. |
| Weaver is too opinionated | Start with deterministic checks only. LLM reasoning in Phase 3. |
| Cost overrun | Sonnet for Sentinel/Weaver, not Opus. Budget ceiling per domain. |
| Added latency | Sentinel/Weaver run in parallel where possible. Total: ~7 min added. |

---

## 14. What Does NOT Change

The following components are working and should not be modified:

1. **Herald's 7-factor model routing** — proven, battle-tested
2. **CLA decomposition pipeline** — operationalizer → decomposer → scheduler
3. **Forge's 4-phase coding** — understand → specify → locate → execute
4. **Arbiter's diff review** — enhanced with Sentinel evidence, not replaced
5. **Argus UI design pipeline** — design-first with approved screenshots
6. **Sprint board** — task tracking and audit trail
7. **Model tier cascade** — L1-L4 with Oracle/Shard/Haiku/Sonnet/Opus
8. **Sprint discipline guard** — process enforcement with `sudo:` override
9. **Domain context files** — auto-generated, fetched by Herald

The proposal is additive. No existing component is replaced or significantly modified.

---

## 15. Decision Record

In the context of an autonomous agent pipeline that produces passing tests but non-functional software,
facing the problem that agents optimize for synthetic gates rather than product correctness,
we decided to add three feedback loops (Sentinel reality verification, Weaver integration coherence, Outcome feedback) and pipeline episodic memory,
and neglected the alternative of adding more human review gates (which doesn't scale and was already proven insufficient in SpecFlow),
to achieve a pipeline where every stage verifies its output against reality,
accepting that this adds ~$0.40-1.15/day in inference costs and ~7 minutes of pipeline latency per run.
