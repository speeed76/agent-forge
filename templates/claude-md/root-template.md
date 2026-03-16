# CLAUDE.md — [Project Name]

## Project Overview
[One paragraph: what the system does, primary workflow, tech stack]

## Commands

```bash
# Start/stop
[primary start command]
[primary stop command]

# Test
[test command]

# Build
[build command]
```

## Safety Rules
1. [Credential/env file protection — never commit or expose]
2. [Destructive operation gates — confirm with user first]
3. [API-first mandates if applicable]
4. Pre-commit hook blocks [placeholder patterns / secrets] — never bypass with `--no-verify`.
5. [Governance authority chain: DOC_A > DOC_B > DOC_C — higher wins conflicts]

## Domain Navigation

Behavioral rules in `.claude/rules/` auto-load when matching files are accessed.

| Domain | Entry point |
|--------|-------------|
| [Domain A] | [`.claude/rules/domain-a.md`] or [`subdir/CLAUDE.md`] |
| [Domain B] | [`.claude/rules/domain-b.md`] |
| [Domain C] | [`.claude/rules/domain-c.md`] |
| [Governance] | [`MISSION.md`] → [`STRATEGY.md`] → [`ROADMAP.md`] |
| [Reference] | [`TECH_DEBT.md`], [`TROUBLESHOOTING.md`] |

## Git Workflow — Agent-Owned (MANDATORY)

**Git is the agent's sole responsibility.** The operator does not run git commands, choose branches, or make commits.

| Branch | Purpose | Who creates |
|--------|---------|-------------|
| `main` | Stable, deployable. PRs target here. | Agent merges via PR |
| `feat/<name>` | Feature work. One active at a time. | Agent creates at `/start` if needed |

**Never commit directly to `main`.** Pre-commit hook enforces this.

**During work:** commit atomically by domain. Push after milestones. Never accumulate > 5 unpushed commits.

## Sprint Discipline Guard (MANDATORY)

When a sprint is active, classify every request: **ON-PATH/PROCESS** → execute. **ADJACENT/DEVIATION/SCOPE CREEP** → refuse (`sudo:` prefix overrides). **PROCESS VIOLATION** → hard block, no override. Full rules: [`SPRINT_WORKFLOW.md §9`] or [equivalent protocol file].

## Host Environment
[Node/Python version, key ports, database locations, active services]

## Session Health Check
Slash commands: `/start`, `/res`, `/wrap`. [Additional project-specific commands.]
