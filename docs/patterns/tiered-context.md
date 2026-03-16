# Pattern: Tiered Context Loading

## Problem
Loading all project knowledge at session start wastes tokens and displaces working memory. Loading nothing means the agent rediscovers knowledge through expensive source code reading.

## Solution
Three-tier loading model where knowledge loads progressively based on what the agent is actually working on.

## Tiers

### Tier 1: Always Loaded (Session Start)
**Budget:** < 1,500 tokens total

Contents:
- Root CLAUDE.md — project overview, command cheat sheet, safety rules, domain navigation table
- MEMORY.md — first 200 lines of operational rules and incident records
- Unscoped `.claude/rules/invariants.md` — safety constraints that apply everywhere

**Rule:** If it doesn't affect every task, it doesn't belong in Tier 1.

### Tier 2: Path-Triggered (On File Access)
**Budget:** 200-400 tokens per domain

Contents:
- `.claude/rules/<domain>.md` with `paths:` frontmatter
- Subdirectory CLAUDE.md files

**Trigger:** Agent reads a file → matching rule files auto-load.

**Rule:** One rule file per bounded context. Contains behavioral knowledge for that context.

### Tier 3: Task-Triggered (On Demand)
**Budget:** Variable

Contents:
- Skills (auto-triggered by task description)
- Commands (user-invoked)
- Source code (last resort)

**Rule:** If the agent needs source code to understand behavior, Tier 2 is incomplete.

## Implementation

```
project/
  CLAUDE.md                        # Tier 1: navigation + safety (< 150 lines)
  DOMAIN.md                        # Tier 2: loaded on demand
  .claude/
    rules/
      invariants.md                # Tier 1: no paths (always loaded)
      auth-flow.md                 # Tier 2: paths: ["src/auth/**"]
      data-pipeline.md             # Tier 2: paths: ["src/etl/**"]
      api-layer.md                 # Tier 2: paths: ["src/routes/**"]
    commands/
      start.md                     # Tier 3: user invokes /start
      wrap.md                      # Tier 3: user invokes /wrap
```

## Anti-Pattern: Everything in Tier 1

Signs:
- Root CLAUDE.md > 300 lines
- API reference tables in root file
- Behavioral knowledge for specific subsystems in always-loaded context
- Agent context fills up before productive work begins

Fix: Move domain-specific content to path-scoped rule files.

## Anti-Pattern: Nothing in Tier 2

Signs:
- `.claude/rules/` directory missing or empty
- Agent reads 5+ source files before producing output
- Operator frequently corrects agent's understanding
- Same exploratory patterns repeated across sessions

Fix: Write behavioral rule files for each bounded context.
