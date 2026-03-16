# Agent Architecture Review Checklist

When reviewing an existing project's agent setup, work through each section. Score each dimension and produce a correction plan.

## 1. Context Inventory

Read all agent context files and inventory them:

```
[ ] Root CLAUDE.md — lines, content categories
[ ] Subdirectory CLAUDE.md files — count, paths, content
[ ] .claude/rules/ — exists? files? paths: frontmatter?
[ ] .claude/commands/ — count, what workflows
[ ] MEMORY.md / auto-memory — size, structure
[ ] Any other context files (SESSION.md, DOMAIN.md, etc.)
```

### Metrics

| Metric | Healthy | Warning | Critical |
|--------|---------|---------|----------|
| Root CLAUDE.md lines | < 150 | 150-300 | > 300 |
| Always-loaded tokens | < 1,500 | 1,500-3,000 | > 3,000 |
| Behavioral rule files | 4-8 per project | 1-3 | 0 |
| Path-scoped rules | > 80% of rules | 50-80% | < 50% |
| Commands/skills | 3-10 | 1-2 or > 15 | 0 |

## 2. Three-Tier Coverage

For each major subsystem, assess:

| Subsystem | Tier 1 (WHERE) | Tier 2 (HOW) | Tier 3 (Source) |
|-----------|---------------|--------------|-----------------|
| [name] | Present/Missing | Present/Missing | Exists by definition |

**The diagnosis is always the same:** Tier 2 is missing. If Tier 2 exists for all subsystems, check its quality (see Section 3).

## 3. Behavioral Knowledge Quality

For each rule file or behavioral document, assess:

### Completeness Check
- [ ] Behavioral contract — what happens, in what order?
- [ ] Domain terms — glossary for this bounded context?
- [ ] Flow narrative — primary data path described?
- [ ] Failure modes — known gotchas documented?
- [ ] Decision rationale — WHY, not just WHAT?

### Density Check
Count the ratio: lines of behavioral summary / lines of source code it covers.
- Good: 1:10 to 1:25 (20-50 lines summary for 500 lines source)
- Bad: 1:1 to 1:5 (basically restating the code)
- Missing: 0:N (no summary at all)

### Freshness Check
Compare rule file last-modified against source file last-modified.
- If source changed after rule: rule may be stale
- If rule never existed: behavioral knowledge never captured

## 4. Memory Architecture

### Semantic Memory (Facts)
- [ ] Domain glossary exists?
- [ ] API reference accessible?
- [ ] Infrastructure notes current?

### Episodic Memory (Incidents)
- [ ] Past incidents recorded with structured format?
- [ ] Root cause and prevention documented?
- [ ] Incident → rule file link exists?

### Procedural Memory (Workflows)
- [ ] Session start protocol?
- [ ] Session wrap protocol?
- [ ] Domain-specific workflows as commands?
- [ ] Git protocol defined?

## 5. Token Budget Analysis

Calculate:
1. **Always-loaded** — Root CLAUDE.md + MEMORY.md + unscoped rules
2. **Per-task** — How many tokens load for a typical task?
3. **Worst case** — All rules triggered simultaneously
4. **Waste** — Content in always-loaded that belongs in per-task

### Common Token Waste Patterns
- API reference tables in root CLAUDE.md (should be in domain rule)
- Full incident history in MEMORY.md (should be in topic files)
- Behavioral knowledge in always-loaded (should be path-scoped)
- Duplicated content across multiple files

## 6. Anti-Pattern Scan

Check for each anti-pattern (see `docs/anti-patterns/common-failures.md`):

- [ ] Monolithic CLAUDE.md (> 300 lines)
- [ ] Behavioral knowledge only in source code comments
- [ ] No path-scoped rules (`.claude/rules/` missing or empty)
- [ ] Session startup > 15 turns before productive work
- [ ] Agent re-reads same source files every session
- [ ] Operator frequently says "you should have known that"
- [ ] No session wrap protocol (knowledge evaporates)
- [ ] No incident records (same mistakes repeated)
- [ ] Direct DB/API writes without API-first rule
- [ ] Hardcoded project-specific knowledge in generic commands

## 7. Correction Plan Template

```markdown
## Agent Architecture Correction Plan

### Project: [name]
### Review Date: [date]
### Overall Score: [A/B/C/D/F]

### Critical Fixes (do first)
1. [Fix with estimated effort]

### High Priority
1. [Fix]

### Medium Priority
1. [Fix]

### Low Priority / Nice-to-Have
1. [Fix]

### Token Budget Before/After
| | Before | After |
|---|--------|-------|
| Always-loaded | X tokens | Y tokens |
| Per-task average | X tokens | Y tokens |
| Source re-reading waste | X tokens/session | Y tokens/session |
```
