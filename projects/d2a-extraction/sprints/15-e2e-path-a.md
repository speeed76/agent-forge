# WORKDIR: mission-control
# MODEL: opus
# PAUSE: no
# TIMEOUT: 1800

# Sprint 15 — E2E Smoke Test: PawsOnLeash (Path A)

## Context

All infrastructure is in place. This is the first real end-to-end test of the d2a pipeline after extraction from wordsynk.

**Test**: Submit the PawsOnLeash spec (a pet care app) to the pipeline. Use Path A (greenfield scaffold on cobalt-sandbox).

Path A = clean slate on cobalt-sandbox. The pipeline should:
1. Accept the spec POST
2. Route through cascade-router to select LLM backend
3. cortex decomposer breaks the spec into tasks
4. cortex scheduler plans execution
5. cortex operationalizer generates code
6. Forge GHA runner creates a PR on cobalt-sandbox
7. Sentinel validates the PR
8. Arbiter decides to merge or request changes

Sprint 15 monitors this full flow and captures results.

**Maximum wait**: 20 minutes (1200 seconds) for a PR to appear.

## Steps

### Step 1: Read Health Check Report

```bash
cat memory/health-check-*.md 2>/dev/null | tail -50 || echo "no health report found — run Sprint 13 first"
```

If the report says "HOLD", do not proceed with the test. Document the blocker.
If "PROCEED", continue.

### Step 2: Read Pipeline API Documentation

Find out how to POST to the pipeline:

```bash
# Check if there's an API doc
cat README.md 2>/dev/null | grep -A 20 "API\|endpoint\|POST" | head -40
cat docs/api.md 2>/dev/null | head -60 || echo "no api.md"

# Try to find the route from source
find . -name "*.js" -o -name "*.ts" | xargs grep -l "pipeline/run\|/api/pipeline" 2>/dev/null | head -5
```

If docs aren't available, try the health endpoint to understand the API:
```bash
curl -sf http://localhost:3031/ 2>/dev/null | python3 -m json.tool 2>/dev/null || curl -sf http://localhost:3031/health
```

### Step 3: Prepare PawsOnLeash Test Fixture

PawsOnLeash is a pet care app (dog walking booking + Airtable integration). Fixture data:

```json
{
  "spec": {
    "projectName": "PawsOnLeash",
    "description": "Pet care booking platform with dog walker scheduling, Airtable integration, and SMS notifications",
    "targetRepo": "speeed76/cobalt-sandbox",
    "branch": "feature/pawsonleash-scaffold",
    "path": "path-a-greenfield",
    "features": [
      "Dog walker booking system",
      "Airtable-backed scheduler",
      "Twilio SMS notifications for booking confirmations",
      "Calendar availability view",
      "Admin dashboard for walker management"
    ],
    "stack": "Node.js + Express + Airtable API",
    "tier": "L2",
    "testMode": true
  }
}
```

Save this to a temp file:
```bash
cat > /tmp/pawsonleash-fixture.json << 'FIXTURE'
{
  "spec": {
    "projectName": "PawsOnLeash",
    "description": "Pet care booking platform with dog walker scheduling, Airtable integration, and SMS notifications",
    "targetRepo": "speeed76/cobalt-sandbox",
    "branch": "feature/pawsonleash-scaffold",
    "path": "path-a-greenfield",
    "features": [
      "Dog walker booking system",
      "Airtable-backed scheduler",
      "Twilio SMS notifications for booking confirmations",
      "Calendar availability view",
      "Admin dashboard for walker management"
    ],
    "stack": "Node.js + Express + Airtable API",
    "tier": "L2",
    "testMode": true
  }
}
FIXTURE
```

### Step 4: Submit the Pipeline Request

```bash
RESPONSE=$(curl -sf -X POST http://localhost:3031/api/pipeline/run \
  -H "Content-Type: application/json" \
  -d @/tmp/pawsonleash-fixture.json 2>&1)
echo "Pipeline response: $RESPONSE"

# Extract pipeline_id if present
PIPELINE_ID=$(echo "$RESPONSE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('pipeline_id', d.get('id', 'unknown')))" 2>/dev/null || echo "unknown")
echo "Pipeline ID: $PIPELINE_ID"
```

If the endpoint path is different (e.g., `/api/run`, `/pipeline`, etc.), try variations:
```bash
curl -sf http://localhost:3031/ 2>/dev/null | python3 -m json.tool
```

### Step 5: Monitor Pipeline Progress

Poll for status every 30 seconds for up to 20 minutes:

```bash
START_TIME=$(date +%s)
MAX_WAIT=1200
PR_NUMBER=""

while true; do
  ELAPSED=$(( $(date +%s) - START_TIME ))
  if [ $ELAPSED -gt $MAX_WAIT ]; then
    echo "TIMEOUT: No PR after ${MAX_WAIT}s"
    break
  fi

  # Check for PR on cobalt-sandbox
  PR_NUMBER=$(gh api repos/speeed76/cobalt-sandbox/pulls \
    --jq '.[0].number' 2>/dev/null || echo "")

  if [ -n "$PR_NUMBER" ] && [ "$PR_NUMBER" != "null" ]; then
    echo "PR created: #$PR_NUMBER (after ${ELAPSED}s)"
    break
  fi

  # Check pipeline status if endpoint exists
  if [ "$PIPELINE_ID" != "unknown" ]; then
    STATUS=$(curl -sf "http://localhost:3031/api/pipeline/$PIPELINE_ID/status" 2>/dev/null | \
      python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('status', 'unknown'))" 2>/dev/null || echo "no status endpoint")
    echo "[${ELAPSED}s] Pipeline status: $STATUS"
  fi

  sleep 30
done
```

### Step 6: Capture PR Details

If a PR was created:
```bash
if [ -n "$PR_NUMBER" ] && [ "$PR_NUMBER" != "null" ]; then
  PR_DATA=$(gh api repos/speeed76/cobalt-sandbox/pulls/$PR_NUMBER --jq '{
    number: .number,
    title: .title,
    url: .html_url,
    state: .state,
    files: .changed_files,
    created_at: .created_at
  }')
  echo "PR Details: $PR_DATA"

  # Check for Sentinel comment
  SENTINEL=$(gh api repos/speeed76/cobalt-sandbox/pulls/$PR_NUMBER/reviews \
    --jq '.[].body' 2>/dev/null | head -5)
  echo "Review comments: $SENTINEL"

  # Check CI checks
  CHECKS=$(gh api repos/speeed76/cobalt-sandbox/commits/$(gh api repos/speeed76/cobalt-sandbox/pulls/$PR_NUMBER --jq .head.sha)/check-runs \
    --jq '[.check_runs[] | {name: .name, status: .status, conclusion: .conclusion}]' 2>/dev/null)
  echo "CI checks: $CHECKS"
fi
```

### Step 7: Write E2E Results

Create `memory/e2e-results-$(date +%Y-%m-%d).md`:

Sections:
- **TEST_SPEC** — what was submitted (PawsOnLeash, Path A, cobalt-sandbox)
- **PIPELINE_RESPONSE** — raw response from POST to :3031
- **PIPELINE_ID** — extracted ID
- **TIMELINE** — timestamp of POST, time for PR to appear (or TIMEOUT)
- **PR_RESULT** — PR number, URL, title, file count (or NO_PR if timed out)
- **CASCADE_ROUTING** — which LLM backend was selected (if observable from logs)
- **SENTINEL_RESULT** — sentinel/review comments on the PR
- **ARBITER_DECISION** — merge or request changes (if Arbiter ran)
- **ISSUES** — anything that went wrong or behaved unexpectedly
- **VERDICT** — PASS / PARTIAL / FAIL with explanation

## Expected Outputs

1. `memory/e2e-results-[DATE].md` file created
2. File contains all required sections
3. `gh api repos/speeed76/cobalt-sandbox/pulls --jq '.[0].number'` returns a number (PR created)
   OR file documents why no PR was created (service not available, config issue, etc.)
