# WORKDIR: cortex
# MODEL: sonnet
# PAUSE: no
# TIMEOUT: 600

# Sprint 06 — cortex cascade_client.py Audit

## Context

The cortex runtime scripts (`operationalizer.py`, `cla.py`, etc.) import `anthropic` directly.
There is a `runtime/cascade_client.py` abstraction that should be used instead, but it's bypassed.

Sprint 06 audits the current state and produces a precise refactor plan. Sprint 07 will execute it.

WORKDIR is `/Users/pawelgiers/Projects/cortex`.

## Steps

### Step 1: Survey cortex Structure

```bash
ls /Users/pawelgiers/Projects/cortex/
ls /Users/pawelgiers/Projects/cortex/runtime/ 2>/dev/null || echo "no runtime dir"
find /Users/pawelgiers/Projects/cortex -name "*.py" | grep -v __pycache__ | grep -v ".git" | sort
```

### Step 2: Read cascade_client.py Fully

```bash
cat runtime/cascade_client.py
```

Understand:
- What does it do currently?
- What API does it expose?
- Does it call the cascade-router, or does it call Anthropic directly?
- What parameters does it accept?
- What does it return?

### Step 3: Read Direct-Import Files

Read the first 100 lines of each of these files to find all `import anthropic` / `anthropic.Anthropic()` usages:

```bash
head -100 runtime/operationalizer.py
head -100 runtime/cla.py
head -100 runtime/decomposer.py 2>/dev/null || echo "no decomposer.py"
head -100 runtime/scheduler.py 2>/dev/null || echo "no scheduler.py"
```

For each file, also grep for all anthropic usage:
```bash
grep -n "anthropic\|Anthropic\|claude-" runtime/operationalizer.py runtime/cla.py
grep -n "anthropic\|Anthropic\|claude-" runtime/decomposer.py runtime/scheduler.py 2>/dev/null
```

### Step 4: Map the Full Anthropic Usage Pattern

For `operationalizer.py` and `cla.py` specifically, understand:
- How is the Anthropic client instantiated? (`anthropic.Anthropic(api_key=...)` or `anthropic.Anthropic()`?)
- What model is called? (claude-opus-4-6? claude-sonnet-4-6?)
- What does the call look like? (`client.messages.create(...)`)
- What are the params: max_tokens, temperature, system prompt pattern?
- Is there any retry/error handling around the call?

Read more of each file if needed:
```bash
grep -n -A 10 "anthropic.Anthropic\|client.messages.create" runtime/operationalizer.py
grep -n -A 10 "anthropic.Anthropic\|client.messages.create" runtime/cla.py
```

### Step 5: Assess cascade_client.py Gap

After reading `cascade_client.py` and the direct-import files, answer:

1. Does `cascade_client.py` currently call the cascade router at `:3032`, or does it call Anthropic directly?
2. What interface would the runtime files need? (e.g., `cascade_client.complete(prompt, tier="L2")`)
3. What changes are needed to `cascade_client.py` to make it a proper abstraction:
   - It should `GET http://localhost:3032/api/cascade/resolve?tier=LN` to get the backend
   - Then call that backend's API
   - Environment var: `CASCADE_ROUTER_URL` (default `http://localhost:3032`)
4. Are there any complications: async vs sync, streaming, specific response format expectations?

### Step 6: Write Refactor Plan

Create `memory/cascade-refactor-plan.md` in cortex:

```bash
mkdir -p memory
```

Sections:

**CURRENT_STATE** — What cascade_client.py does today. What operationalizer.py and cla.py do today. The gap.

**TARGET_STATE** — What cascade_client.py should do after refactor. The interface runtime files should use.

**cascade_client_changes** — Specific changes needed to cascade_client.py:
- New function signatures (if changing)
- How to call cascade router at :3032
- Environment var: `CASCADE_ROUTER_URL`
- What to do if cascade router is unreachable (fail fast, don't fall back to direct Anthropic)

**operationalizer_changes** — Line-by-line change plan for operationalizer.py:
- Remove: `import anthropic` line(s)
- Replace: `anthropic.Anthropic(...)` instantiation with cascade_client import
- Replace: each `client.messages.create(...)` call with cascade_client call
- Exact function signatures to use

**cla_changes** — Same for cla.py

**other_files** — Any other files that need changes (decomposer, scheduler)

**refactor_steps** — Ordered numbered list of exact steps to execute in Sprint 07

**test_plan** — How to verify the refactor works without running the full pipeline

## Expected Outputs

1. File created: `memory/cascade-refactor-plan.md`
2. Contains sections: CURRENT_STATE, TARGET_STATE, cascade_client_changes, operationalizer_changes, cla_changes, refactor_steps, test_plan
3. operationalizer_changes and cla_changes have line-specific edit instructions
4. The word "operationalizer" appears in the file
5. The word "refactor_steps" appears as a section header
