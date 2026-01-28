# Claude Agent Crew

A portable agent crew system for Claude Code with 7 specialized agents orchestrated through a central coordinator.

## Agents

| Agent | Role |
|-------|------|
| Market Researcher | Analyzes markets, competitors, and users |
| Product Manager | Creates requirements and user stories |
| Architect | Designs system architecture |
| Developer | Implements code |
| QA Tester | Tests and identifies issues |
| DevOps | Sets up CI/CD and deployment |
| Customer Support | Creates user documentation |

## Installation

```bash
./scripts/install.sh
```

This installs skills to `~/.claude/skills/`.

## Usage

```bash
# Basic usage
/orchestrate Build a SaaS invoicing app

# With constraints
/orchestrate Build a CLI tool --constraints "Python only, must work offline"
```

## How It Works

1. You invoke `/orchestrate` with a goal
2. Orchestrator determines which phases are needed
3. For each phase, specialized agents are spawned via the Task tool
4. At phase transitions, you review and approve before continuing
5. Artifacts are saved to `docs/<phase>/` folders

## Phases

1. **Research** - Market Researcher analyzes the space
2. **Planning** - PM creates requirements
3. **Design** - Architect designs the system
4. **Build** - Developer implements
5. **Test** - QA tests the implementation
6. **Deploy** - DevOps sets up deployment

## Uninstallation

```bash
./scripts/uninstall.sh
```

## License

MIT
