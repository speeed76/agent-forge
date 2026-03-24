# WORKDIR: wordsynk-automation-sys
# MODEL: sonnet
# PAUSE: no
# TIMEOUT: 600

# Sprint 11 — wordsynk: Clean Context

## Context

`wordsynk-automation-sys` is a booking automation system. It should not own the d2a pipeline context.
The d2a pipeline context now lives in `mission-control`.

Sprint 11 cleans up the wordsynk CLAUDE.md to remove d2a pipeline references that now live in mission-control, and removes stale files.

**Important**: This is surgical. Only remove d2a/pipeline-specific content. Keep booking automation context intact.

## Steps

### Step 1: Read Current State

```bash
cat CLAUDE.md
echo "---SESSION.md---"
cat SESSION.md | head -100
echo "---SESSION_NEXT.md (if exists)---"
cat SESSION_NEXT.md 2>/dev/null || echo "not found"
echo "---pipeline-safety.md (if exists)---"
cat .claude/rules/pipeline-safety.md 2>/dev/null || echo "not found"
```

Count current pipeline references:
```bash
grep -c "pipeline-safety\|Herald\|Forge\|Arbiter\|mission-control\|d2a\|cortex" CLAUDE.md || echo "0 matches"
```

### Step 2: Update CLAUDE.md

Make these specific changes to CLAUDE.md:

**Remove**: The "Pipeline (Herald, Forge, Arbiter, CI/CD)" domain navigation entry (if it exists in the domain nav table).

**Add** (in the "External Tools" or "Host Environment" section, or create one):
```
d2a pipeline: external service at :3031. Config: `d2a.config.json`. See `/Users/pawelgiers/Projects/mission-control/CLAUDE.md`.
```

**Remove** (if present): Any reference to `pipeline-safety.md` from `.claude/rules/`.

**Keep intact**: All booking automation content (Airtable, scheduling, webhook, calendar, etc.)

Use targeted edits — read the file section by section and make minimal changes.

After editing, verify:
```bash
grep -c "pipeline-safety\|Herald\|Forge\|Arbiter" CLAUDE.md
# Should be ≤ 2
```

### Step 3: Delete SESSION_NEXT.md

If `SESSION_NEXT.md` exists and it contains d2a/PawsOnLeash pipeline planning:
```bash
cat SESSION_NEXT.md 2>/dev/null | head -20
# If it's about the d2a E2E test or PawsOnLeash, delete it:
rm -f SESSION_NEXT.md && echo "deleted SESSION_NEXT.md"
```

The PawsOnLeash plan now lives in `mission-control/memory/`.

### Step 4: Trim SESSION.md

Read SESSION.md and identify sections about the d2a pipeline (not booking automation).

For each d2a/pipeline section in SESSION.md (sessions where the work was about Forge, Arbiter, cascade-router, cortex, specflow, cobalt-relay, etc.):

Replace the detailed content with a one-line summary:
```
[DATE] d2a pipeline work — see mission-control/memory/pipeline.md for context
```

Do NOT remove booking automation session entries (Airtable, calendar, scheduling work).

**Be conservative**: If a session entry is ambiguous, keep it.

After trimming, check:
```bash
wc -l SESSION.md
```

### Step 5: Remove pipeline-safety.md from .claude/rules/

If `pipeline-safety.md` exists in wordsynk's `.claude/rules/`, remove it:
```bash
ls .claude/rules/ 2>/dev/null || echo "no rules dir"
if [ -f ".claude/rules/pipeline-safety.md" ]; then
  rm .claude/rules/pipeline-safety.md
  echo "Removed pipeline-safety.md from wordsynk rules"
else
  echo "pipeline-safety.md not in wordsynk rules — nothing to remove"
fi
```

The behavioral contract for pipeline safety now lives in `mission-control/.claude/rules/pipeline-safety.md`.

### Step 6: Final Verification

```bash
# Should be ≤ 2
PIPELINE_REFS=$(grep -c "pipeline-safety\|Herald\|Forge\|Arbiter" CLAUDE.md 2>/dev/null || echo "0")
echo "Pipeline refs in CLAUDE.md: $PIPELINE_REFS"

# Should not exist
ls .claude/rules/pipeline-safety.md 2>/dev/null && echo "WARNING: pipeline-safety.md still exists" || echo "OK: pipeline-safety.md gone"

# Should not exist
ls SESSION_NEXT.md 2>/dev/null && echo "WARNING: SESSION_NEXT.md still exists" || echo "OK: SESSION_NEXT.md gone"
```

### Step 7: Commit

```bash
git add CLAUDE.md SESSION.md
git rm SESSION_NEXT.md 2>/dev/null || true
git rm .claude/rules/pipeline-safety.md 2>/dev/null || true
git status

git commit -m "chore: remove d2a pipeline context from wordsynk (moved to mission-control)

- CLAUDE.md: removed pipeline nav entries, added external ref to :3031
- SESSION.md: replaced detailed d2a entries with summary pointers
- Deleted SESSION_NEXT.md (content now in mission-control/memory/)
- Deleted .claude/rules/pipeline-safety.md (now in mission-control)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

## Expected Outputs

1. `CLAUDE.md` — pipeline refs (Herald/Forge/Arbiter/pipeline-safety) count ≤ 2
2. `.claude/rules/pipeline-safety.md` — does NOT exist in wordsynk
3. `SESSION_NEXT.md` — does NOT exist
4. `SESSION.md` — d2a entries replaced with summary pointers
5. Git commit created
