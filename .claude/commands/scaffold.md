# /scaffold — Build Agent Architecture for a New Project

You are Agent Forge. The operator will provide a project specification (description, tech stack, key workflows). Your job is to generate a complete agent architecture that makes the project's agent competent from session one.

## Input
The operator provides one of:
- A project description (verbal or document)
- A README.md or existing codebase to analyze
- A SPEC.md or requirements document

## Process

### Step 1: Domain Analysis
Read the input and extract:
1. **Bounded contexts** — 3-7 distinct areas (each becomes a rule file)
2. **Primary data flows** — 3-5 main data paths
3. **External integrations** — APIs, databases, services
4. **Domain vocabulary** — terms with project-specific meaning
5. **Safety boundaries** — credentials, destructive ops, env files
6. **Tech stack** — language, framework, runtime, database

Present this analysis to the operator for confirmation before proceeding.

### Step 2: Generate Architecture

Using the confirmed analysis, generate these files:

**Always:**
- `CLAUDE.md` — Root file (< 150 lines). Use `templates/claude-md/root-template.md`.
- `.claude/rules/invariants.md` — Safety rules (no paths, always loaded). Use `templates/rules/invariants-template.md`.
- `.claude/commands/start.md` — Session start. Use `templates/commands/start-template.md`.
- `.claude/commands/wrap.md` — Session wrap. Use `templates/commands/wrap-template.md`.

**Per bounded context:**
- `.claude/rules/<context>.md` — Behavioral rule file with `paths:` frontmatter. Use `templates/rules/behavioral-rule-template.md`.

**Domain layer:**
- `DOMAIN.md` — Ubiquitous language glossary + context map
- `docs/decisions/0001-initial-architecture.md` — Seed ADR

**Memory:**
- Structure for auto-memory directory with topic files

### Step 3: Content Generation

For each behavioral rule file:
1. If codebase exists: READ the source files in this context
2. Extract behavioral contracts, domain terms, flow narratives
3. Identify failure modes from code patterns (error handling, edge cases)
4. Write the rule file at appropriate density (30-80 lines)

For DOMAIN.md:
1. List all bounded contexts with 1-line descriptions
2. Draw the context map (which calls which)
3. Write glossary entries for all domain terms
4. List 3-5 key domain events per context

### Step 4: Validation

Run the review checklist (`knowledge/review-checklist.md`) against the generated architecture:
- [ ] Root CLAUDE.md < 150 lines
- [ ] Each rule file has paths: frontmatter
- [ ] No behavioral knowledge in root CLAUDE.md
- [ ] No duplicated content
- [ ] Safety rules in always-loaded tier
- [ ] Token budget: always-loaded < 1,500 tokens
- [ ] Session protocols exist (start + wrap)

### Step 5: Delivery

Present the complete architecture to the operator:
1. File tree showing all generated files
2. Token budget breakdown (always-loaded, per-domain, total)
3. Bounded context map visualization
4. Any gaps identified (areas where behavioral knowledge needs operator input)

## Output Format

Generate files directly in the target project directory. If the project is an existing codebase, merge carefully — never overwrite existing CLAUDE.md without confirmation.

## References
- `knowledge/scaffolding-protocol.md` — Full protocol details
- `docs/patterns/` — All architectural patterns
- `templates/` — All file templates
- `docs/anti-patterns/common-failures.md` — What to avoid
