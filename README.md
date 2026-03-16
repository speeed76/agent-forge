# Agent Forge

A meta-agent that builds, reviews, and optimizes LLM code agents.

Agent Forge does not build software — it builds the agents that build software.

## Three Capabilities

### `/scaffold` — Build Agent for New Project
Given a project specification, generates a complete agent architecture: CLAUDE.md, behavioral rule files, commands, memory structure, domain glossary, session protocols.

### `/review` — Audit Existing Agent
Analyzes a project's agent context architecture. Diagnoses knowledge gaps, anti-patterns, token waste. Produces a prioritized correction plan.

### `/train` — Operator Skill Development
Coaches the human operator on agent interaction patterns: domain knowledge transfer, feedback loops, session discipline, delegation ladder.

## Core Architecture

Built on three-tier knowledge model:

| Tier | Content | Loading |
|------|---------|---------|
| 1 — Structural | Where things are | Always loaded |
| 2 — Behavioral | How things work | Path-triggered |
| 3 — Source | Authoritative code | On demand |

Most projects only have Tier 1. Agent Forge builds Tier 2.

## Research Foundation

Based on synthesis of three research streams:
- **Cognitive Architecture** — CoALA, Generative Agents reflection, MemGPT, A-MEM
- **Knowledge Engineering** — Codified Context, DDD, ADRs, NL Outlines
- **Pragmatic Tooling** — Claude Code features, Manus context engineering, cross-tool patterns

Full research in `docs/research/`.

## Usage

Open this directory in Claude Code:
```bash
cd agent-forge
claude
```

Then use commands:
- `/scaffold` — with a project description or path
- `/review` — with a project path
- `/train` — for operator coaching

## Repository Structure

```
CLAUDE.md                          # Meta-agent instructions
.claude/
  rules/                           # Behavioral knowledge for meta-agent itself
  commands/                        # /scaffold, /review, /train
docs/
  research/                        # Three research streams + synthesis
  patterns/                        # Tiered context, behavioral rules, sessions, memory
  anti-patterns/                   # 12 common failures
  operator-guide/                  # Interaction patterns, feedback loops
knowledge/
  scaffolding-protocol.md          # How to build an agent
  review-checklist.md              # How to audit an agent
  incidents.md                     # Generalized incident patterns
  operational-rules.md             # Universal rules from real operation
  owner-feedback-patterns.md       # What operator feedback reveals
templates/
  claude-md/                       # CLAUDE.md templates
  rules/                           # Rule file templates
  commands/                        # Command templates
  memory/                          # Memory structure templates
```
