# Agent Crew System Design

## Overview

A portable agent crew system for Claude Code that orchestrates 7 specialized agents through a product development lifecycle. The system uses a hybrid architecture: skills define agent personas, while the Task tool executes them.

### Core Components

1. **Orchestrator Skill** (`/orchestrate`) - The coordinator that interprets goals, manages phases, delegates to agents, and presents checkpoints
2. **7 Agent Persona Skills** - Detailed definitions for each role (not invoked directly, read by Orchestrator)
3. **Phase-based Artifact Folders** - Structured output in `docs/research/`, `docs/planning/`, `docs/design/`, `docs/build/`, `docs/test/`, `docs/deploy/`
4. **Dual Context System** - `docs/orchestrator-state.json` for machine state + `docs/context.md` for human-readable decisions

### Invocation

```
/orchestrate Build a SaaS invoicing app

/orchestrate Build a CLI tool for image compression --constraints "Must work offline, Python only"
```

### Workflow

1. User invokes `/orchestrate` with a goal (+ optional constraints)
2. Orchestrator determines which phases are needed
3. Within each phase, Orchestrator spawns agents via Task tool, deciding collaboration pattern (sequential, iterative, or parallel)
4. At phase transitions, Orchestrator pauses with an interactive checkpoint
5. User reviews, drills into details if needed, then approves to continue

---

## Agent Personas

### Persona Structure

Each agent skill file defines:

- **Role** - One-line identity statement
- **Expertise Areas** - Specific domains of knowledge
- **Core Responsibilities** - Fixed tasks this agent always handles
- **Communication Style** - How the agent expresses itself
- **Expected Inputs** - What context/artifacts it needs
- **Outputs Produced** - Deliverables and their format
- **Quality Criteria** - What "good" looks like for this agent
- **What to Avoid** - Anti-patterns and common mistakes
- **Default Tools** - Role-appropriate tool access

### The Seven Agents

| Agent | Key Deliverables | Default Tools |
|-------|------------------|---------------|
| **Market Researcher** | MRD, Competitive Analysis, User Personas | WebSearch, WebFetch, Read |
| **Product Manager** | PRD, User Stories, Prioritized Backlog | Read, Write, AskUserQuestion |
| **Architect** | Architecture Doc, Data Models, API Contracts | Read, Write, Glob, Grep |
| **Developer** | Implementation Code, Unit Tests | Read, Write, Edit, Bash, Glob, Grep |
| **QA Tester** | Test Plan, Test Cases, Bug Reports | Read, Bash, Glob, Grep |
| **DevOps** | CI/CD Config, Deployment Scripts, Infra Docs | Read, Write, Edit, Bash |
| **Customer Support** | User Docs, FAQs, Troubleshooting Guides | Read, Write, WebSearch |

### Tool Escalation

When an agent needs tools outside their default set, they signal the Orchestrator. Orchestrator can grant temporary access (e.g., giving Market Researcher file write access to save research notes).

---

## Phases and Checkpoints

### Six Phases

| Phase | Agents Involved | Collaboration Pattern | Primary Deliverables |
|-------|-----------------|----------------------|---------------------|
| **Research** | Market Researcher | Solo | MRD, Competitive Analysis, User Personas |
| **Planning** | PM (lead), Market Researcher (input) | Iterative | PRD, User Stories, Backlog |
| **Design** | Architect (lead), PM (input), DevOps (input) | Iterative | Architecture Doc, API Contracts, Data Models |
| **Build** | Developer (lead), Architect (reference) | Sequential | Implementation Code |
| **Test** | QA Tester (lead), Developer (fixes) | Iterative | Test Plan, Bug Reports, Fixed Code |
| **Deploy** | DevOps (lead), QA (validation) | Sequential | CI/CD, Deployment Scripts, Infra |

### Post-Deploy (Optional)

Customer Support agent can be triggered after deployment to generate user-facing documentation based on all prior artifacts.

### Checkpoint Interaction

At each phase transition, Orchestrator presents:

```
Phase Complete: Research
━━━━━━━━━━━━━━━━━━━━━━━━

Summary: Analyzed 5 competitors, identified 3 user personas,
         found gap in market for offline-first solution.

Artifacts Created:
  → docs/research/mrd.md
  → docs/research/competitive-analysis.md
  → docs/research/personas.md

[1] View summary details
[2] Open MRD
[3] Open Competitive Analysis
[4] Open Personas
[5] Ask a question about this phase
[A] Approve and continue to Planning
[X] Stop here
```

---

## Context Management

### Dual-File System

The Orchestrator maintains two files to track state and decisions:

#### `docs/orchestrator-state.json` - Machine-readable state

```json
{
  "goal": "Build a SaaS invoicing app",
  "constraints": ["Must support Stripe", "Multi-tenant"],
  "currentPhase": "design",
  "completedPhases": ["research", "planning"],
  "agents": {
    "market-researcher": { "status": "complete", "artifacts": ["docs/research/mrd.md"] },
    "pm": { "status": "complete", "artifacts": ["docs/planning/prd.md"] },
    "architect": { "status": "in-progress", "artifacts": [] }
  },
  "pendingDecisions": [],
  "grantedTools": {},
  "retryCount": {}
}
```

#### `docs/context.md` - Human-readable decisions log

```markdown
# Project Context: SaaS Invoicing App

## Goal
Build a SaaS invoicing app with Stripe support, multi-tenant architecture.

## Key Decisions
- **2024-01-27 (Research)**: Target SMB market, not enterprise
- **2024-01-27 (Planning)**: MVP scope: invoices, payments, basic reporting
- **2024-01-27 (Design)**: PostgreSQL + row-level security for multi-tenancy

## Open Questions
- Pricing model: per-seat vs per-invoice?

## Cross-Agent Notes
- PM flagged: competitor X has poor mobile experience - opportunity
- Architect notes: consider event sourcing for audit trail
```

### How Context Flows

1. Orchestrator reads both files at startup
2. Before spawning an agent, Orchestrator injects relevant context into the prompt
3. After agent completes, Orchestrator updates both files with results and decisions

---

## Error Handling

### Retry Logic

When an agent produces poor output or gets stuck:

1. **Detection** - Orchestrator evaluates output against the agent's Quality Criteria
2. **First Retry** - Orchestrator provides specific feedback and asks agent to try again
3. **Escalation** - If retry fails, Orchestrator pauses and escalates to user

### Retry Prompt Pattern

```
Your previous output didn't meet quality criteria:
- Issue: [specific problem identified]
- Missing: [what was expected but not delivered]

Please try again with these adjustments:
- [specific guidance]
```

### Escalation Prompt

```
Agent Stuck: Architect
━━━━━━━━━━━━━━━━━━━━━━

The Architect agent failed after 1 retry.

Original Task: Design multi-tenant data model
Issue: Proposed schema doesn't isolate tenant data properly

Agent's Output:
  → [summary of what was produced]

[1] View full output
[2] Provide guidance and retry
[3] Skip this task
[4] Take over manually
[5] Assign to different agent
```

### State Tracking

Retry counts are tracked in `orchestrator-state.json` to prevent infinite loops:

```json
"retryCount": {
  "architect:data-model": 1
}
```

Maximum retries: 1 (configurable)

---

## File Structure

### Skills Location (Portable, in global config)

```
~/.claude/skills/
├── orchestrate.md              # Main orchestrator skill
└── crew/
    ├── market-researcher.md    # Agent persona definitions
    ├── product-manager.md
    ├── architect.md
    ├── developer.md
    ├── qa-tester.md
    ├── devops.md
    └── customer-support.md
```

### Project Artifacts (Created per-project)

```
your-project/
├── docs/
│   ├── orchestrator-state.json    # Machine state
│   ├── context.md                  # Human-readable log
│   ├── research/
│   │   ├── mrd.md
│   │   ├── competitive-analysis.md
│   │   └── personas.md
│   ├── planning/
│   │   ├── prd.md
│   │   ├── user-stories.md
│   │   └── backlog.md
│   ├── design/
│   │   ├── architecture.md
│   │   ├── data-models.md
│   │   └── api-contracts.md
│   ├── build/
│   │   └── (code lives in src/, tracked here)
│   ├── test/
│   │   ├── test-plan.md
│   │   └── bug-reports.md
│   └── deploy/
│       ├── ci-cd.md
│       └── infrastructure.md
└── src/
    └── (implementation code)
```

### Initialization

First time `/orchestrate` runs in a project, it creates the `docs/` folder structure and initializes empty state files.

---

## Orchestrator Implementation

### Execution Flow

#### 1. Initialization

- Parse goal and constraints from invocation
- Check if docs/ exists; if not, create folder structure
- Load orchestrator-state.json (or create if new project)
- Load context.md for decision history

#### 2. Phase Planning

- Analyze goal to determine which phases are needed
- Not every project needs all 6 phases (e.g., a docs-only task skips Build/Test/Deploy)
- Present phase plan to user for confirmation

#### 3. Agent Spawning (via Task Tool)

- Read the relevant persona skill file (e.g., crew/architect.md)
- Construct a prompt that includes:
  - Full persona definition
  - Relevant context from context.md
  - Specific task to accomplish
  - Artifacts from previous agents
  - Granted tools (if any beyond defaults)
- Spawn agent using Task tool with subagent_type="general-purpose"

#### 4. Output Processing

- Receive agent output
- Evaluate against Quality Criteria from persona
- If pass: update state, save artifacts, log decisions
- If fail: retry once with feedback, then escalate

#### 5. Checkpoint Presentation

- Summarize phase results
- Present interactive options
- Wait for user input
- Continue or stop based on response

---

## Limitations and Considerations

### Known Constraints

| Constraint | Impact | Mitigation |
|------------|--------|------------|
| Task tool agents can't spawn sub-agents | No nested delegation (Developer can't spawn a "Code Reviewer") | Orchestrator handles all delegation; agents request via output |
| Each agent starts fresh | No memory between spawns of same agent | Context file provides continuity; Orchestrator injects relevant history |
| Token limits per agent | Large codebases may exceed context | Orchestrator provides focused context; agents can request more via Glob/Grep |
| No true parallelism | Task tool runs sequentially in practice | Acceptable for v1; can optimize later if needed |

### What This System Won't Do (v1)

- Real-time collaboration between agents (no live chat between agents)
- Persistent agent memory across projects
- Custom agent creation on the fly (predefined 7 only)
- Multi-project orchestration in a single session

### Future Enhancements (Out of Scope for Now)

- Agent performance metrics and tuning
- Custom agent templates
- Project-specific persona overrides
- Integration with external tools (Jira, Linear, etc.)

### Security Considerations

- Agents only get role-appropriate tools by default
- Tool grants are logged in state file
- User approval required at every phase transition

---

## Summary

| Component | Description |
|-----------|-------------|
| **Orchestrator** | Invoked via `/orchestrate <goal>`, manages workflow |
| **Agents** | Market Researcher, PM, Architect, Developer, QA, DevOps, Customer Support |
| **Phases** | Research → Planning → Design → Build → Test → Deploy |
| **Architecture** | Skills define personas, Task tool executes them |
| **Context** | JSON state + Markdown decisions log |
| **Checkpoints** | Phase transitions with interactive drill-down options |
| **Error Handling** | Retry once, then escalate to human |
| **Tool Access** | Role-appropriate defaults, Orchestrator can grant more |
