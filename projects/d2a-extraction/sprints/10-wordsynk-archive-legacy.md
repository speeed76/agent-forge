# WORKDIR: wordsynk-automation-sys
# MODEL: haiku
# PAUSE: no
# TIMEOUT: 300

# Sprint 10 — wordsynk: Archive Legacy Agents

## Context

The `wordsynk-automation-sys/agents/` directory contains legacy Herald JS dispatcher and other files that have been superseded by mission-control. They should be archived (not deleted) to preserve reference material.

Legacy items to archive:
- `agents/dispatcher/` — Herald JS dispatcher (superseded by mission-control pipeline)
- `agents/worker/worker.py` — old worker (superseded by cortex runtime)
- `agents/reviewer/reviewer.py` — old reviewer (superseded by Arbiter)

## Steps

### Step 1: Survey What Exists

```bash
ls agents/
ls agents/dispatcher/ 2>/dev/null || echo "no dispatcher dir"
ls agents/worker/ 2>/dev/null || echo "no worker dir"
ls agents/reviewer/ 2>/dev/null || echo "no reviewer dir"
```

Record exactly what exists before making any changes.

### Step 2: Create Archive Directory

```bash
mkdir -p agents/_archive
```

### Step 3: Archive dispatcher/ (Herald JS)

```bash
# Check if dispatcher exists
if [ -d "agents/dispatcher" ]; then
  mv agents/dispatcher agents/_archive/dispatcher-herald-legacy
  echo "Moved dispatcher to _archive/dispatcher-herald-legacy"
else
  echo "agents/dispatcher does not exist — nothing to move"
fi
```

### Step 4: Archive worker.py (if exists as standalone)

```bash
if [ -f "agents/worker/worker.py" ]; then
  # Check if there are other files in worker/
  OTHER_FILES=$(ls agents/worker/ | grep -v "worker.py" | wc -l)
  if [ "$OTHER_FILES" -gt 0 ]; then
    echo "worker/ has other files: $(ls agents/worker/)"
    # Move just worker.py, preserving the directory for other files
    cp agents/worker/worker.py agents/_archive/worker-legacy.py
    # Remove from original only if confirmed superseded
    rm agents/worker/worker.py
    echo "Moved worker.py to _archive (other files remain in agents/worker/)"
  else
    mv agents/worker/worker.py agents/_archive/worker-legacy.py
    echo "Moved worker.py to _archive"
  fi
else
  echo "agents/worker/worker.py does not exist"
fi
```

### Step 5: Archive reviewer.py (if exists as standalone)

```bash
if [ -f "agents/reviewer/reviewer.py" ]; then
  mv agents/reviewer/reviewer.py agents/_archive/reviewer-legacy.py
  echo "Moved reviewer.py to _archive"
else
  echo "agents/reviewer/reviewer.py does not exist"
fi
```

### Step 6: Create _archive/README.md

```bash
cat > agents/_archive/README.md << 'EOF'
# Archived Legacy Agents

These files have been superseded by the mission-control d2a pipeline.
Preserved here for reference only — do NOT re-activate.

## Archived Items

### dispatcher-herald-legacy/
- **Was**: Herald JS dispatcher — routed booking automation requests
- **Superseded by**: mission-control service at :3031
- **Archived**: Sprint 10 (d2a extraction)

### worker-legacy.py
- **Was**: Python worker that processed booking automation tasks
- **Superseded by**: cortex runtime (`/Users/pawelgiers/Projects/cortex/runtime/`)
- **Archived**: Sprint 10 (d2a extraction)

### reviewer-legacy.py
- **Was**: Code review agent
- **Superseded by**: Arbiter (GHA-integrated review step in d2a pipeline)
- **Archived**: Sprint 10 (d2a extraction)

## Why Kept (Not Deleted)
Historical reference for understanding the old architecture.
If there is ever a regression, these files document how the previous system worked.
EOF
```

### Step 7: Verify Structure

```bash
ls agents/
ls agents/_archive/
# Confirm dispatcher is gone from active location
ls agents/dispatcher 2>/dev/null && echo "WARNING: dispatcher still in active location" || echo "OK: dispatcher removed from active location"
# Confirm archive exists
ls agents/_archive/dispatcher-herald-legacy/ | head -5
```

### Step 8: Commit

```bash
git add agents/_archive/
git add agents/dispatcher agents/worker agents/reviewer 2>/dev/null || true  # stage deletions
git status

git commit -m "archive: move legacy Herald dispatcher + workers to agents/_archive

Superseded by mission-control d2a pipeline. Preserved for reference.
- agents/dispatcher/ → agents/_archive/dispatcher-herald-legacy/
- agents/worker/worker.py → agents/_archive/worker-legacy.py
- agents/reviewer/reviewer.py → agents/_archive/reviewer-legacy.py

Co-Authored-By: Claude Haiku 4.5 <noreply@anthropic.com>"
```

## Expected Outputs

1. `agents/_archive/dispatcher-herald-legacy/` exists
2. `agents/dispatcher/` no longer exists (moved to _archive)
3. `agents/_archive/README.md` exists with explanation
4. Git commit created with archive message
