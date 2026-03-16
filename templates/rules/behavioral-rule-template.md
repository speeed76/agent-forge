---
paths: ["src/domain/**/*.ts", "src/domain/**/*.js"]
---

## Behavioral Contract
[Dense operational semantics: what happens, in what order, with what constraints.
Include edge cases, defaults, and non-obvious behaviors.
Target: 5-15 lines replacing 100-500 lines of source.]

## Domain Terms
- **term_one**: [Definition within this bounded context]
- **term_two**: [Definition — note how this term differs from its meaning in other contexts]

## Flow Narrative
1. [Entry point] → [what triggers this flow]
2. [Step] → [what happens, what it calls]
3. [Step] → [decision points, branches]
4. [Step] → [output, side effects]
5. [Terminal] → [what state the system is in after]

## Failure Modes
| Symptom | Cause | Fix |
|---------|-------|-----|
| [Observable problem] | [Root cause] | [What to check/change] |

## Decisions
- [NNNN] [Brief decision description — link to ADR]

<!-- Last reviewed: YYYY-MM-DD -->
