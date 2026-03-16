# /review — Audit Existing Agent Architecture

You are Agent Forge performing an agent architecture review. Analyze the target project's agent setup and produce a structured correction plan.

## Input
The operator provides:
- A path to a project directory, OR
- A GitHub repo URL, OR
- The current project (if running inside it)

## Process

### Step 1: Context Inventory

Read ALL agent context files:

```
Files to check:
- CLAUDE.md (root)
- **/CLAUDE.md (subdirectories)
- .claude/rules/*.md
- .claude/commands/*.md
- .claude/settings.json
- .claude/settings.local.json
- MEMORY.md or memory/ directory
- DOMAIN.md
- docs/decisions/
- SESSION.md, SESSION_NEXT.md
- Any other .md files referenced by CLAUDE.md
```

For each file found, record: path, line count, content categories.

### Step 2: Metrics Assessment

Score each dimension:

| Dimension | A (Excellent) | B (Good) | C (Needs Work) | D (Poor) | F (Missing) |
|-----------|---------------|----------|-----------------|----------|-------------|
| Tier 1 Structure | < 150 lines, nav + safety only | < 200 lines | < 300 lines, some behavioral | > 300 lines | No CLAUDE.md |
| Tier 2 Coverage | Rule per context, all path-scoped | Most contexts covered | Some rules, mixed scoping | 1-2 rules | No .claude/rules/ |
| Behavioral Density | 1:10-1:25 compression | 1:5-1:10 | 1:1-1:5 (restating code) | Rules exist but wrong content | No behavioral knowledge |
| Memory Types | Semantic + Episodic + Procedural | 2 of 3 | Semantic only | Partial semantic | No persistent memory |
| Session Protocol | Start + wrap + behavioral checkpoint | Start + wrap | Start only | Ad-hoc | None |
| Token Budget | < 1,500 always-loaded | < 2,500 | < 4,000 | > 4,000 | Not managed |

### Step 3: Anti-Pattern Scan

Check each anti-pattern from `docs/anti-patterns/common-failures.md`:

```
[ ] AP-01: Monolithic CLAUDE.md (> 300 lines)
[ ] AP-02: Behavioral knowledge only in comments
[ ] AP-03: No Tier 2 (no .claude/rules/)
[ ] AP-04: Over-engineered startup (> 15 turns)
[ ] AP-05: Apology without correction protocol
[ ] AP-06: Configuration bandaid pattern
[ ] AP-07: Scope creep tendency
[ ] AP-08: Duplicated knowledge across files
[ ] AP-09: Exploratory paralysis (no behavioral layer)
[ ] AP-10: Implicit domain knowledge not captured
[ ] AP-11: Flat memory (no episodic records)
[ ] AP-12: Wrap = git push only
```

### Step 4: Three-Tier Gap Analysis

For each identified bounded context in the codebase:

| Context | Tier 1 (WHERE) | Tier 2 (HOW) | Status |
|---------|---------------|--------------|--------|
| [context] | [Present/Missing] | [Present/Missing/Stale] | [OK/Gap/Stale] |

### Step 5: Correction Plan

Generate a prioritized correction plan:

```markdown
## Agent Architecture Correction Plan

### Project: [name]
### Review Date: [date]
### Overall Grade: [A-F]

### Critical (do immediately)
1. [Fix] — [estimated effort]

### High Priority (this sprint)
1. [Fix] — [estimated effort]

### Medium Priority (next sprint)
1. [Fix] — [estimated effort]

### Low Priority (when convenient)
1. [Fix] — [estimated effort]

### Token Budget
| | Current | Target |
|---|---------|--------|
| Always-loaded | X tokens | Y tokens |
| Per-task average | X tokens | Y tokens |
| Source re-reading | X tokens/session | Y tokens/session |
```

### Step 6: Offer Implementation

Ask the operator: "Shall I implement any of these corrections now?"

If yes, work through the correction plan using the scaffolding protocol for new files and careful editing for existing files.

## References
- `knowledge/review-checklist.md` — Full checklist details
- `docs/anti-patterns/common-failures.md` — Anti-pattern catalog
- `docs/patterns/` — Correct patterns to recommend
