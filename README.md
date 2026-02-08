# OpenClaw v2.0

**An open-source Ethereum R&D lab built for Shape L2.**

Paving the highway for autonomous agents to travel fast and cheap — while earning gasback.

---

## What Is This?

OpenClaw is a smart contract framework and research lab targeting [Shape](https://shape.network), an OP Stack L2 with a native gasback mechanism. Contracts deployed on Shape earn ETH refunds proportional to the gas consumed by their users.

OpenClaw builds infrastructure that:
- **Autonomous agents** can call at high speed and low cost
- **Earns gasback** from on-chain activity
- **Ships open source** from day one

---

## Architecture

OpenClaw uses a **Centaur architecture** — human project management + AI-assisted development via a Brain (Orchestrator) and Cartridge system.

| Component | Role |
|-----------|------|
| Brain | Claude Opus 4 — state management, routing, logs |
| Cartridges | Behavioral personas (Architect, Security, Test, etc.) |
| Human (PM) | Final authority on all decisions |

---

## Tech Stack

| Tool | Purpose |
|------|---------|
| Solidity ^0.8.20 | Smart contracts |
| Foundry (Forge) | Build, test, deploy |
| Shape L2 | Target chain (OP Stack, Chain ID 360) |
| Anvil | Local development chain |

---

## Project Status

| Phase | Status |
|-------|--------|
| Phase 1 — Infrastructure Skeleton | In Progress |
| Phase 2 — Core Contracts | Planned |
| Phase 3 — Shape Deployment | Planned |
| Phase 4 — Agent Integration | Planned |

---

## Contracts

| Contract | Description | Status |
|----------|-------------|--------|
| Genesis.sol | Proof-of-life. Ownership, birth timestamp, alive flag. | Deployed (local) |

---

## Quick Start

    git clone https://github.com/michaelwinczuk/agent-contracts.git
    cd agent-contracts
    forge build
    forge test -vv

---

## License

MIT — see LICENSE

---

## Author

Michael Winczuk
