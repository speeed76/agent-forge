# WORKDIR: cortex
# MODEL: opus
# PAUSE: no
# TIMEOUT: 1200

# Sprint 07 — cortex Direct Import Refactor

## Context

Sprint 06 produced `memory/cascade-refactor-plan.md` — a precise plan for replacing direct `import anthropic` calls in cortex runtime with `cascade_client.py` calls through the cascade router at `:3032`.

Sprint 07 executes that plan.

WORKDIR: `/Users/pawelgiers/Projects/cortex`

**Why this matters**: Every direct `import anthropic` bypasses the cascade router's tier selection logic. Oracle (qwen3-coder:30b) and Shard (qwen2.5-coder:14b) should handle routine work; Claude API is the expensive fallback. Bypassing cascade-router means every call goes to Claude API directly, burning API budget and ignoring available local compute.

## Steps

### Step 1: Read the Refactor Plan

```bash
cat memory/cascade-refactor-plan.md
```

Follow this plan precisely. If any step is unclear or the plan references a line number that doesn't match the current file, use your judgment to apply the intent correctly.

### Step 2: Read Current cascade_client.py

```bash
cat runtime/cascade_client.py
```

Understand the current interface before modifying it.

### Step 3: Update cascade_client.py

If cascade_client.py doesn't already route through the cascade router, update it:

The correct pattern:
```python
import os
import requests

CASCADE_ROUTER_URL = os.environ.get("CASCADE_ROUTER_URL", "http://localhost:3032")

def complete(prompt: str, tier: str = "L2", system: str = None, max_tokens: int = 4096) -> str:
    """Route an LLM completion through the cascade router."""
    # Step 1: Resolve backend for this tier
    resolve_resp = requests.get(
        f"{CASCADE_ROUTER_URL}/api/cascade/resolve",
        params={"tier": tier},
        timeout=10
    )
    resolve_resp.raise_for_status()
    backend = resolve_resp.json()

    # Step 2: Call the resolved backend
    # (Implementation depends on what cascade router returns)
    ...
```

Alternatively, if the cascade router has a `/api/cascade/complete` endpoint that handles the full flow, use that instead — check the cascade-router source:
```bash
grep -r "complete\|/complete" /Users/pawelgiers/Projects/mission-control/cascade-router/ 2>/dev/null | grep -v ".git" | head -20
grep -r "complete\|/complete" /Users/pawelgiers/Projects/wordsynk-automation-sys/cascade-router/ 2>/dev/null | grep -v ".git" | head -20
```

Use whatever interface the cascade router actually exposes. Read its routes:
```bash
find /Users/pawelgiers/Projects/mission-control/cascade-router/src -name "*.js" 2>/dev/null | head -5
# or
find /Users/pawelgiers/Projects/wordsynk-automation-sys/cascade-router -name "*.js" 2>/dev/null | head -10
```

### Step 4: Refactor operationalizer.py

Based on the plan from Sprint 06:

1. Remove the `import anthropic` line(s)
2. Add import: `from runtime.cascade_client import complete as cascade_complete` (adjust import path as needed)
3. Replace each `client.messages.create(...)` call with the cascade_client equivalent
4. Remove the `anthropic.Anthropic(api_key=...)` instantiation

After editing, verify no direct imports remain:
```bash
grep -n "import anthropic\|anthropic\.Anthropic" runtime/operationalizer.py && echo "STILL HAS DIRECT IMPORTS" || echo "clean"
```

### Step 5: Refactor cla.py

Same process for cla.py:

1. Remove `import anthropic` line(s)
2. Add cascade_client import
3. Replace all `client.messages.create(...)` calls
4. Remove anthropic client instantiation

After editing:
```bash
grep -n "import anthropic\|anthropic\.Anthropic" runtime/cla.py && echo "STILL HAS DIRECT IMPORTS" || echo "clean"
```

### Step 6: Test Import Verification

```bash
python3 -c "import sys; sys.path.insert(0, '.'); from runtime import operationalizer; print('operationalizer import: OK')" 2>&1
python3 -c "import sys; sys.path.insert(0, '.'); from runtime import cla; print('cla import: OK')" 2>&1
```

If import fails due to missing dependencies (requests, etc.), fix them. If it fails due to missing CASCADE_ROUTER_URL (service not running), that's acceptable — the import itself should succeed.

### Step 7: Run Full Import Check

```bash
grep -r "import anthropic" runtime/*.py 2>/dev/null && echo "WARNING: direct imports still found" || echo "All clear — no direct anthropic imports"
```

### Step 8: Commit and Push

```bash
git add runtime/operationalizer.py runtime/cla.py runtime/cascade_client.py
git status

git commit -m "refactor: route LLM calls through cascade-router instead of direct anthropic imports

- operationalizer.py: replaced anthropic.Anthropic() with cascade_client
- cla.py: replaced anthropic.Anthropic() with cascade_client
- cascade_client.py: updated to route through cascade-router at :3032

CASCADE_ROUTER_URL env var controls endpoint (default: http://localhost:3032)

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"

git push origin main
```

If pushing fails (remote has changes), pull first:
```bash
git pull --rebase origin main
git push origin main
```

## Expected Outputs

1. `runtime/operationalizer.py` — no `import anthropic` lines
2. `runtime/cla.py` — no `import anthropic` lines
3. `runtime/cascade_client.py` — routes through cascade router
4. `python3 -c "from runtime import operationalizer"` exits 0
5. `git log --oneline -1` shows a new commit with "cascade" in message
6. Changes pushed to `speeed76/cortex`
