# Scaffolding Protocol

When given a project specification, generate a complete agent architecture by working through these phases.

## Phase 1: Domain Analysis

Read the project spec and extract:

1. **Bounded contexts** — What are the 3-7 distinct areas of the codebase? Each becomes a rule file.
2. **Primary data flows** — What are the 3-5 main paths data takes through the system?
3. **External integrations** — APIs, databases, services, devices. Each integration point is a behavioral contract.
4. **Domain vocabulary** — Terms that have specific meaning in this project.
5. **Safety boundaries** — Credentials, destructive operations, irreversible actions.

## Phase 2: Tier 1 — Root CLAUDE.md

Generate a root CLAUDE.md under 150 lines containing:

```markdown
# CLAUDE.md

## Project Overview
[One paragraph: what the system does, primary workflow]

## Commands
[Cheat sheet: start, test, build, deploy — max 10 lines]

## Safety Rules
[Non-negotiable constraints: credentials, destructive ops, env files]

## Domain Navigation
[Table: "Working on X → Read Y" for each bounded context]
```

**Anti-patterns to avoid:**
- Behavioral knowledge in root CLAUDE.md (belongs in rules/)
- API reference tables (belong in domain-specific rules)
- Incident history (belongs in MEMORY.md)
- Full command documentation (belongs in commands/)

## Phase 3: Tier 2 — Behavioral Rule Files

For each bounded context, create `.claude/rules/<context>.md`:

```markdown
---
paths: ["src/auth/**/*.ts", "src/middleware/auth*.ts"]
---

## Behavioral Contract
[Dense operational semantics — what happens, in what order, with what constraints]

## Domain Terms
- **term**: Definition within this bounded context

## Flow Narrative
1. Step one
2. Step two (calls X which triggers Y)
3. ...

## Failure Modes
| Symptom | Cause | Fix |
|---------|-------|-----|
| ... | ... | ... |

## Decisions
- [NNNN] Why X was chosen over Y
```

### Path Mapping Rules

- Use glob patterns that match the actual file structure
- A file can match multiple rules — all matching rules load
- Rules without `paths:` load at session start (use sparingly)
- Prefer specific paths over broad wildcards

### Content Density Target

Each rule file should be 30-80 lines. If longer, split into sub-contexts. If shorter, it may not need its own file.

## Phase 4: Commands

Create `.claude/commands/` for recurring workflows:

**Minimum set:**
- `start.md` — Session startup (health check, orientation)
- `wrap.md` — Session close (push, update docs, write behavioral learnings)

**Common additions:**
- `test.md` — Run tests with domain-aware interpretation
- `deploy.md` — Deployment workflow
- `review.md` — Code review checklist

## Phase 5: Memory Structure

Create auto-memory directory with pre-structured topic files:

```
memory/
  MEMORY.md          # Index (loaded first 200 lines) — operational rules only
  incidents.md       # Episodic memory — what went wrong and why
  patterns.md        # Discovered behavioral patterns
```

**MEMORY.md structure:**
- Standing operational rules (max 15)
- API reference (if project has key APIs)
- Host/infra notes (if relevant)
- Links to topic files for overflow

## Phase 6: ADR Seed

Create `docs/decisions/` with 3-5 seed ADRs capturing the initial architectural choices:

```markdown
# NNNN. [Decision Title]

In the context of [situation],
facing [problem],
we decided [choice]
and neglected [alternatives],
to achieve [benefits],
accepting that [drawbacks].
```

## Phase 7: Domain Glossary

Create `DOMAIN.md` with:

1. Bounded context map (which contexts interact)
2. Glossary (20-30 terms with their context and code anchor)
3. Key domain events per context

## Phase 8: Validation

Before delivering:
- [ ] Root CLAUDE.md under 150 lines
- [ ] Each rule file has `paths:` frontmatter
- [ ] No behavioral knowledge in root CLAUDE.md
- [ ] No duplicated content across files
- [ ] Safety rules are in root CLAUDE.md (always loaded)
- [ ] Domain terms defined where they are used (in rule files), not globally
- [ ] Session protocol (start/wrap) exists
- [ ] MEMORY.md under 200 lines
- [ ] Token budget estimated: always-loaded < 1,500 tokens
