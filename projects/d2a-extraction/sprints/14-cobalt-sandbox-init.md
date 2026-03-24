# WORKDIR: mission-control
# MODEL: haiku
# PAUSE: yes
# TIMEOUT: 300

# Sprint 14 — cobalt-sandbox Initialization

## Pause Instructions

Before this sprint can run, you must initialize the cobalt-sandbox repository on GitHub.

### Step A: Create the Repository

If `speeed76/cobalt-sandbox` doesn't exist yet:

```bash
gh repo create speeed76/cobalt-sandbox --public --description "d2a pipeline sandbox for greenfield Forge scaffolds"
```

OR via GitHub UI: github.com → New repository → speeed76/cobalt-sandbox → Public → Create.

### Step B: Initialize with a Commit

```bash
cd /tmp
rm -rf cobalt-sandbox
git clone https://github.com/speeed76/cobalt-sandbox.git
cd cobalt-sandbox
echo '# cobalt-sandbox

Sandbox repository for the d2a pipeline. Forge agents scaffold new applications here.' > README.md
git add README.md
git commit -m "init: cobalt-sandbox for d2a Forge scaffolds"
git push origin main
```

### Step C: Configure FORGE_PAT Access

1. Go to **GitHub → Settings → Developer Settings → Personal Access Tokens → Fine-grained tokens**
2. Find the token named `FORGE_PAT` (used by the d2a pipeline GHA runner)
3. Under "Repository access" → add `speeed76/cobalt-sandbox` to the allowlist
4. Save changes

### Step D: Verify and Continue

Verify the repo is accessible:
```bash
gh api repos/speeed76/cobalt-sandbox/commits/main --jq '.sha'
```

Should return a 40-character hex SHA.

**When all steps are complete**, create the continue file:
```bash
touch /Users/pawelgiers/Projects/agent-forge/projects/d2a-extraction/results/sprint-14.continue
```

---

## Agent Steps (After Human Completes Pause)

### Step 1: Verify cobalt-sandbox Exists and Has a Commit

```bash
gh api repos/speeed76/cobalt-sandbox/commits/main --jq '.sha' 2>/dev/null || echo "repo not accessible or no main branch"
```

The SHA must be a 40-char hex string. If not, the human hasn't completed the pause steps.

### Step 2: Verify FORGE_PAT Access

```bash
# Check FORGE_PAT env var
echo "FORGE_PAT length: ${#FORGE_PAT} chars"

# Test access with FORGE_PAT
if [ -n "$FORGE_PAT" ]; then
  gh api repos/speeed76/cobalt-sandbox --token "$FORGE_PAT" --jq '.full_name' 2>/dev/null && echo "FORGE_PAT access: OK" || echo "FORGE_PAT access: DENIED — need to add cobalt-sandbox to allowlist"
else
  echo "FORGE_PAT not set in environment — check .env or GHA secrets"
fi
```

If FORGE_PAT is not set, find it:
```bash
# Check common locations
cat ~/.env 2>/dev/null | grep FORGE_PAT || true
cat /Users/pawelgiers/Projects/mission-control/.env 2>/dev/null | grep FORGE_PAT || true
```

### Step 3: Update memory/pipeline.md

Update the `COBALT_STATUS` or `FORGE_PAT` section in `memory/pipeline.md`:

Set cobalt-sandbox status to `READY` with today's date and the SHA.

```bash
# Get the SHA
SHA=$(gh api repos/speeed76/cobalt-sandbox/commits/main --jq '.sha' 2>/dev/null)
echo "cobalt-sandbox SHA: $SHA"
```

Add to memory/pipeline.md under COBALT_STATUS or at the end:
```
## cobalt-sandbox
- Status: READY
- Repo: speeed76/cobalt-sandbox
- Init SHA: [SHA]
- Date: [today]
- FORGE_PAT access: [YES/NO — checked Sprint 14]
```

## Expected Outputs

1. `gh api repos/speeed76/cobalt-sandbox/commits/main --jq .sha` returns a 40-char hex SHA
2. `memory/pipeline.md` updated with cobalt-sandbox READY status
3. FORGE_PAT access verified (or issue documented in pipeline.md)
