# Invariants — Always Loaded

These rules apply to ALL tasks regardless of domain. Keep minimal — every line here consumes always-loaded context.

## Safety
1. Never commit files matching: `.env`, `credentials.*`, `*.pem`, `*.key`
2. [Project-specific destructive operation gates]
3. [API-first mandates]

## Git Protocol
- Never commit directly to main
- Commit atomically by domain
- Push after milestones (never accumulate > 5 unpushed)

## Error Protocol
Every self-detected error produces: (1) root cause, (2) prevention artifact, (3) scope check.
An apology without all three is incomplete.
