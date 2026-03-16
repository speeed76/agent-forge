# Knowledge Engineering for LLM Agent Context

Research stream 2 of 3. Focus: Structured knowledge representation, decision records, domain modeling, and codified context.

## The Codified Context Paper (Most Directly Relevant)

**"Codified Context: Infrastructure for AI Agents in a Complex Codebase"** (Vasilopoulos, 2025)
- [arXiv:2602.20478](https://arxiv.org/abs/2602.20478)
- 283 sessions, 108,000-line C# system, 2,801 human prompts, 16,522 autonomous turns

### Three-Tier Architecture (Empirical)

| Tier | Content | Loading | Size |
|------|---------|---------|------|
| Hot Memory | Conventions, architectural summaries, trigger tables, failure modes | Always loaded | ~660 lines |
| Specialized Agents | 19 domain-expert specs (>50% domain knowledge) | Per task | ~9,300 lines |
| Cold Memory | 34 subsystem specs, correctness pillars, symptom-cause-fix | On-demand MCP | ~16,250 lines |

**Primary failure mode:** Specification staleness.

---

## Domain-Driven Design

### Eric Evans (2003)
- *Domain-Driven Design: Tackling Complexity in the Heart of Software*
- Core concepts: ubiquitous language, bounded contexts, knowledge crunching

### Russ Miles (2025) — DICE
- "Domain Driven Agent Design" — [Engineering Agents Substack](https://engineeringagents.substack.com/p/domain-driven-agent-design)
- Domain objects as first-class context units
- Bounded contexts become context-window boundaries
- "Filter, trim, and shape the context window to what really matters — business semantics, not token bloat"

### Practical Application
- **Domain glossary** — terms with bounded context and code anchors
- **Context map** — which contexts interact and how
- **Key domain events** per context (3-5 each)
- Estimated cost: 1-2K tokens, replaces 20-30K of exploratory reading

---

## Architecture Decision Records (ADRs)

### Michael Nygard (2011) — ADR Format
- [adr.github.io](https://adr.github.io/)
- Decisions as immutable events, not living documents
- Append-only: never edit old decisions, write new ones that supersede

### Olaf Zimmermann (2012) — Y-Statements
- [Medium: Y-Statements](https://medium.com/olzzio/y-statements-10eb07b5a177)
- Format: "In the context of [X], facing [Y], we decided [Z] and neglected [alternatives], to achieve [benefits], accepting that [drawbacks]."

### MADR 4.0.0 (2024)
- [adr.github.io/madr](https://adr.github.io/madr/)
- Minimal template decomposes Y-statement into document sections

### Key Properties
- Append-only eliminates staleness
- The "why not" (rejected alternatives) is the most valuable part
- LLM agent can draft ADRs during /wrap — near-zero friction
- 20 Y-statements ≈ 2K tokens → reconstructs decision landscape

---

## NL Outlines for Code (Google, FSE 2025)

- [arXiv:2408.04820](https://arxiv.org/abs/2408.04820)
- Concise prose statements partitioning and summarizing code
- Bidirectional sync: code changes → outline updates; outline edits → code updates
- 60% "excellent," 80% "completely correct"
- `//*` or `#*` star comment syntax for distinction
- Compression: ~1 outline line per 5-10 source lines

---

## BDD / Executable Specifications

### Dan North (2006) — BDD Origin
- Given/When/Then: human-readable AND machine-executable
- Living documentation that cannot drift (it IS the test suite)

### Spec-Driven Development (Thoughtworks, 2025)
- [Thoughtworks Blog](https://www.thoughtworks.com/en-us/insights/blog/agile-engineering-practices/spec-driven-development-unpacking-2025-new-engineering-practices)
- Specs as "super-prompts" aligned with agent context windows
- Do not need full Cucumber infrastructure — Gherkin read by LLM provides 80% of value

### Cyrille Martraire (2019) — Living Documentation
- Four principles: reliable, low-effort, collaborative, insightful
- "The code tells the how, annotations tell the why"

---

## Developer Knowledge Management

### LaToza, Venolia, DeLine (2006) — Mental Models
- [ICSE 2006](https://www.microsoft.com/en-us/research/publication/maintaining-mental-models-a-study-of-developer-work-habits/)
- Developers rely on implicit knowledge, prefer code exploration over docs
- Design documents considered "inadequate" — not maintained

### Ko, Myers, Coblenz, Aung (2006) — Information Foraging
- [IEEE TSE](https://faculty.washington.edu/ajko/papers/Ko2006SeekRelateCollect.pdf)
- Three activities: searching, relating, collecting
- LLM agent performs same foraging but cannot retain results across sessions

### LaToza & Myers (2010) — Hard Questions
- [PLATEAU Workshop](https://cs.gmu.edu/~tlatoza/papers/plateau2010.pdf)
- 371 questions from 179 developers, 21 categories
- Design rationale, control/data flow, intent, dependencies, historical context

### Robillard (2009) — Five Documentation Factors
- [IEEE Software](https://dl.acm.org/doi/10.1109/MS.2009.193)
- Intent, examples, scenario matching, penetrability, presentation
- These map directly to what behavioral rule files need

### Key Insight
Senior developers retain intent, flow, and gotchas. They look up syntax and parameter names. The behavioral knowledge layer should mirror this: encode intent/flow/gotchas, let the agent look up specifics from source on demand.

---

## Knowledge Graphs for Code

### CodexGraph (Liu et al., 2025; NAACL)
- [Paper](https://aclanthology.org/2025.naacl-long.7.pdf)
- LLM agents + graph database interfaces from static analysis
- Task-agnostic schema: MODULE, CLASS, FUNCTION nodes; CONTAINS, INHERITS, USES edges

### RepoGraph (2024)
- [arXiv:2410.14684](https://arxiv.org/html/2410.14684v1)
- AST-based graph with reference/definition nodes and invoke/contain edges
- 32.8% improvement in repo-level code generation

### Practical Assessment
Medium-low implementability for solo dev. Static analysis can't capture event-driven flows. But the concept — traversable relationships between components — is what behavioral rule files approximate in prose.
