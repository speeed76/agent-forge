# Pattern: Memory Architecture

## The Three Memory Types

Based on CoALA (Sumers et al. 2023) and validated through operational experience.

### Semantic Memory — Facts & Concepts
**What:** Context-independent knowledge. True regardless of when you ask.
**Examples:** "Port 3003 = offer-server." "Rate Card v7: F2F Standard = 20/h." "SQLite DB at data/offers.db."
**Storage:** CLAUDE.md, behavioral rule files, DOMAIN.md glossary
**Loading:** Tier 1 (always) for safety rules; Tier 2 (path-triggered) for domain facts

### Episodic Memory — Experiences & Incidents
**What:** Time-stamped records of specific events. Context-dependent.
**Examples:** "2026-03-07: ABI mismatch after power cut — NVM node started service but native module was built for Homebrew node." "2026-02-27: Missed auto-accept because engine was disabled when rules were set."
**Storage:** MEMORY.md incident section, `knowledge/incidents.md`
**Loading:** Tier 1 (critical incidents in MEMORY.md); Tier 3 (full incident history on demand)

### Procedural Memory — Workflows & Skills
**What:** How to perform tasks. Executable knowledge.
**Examples:** "To check engine state: GET /api/decision/settings. If enabled: false, flag before rule setup." "To deploy: commit by domain → push → PR."
**Storage:** `.claude/commands/`, session protocols, standing rules in MEMORY.md
**Loading:** Tier 3 (invoked by user or auto-triggered by task)

## Memory Structure

```
project/
  CLAUDE.md                    # Semantic: structural facts (always loaded)
  DOMAIN.md                    # Semantic: domain glossary (on demand)
  .claude/
    rules/
      <domain>.md              # Semantic: behavioral knowledge (path-triggered)
      invariants.md            # Semantic: safety rules (always loaded)
    commands/
      start.md                 # Procedural: session start workflow
      wrap.md                  # Procedural: session wrap workflow
  docs/
    decisions/                 # Episodic + Semantic: decision records (append-only)
  memory/
    MEMORY.md                  # Mixed: operational rules + incident index (always loaded, 200 lines)
    incidents.md               # Episodic: full incident records (on demand)
    patterns.md                # Semantic: discovered patterns (on demand)
```

## Maintenance Model

### Who Maintains What
| Memory Type | Creator | Updater | Reviewer |
|-------------|---------|---------|----------|
| Semantic (rule files) | Agent + Operator | Agent (during /wrap) | Operator (periodically) |
| Episodic (incidents) | Agent (when error detected) | Never (append-only) | Operator (for accuracy) |
| Procedural (commands) | Agent or Operator | Agent (when workflow changes) | Operator (for correctness) |

### Staleness Prevention
- ADRs: append-only (never edit, only supersede) — staleness impossible by design
- Rule files: compare source file modification dates against rule file dates
- Commands: validate by running periodically
- MEMORY.md: agent updates during /wrap; operator trims periodically

### Memory Budget
- MEMORY.md: max 200 lines (beyond this, move to topic files)
- Rule files: 30-80 lines each
- Total always-loaded: < 1,500 tokens
- Topic files: unlimited (loaded on demand)
