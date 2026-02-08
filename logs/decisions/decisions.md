# OpenClaw v2.0 — Decision Log

## DECISION-001
- **Date:** 2025-06-27
- **Decision:** Initialize workspace with 24-directory structure per Constitution Section 9.1
- **Rationale:** Constitution compliance. No deviations.
- **Status:** IMPLEMENTED

## DECISION-002
- **Date:** 2025-06-27
- **Decision:** Genesis.sol uses minimal design — Ownable, immutable BIRTH_TIMESTAMP, isAlive(), GenesisDeployed event
- **Rationale:** Constitution mandates starting minimal. External AI (Gemini) suggested upgradeable proxies and registry patterns — rejected as scope creep for Phase 1.
- **Status:** IMPLEMENTED

**Status Update:** DECISION-007 — IMPLEMENTED (2025-06-27). Import path fixed to `../contracts/src/Genesis.sol`. Deployment successful.

---

### DECISION-009
**Date:** 2025-06-27
**Context:** Mission Order 004 — Operation Clean Slate
**Decision:** Fixed unaliased-plain-import lint warnings in DeployGenesis.s.sol by converting to named imports (`{Script, console}`, `{Genesis}`). Ran forge clean to purge stale artifacts. Confirmed zero warnings on rebuild and 5/5 tests pass.
**Status:** IMPLEMENTED
