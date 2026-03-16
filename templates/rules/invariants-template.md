# Invariants — Always Loaded

These rules apply to ALL tasks regardless of domain. Keep minimal — every line here consumes always-loaded context.

## Safety
1. Never commit files matching: `.env`, `credentials.*`, `*.pem`, `*.key`
2. [Project-specific destructive operation gates — confirm with user first]
3. [API-first mandates if applicable — never write to DB directly for live operations]
4. Pre-commit hook blocks [placeholder patterns / secrets] — never bypass with `--no-verify`.

## Git Protocol
- Never commit directly to main — always use feature branches + PRs.
- Commit atomically by domain (infra/backend/frontend/docs = separate commits).
- Push after milestones — never accumulate > 5 unpushed commits.

## Governance
- [Authority chain: DOC_A > DOC_B > DOC_C. When documents conflict, higher authority wins.]
- [Higher-level decisions are immutable — supersede with new entries, never edit existing ones.]

## Error Protocol
Every self-detected error produces: (1) root cause, (2) prevention artifact, (3) scope check.
An apology without all three is incomplete. Prevention artifact = new invariant rule with incident reference.

## Incident-Driven Rules
<!-- New rules are appended here as incidents occur. Format: one-line rule + incident reference. -->
<!-- Example: Never run `next build` outside `release.sh` — contaminates production `.next/`. (INC-2026-03-16) -->
