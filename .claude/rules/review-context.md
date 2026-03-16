---
paths: ["knowledge/review-checklist.md", "docs/anti-patterns/**"]
---

## Review Behavioral Contract

When reviewing an existing agent architecture:
1. Read ALL context files before scoring — don't score based on partial inventory
2. The most common diagnosis is "missing Tier 2" — but verify, don't assume
3. Score dimensions independently — a project can have excellent Tier 1 and no Tier 2
4. Anti-pattern scan must check all 12 patterns, not just obvious ones
5. Correction plan must be prioritized by impact — don't list 20 items equally weighted
6. Always offer to implement corrections, don't just diagnose

## Common Review Mistakes
- Recommending MCP servers or advanced tooling when basic rule files would suffice
- Focusing on structural improvements when behavioral knowledge is the gap
- Suggesting infrastructure (vector DBs, graph DBs) for projects under 100 files
- Not checking for duplicated content across files
- Ignoring token budget analysis
