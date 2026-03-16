# Research Synthesis

Three independent research streams converge on one architecture.

## The Convergence

| Stream | Diagnosis | Prescription |
|--------|-----------|-------------|
| Cognitive Architecture | Missing reflection layer — no synthesis of observations into persistent understanding | Behavioral summaries + three memory types (semantic/episodic/procedural) |
| Knowledge Engineering | Missing Tier 2 in three-tier codified context architecture | Domain glossary + Y-statement ADRs + flow narratives + failure mode tables |
| Pragmatic Tooling | Native mechanism (`.claude/rules/` with path frontmatter) exists but unused | Path-scoped behavioral rules that auto-load on file access |

## The Architecture

```
.claude/rules/                     ← Tier 2: behavioral knowledge
  <context-name>.md               # paths: ["matched/files/**/*.ext"]
  invariants.md                   # (no paths → always loaded) safety only

docs/decisions/                    ← Y-statement ADR log (append-only)
  NNNN-decision-title.md

DOMAIN.md                          ← DDD ubiquitous language glossary
```

## Rule File Template

```markdown
---
paths: ["src/domain/**/*.ts"]
---

## Behavioral Contract
[Dense operational semantics — WHAT happens, in WHAT order, with WHAT constraints]

## Domain Terms
- **term**: Definition within this bounded context

## Flow Narrative
1. Step → 2. Step → 3. Step

## Failure Modes
| Symptom | Cause | Fix |
|---------|-------|-----|

## Decisions
- [NNNN] Why X chosen over Y
```

## Token Budget Model

| Layer | Tokens | When |
|-------|--------|------|
| Root CLAUDE.md | ~400 | Always |
| MEMORY.md | ~800 | Always |
| invariants.md | ~200 | Always |
| Per-domain rule | ~200-400 | On file access |
| DOMAIN.md | ~300 | On demand |

**Net effect:** ~1,400 always + ~300 per triggered domain. Replaces 30-40K tokens of exploratory reading per session.

## Key Research Citations

- Vasilopoulos (2025). Codified Context. [arXiv:2602.20478](https://arxiv.org/abs/2602.20478)
- Park et al. (2023). Generative Agents — reflection is non-negotiable. [arXiv:2304.03442](https://arxiv.org/abs/2304.03442)
- Sumers et al. (2023). CoALA — three memory types. [arXiv:2309.02427](https://arxiv.org/abs/2309.02427)
- Miles (2025). DICE — domain objects as context units. [Engineering Agents Substack](https://engineeringagents.substack.com/p/domain-driven-agent-design)
- Evans (2003). DDD — ubiquitous language, bounded contexts.
- Zimmermann (2012). Y-statements — append-only decision records.
- LaToza & Myers (2010). Hard-to-answer questions about code.
- Robillard (2009). Five documentation factors: intent, examples, scenarios, penetrability, presentation.
- Google (2025). NL Outlines for Code. [arXiv:2408.04820](https://arxiv.org/abs/2408.04820)
