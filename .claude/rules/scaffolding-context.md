---
paths: ["templates/**", "knowledge/scaffolding-protocol.md"]
---

## Scaffolding Behavioral Contract

When scaffolding a new project:
1. ALWAYS present domain analysis for operator confirmation before generating files
2. Use templates as starting points — customize for the specific project
3. Read existing source code if available to extract behavioral knowledge
4. Never generate placeholder content ("TODO: fill in later") — either write real content or omit the section
5. Path patterns in rule files must match the actual file structure of the target project
6. Test the token budget: always-loaded < 1,500, per-domain 200-400

## Common Mistakes
- Generating rule files without reading the source code they describe
- Using generic paths that don't match the project's directory structure
- Putting behavioral knowledge in root CLAUDE.md instead of path-scoped rules
- Forgetting to generate DOMAIN.md glossary
- Skipping the seed ADR
