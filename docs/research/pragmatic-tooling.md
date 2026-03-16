# Pragmatic Tooling for Agent Context

Research stream 3 of 3. Focus: What tools exist today, what patterns work, what's immediately implementable.

## Claude Code Native Features

### `.claude/rules/` with Path-Scoped Frontmatter
**The single most relevant feature for agent context architecture.**

```markdown
---
paths: ["src/auth/**/*.ts", "src/middleware/auth*.ts"]
---
[behavioral knowledge loads when these files are accessed]
```

- Rules WITH `paths:` → auto-load only when matching files touched
- Rules WITHOUT `paths:` → load at launch (use sparingly)
- File access IS the task classifier — no explicit routing needed
- Content: behavioral knowledge, domain terms, failure modes

### Skills with Auto-Trigger
- `.claude/skills/` with SKILL.md containing description in frontmatter
- Claude scans descriptions at startup (~100 tokens per skill)
- Auto-loads full instructions when matching task detected
- Good for operational workflows that don't map to file paths

### `@import` Syntax
- Import critical context directly into CLAUDE.md
- Loads at session start without agent decision
- Use for invariants that must always be present

### SessionStart Hooks
- Auto-inject context via JSON `hookSpecificOutput.additionalContext`
- No user action required (unlike `/start` command)
- Use for lightweight orientation: git state, session continuity

```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "python3 scripts/session-briefing.py"
      }]
    }]
  }
}
```

### Auto-Memory
- `~/.claude/projects/<project>/memory/`
- MEMORY.md first 200 lines always loaded
- Topic files read on demand
- Agent can write to memory files during session

---

## Cross-Tool Patterns

### Cursor: `.cursor/rules/`
- Deprecated monolithic `.cursorrules` for modular `.mdc` files
- Key learning: single rules file doesn't scale past ~300 lines
- Same modular pattern as Claude Code's `.claude/rules/`

### Windsurf: Semantic Vector Indexing
- "Flow" engine: 768-dim embeddings per file/function
- Cross-session "Memories" — notes auto-inject by relevance
- Replicable via MCP servers in Claude Code

### Aider: Repository Map
- tree-sitter → symbol extraction → dependency graph → PageRank ranking
- ~1K token compact map of structurally relevant symbols
- Solves WHERE problem (already handled by CLAUDE.md) not HOW problem

---

## MCP Servers for Code Context

### codebase-memory-mcp (DeusData)
- tree-sitter knowledge graph, 14 MCP tools, sub-ms queries
- 64 language support
- 99.2% token reduction claim (3,400 vs 412,000 tokens for 5 structural queries)
- Single Go binary, no Docker, no API keys
- **Limitation:** Excellent for structural queries; does NOT encode behavioral knowledge
- Install: 30 minutes

### claude-context (Zilliz)
- Semantic code search via vector embeddings
- ~40% token reduction for equivalent retrieval
- Three packages: core indexing, VSCode extension, MCP server

### mcp-codebase-index
- Structural indexer: functions, classes, imports, dependency graphs
- 18 query tools

---

## Manus Context Engineering Principles

From [Manus blog](https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus):

1. **KV cache as primary optimization metric** — Structure prompts so stable prefixes maximize cache hits
2. **Append-only context** — Never rewrite earlier context; add new information at the end
3. **Filesystem as ultimate context** — Write state to files, read back when needed, survives compaction
4. **Deterministic briefings** — Session start should produce stable, non-randomized content
5. **Reserve tokens for reasoning** — Don't fill context with reference material; load on demand

---

## Tiered Context Loading Model

### Tier 1: Always Loaded (~1,500 tokens max)
- Root CLAUDE.md (navigation + safety)
- MEMORY.md first 200 lines (operational rules)
- Unscoped `.claude/rules/` files (invariants only)

### Tier 2: Path-Triggered (~200-400 tokens per domain)
- Scoped `.claude/rules/` files with `paths:` frontmatter
- Subdirectory CLAUDE.md files (load on directory access)

### Tier 3: Task-Triggered (on demand)
- Skills (auto-triggered by task description matching)
- Commands (user-invoked via `/command`)
- Full source files (last resort)

**The missing tier in most projects is Tier 2.**

---

## Real-World CLAUDE.md Patterns

### Community Consensus (2025-2026)
Sources: [Anthropic docs](https://code.claude.com/docs/en/memory), [HumanLayer](https://www.humanlayer.dev/blog/writing-a-good-claude-md), [Arize](https://arize.com/blog/claude-md-best-practices-learned-from-optimizing-claude-code-with-prompt-learning/)

1. Root CLAUDE.md under 200 lines
2. Progressive disclosure (tell Claude how to FIND info, not all info itself)
3. Modular rules in `.claude/rules/`
4. Path-scoped rules for domain knowledge
5. Skills for repeatable workflows
6. `@import` for critical always-needed context
7. Auto-memory for agent-discovered knowledge

### Anti-Patterns
- Monolithic CLAUDE.md over 500 lines
- Duplicated content across CLAUDE.md and MEMORY.md
- Behavioral knowledge only in source code comments
- Over-engineered session protocols (20+ turns before work)
