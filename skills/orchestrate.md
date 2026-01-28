# Orchestrate

> Agent crew orchestrator for product development workflows

## Usage

```
/orchestrate <goal>
/orchestrate <goal> --constraints "<constraints>"
```

## Examples

```
/orchestrate Build a SaaS invoicing app
/orchestrate Build a CLI tool for image compression --constraints "Must work offline, Python only"
```

## What This Skill Does

Orchestrates 7 specialized agents through a product development lifecycle:

1. **Market Researcher** - Analyzes market, competitors, users
2. **Product Manager** - Creates requirements and user stories
3. **Architect** - Designs system architecture
4. **Developer** - Implements the code
5. **QA Tester** - Tests and identifies issues
6. **DevOps** - Sets up CI/CD and deployment
7. **Customer Support** - Creates user documentation

## Workflow

### Phase 1: Initialization

1. Parse the goal and any constraints from the invocation
2. Check if `docs/` folder structure exists; if not, create it:
   - `docs/research/`
   - `docs/planning/`
   - `docs/design/`
   - `docs/build/`
   - `docs/test/`
   - `docs/deploy/`
   - `docs/support/`
3. Load or create `docs/orchestrator-state.json`:
   ```json
   {
     "goal": "<parsed goal>",
     "constraints": ["<parsed constraints>"],
     "currentPhase": "init",
     "completedPhases": [],
     "agents": {},
     "pendingDecisions": [],
     "grantedTools": {},
     "retryCount": {}
   }
   ```
4. Load or create `docs/context.md` with initial goal and constraints

### Phase 2: Phase Planning

Analyze the goal to determine which phases are needed. Present the plan to the user:

```
Goal: <goal>
Constraints: <constraints>

Phases to execute:
  [1] Research - Market Researcher analyzes the space
  [2] Planning - PM creates requirements
  [3] Design - Architect designs the system
  [4] Build - Developer implements
  [5] Test - QA tests the implementation
  [6] Deploy - DevOps sets up deployment

Proceed with this plan? [Y/n]
```

### Phase 3: Execute Phases

For each phase:

1. **Read agent persona** from the crew/ folder
2. **Inject context** including:
   - Full persona definition
   - Project goal and constraints
   - Relevant artifacts from previous phases
   - Specific task for this phase
3. **Spawn agent** using Task tool with `subagent_type="general-purpose"`
4. **Evaluate output** against the agent's Quality Criteria
5. **If output fails quality check:**
   - Retry once with specific feedback
   - If retry fails, escalate to user
6. **Update state files** with results
7. **Present checkpoint** at phase completion

### Checkpoint Format

```
Phase Complete: <Phase Name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Summary: <2-3 sentence summary of what was accomplished>

Artifacts Created:
  → <path to artifact 1>
  → <path to artifact 2>

[1] View summary details
[2] Open <Artifact 1>
[3] Open <Artifact 2>
[A] Approve and continue to <Next Phase>
[X] Stop here
```

Wait for user input before proceeding.

### Phase Collaboration Patterns

| Phase | Lead Agent | Supporting Agents | Pattern |
|-------|------------|-------------------|---------|
| Research | Market Researcher | - | Solo |
| Planning | Product Manager | Market Researcher | Iterative - PM can ask MR for clarification |
| Design | Architect | PM, DevOps | Iterative - Architect can consult PM on requirements, DevOps on constraints |
| Build | Developer | Architect | Sequential - Dev references Architect's designs |
| Test | QA Tester | Developer | Iterative - QA reports bugs, Dev fixes |
| Deploy | DevOps | QA | Sequential - DevOps deploys, QA validates |

### Error Handling

When an agent's output doesn't meet Quality Criteria:

**Retry prompt:**
```
Your previous output didn't meet quality criteria:
- Issue: <specific problem>
- Missing: <what was expected>

Please try again with these adjustments:
- <specific guidance>
```

**Escalation (after 1 retry):**
```
Agent Stuck: <Agent Name>
━━━━━━━━━━━━━━━━━━━━━━━━

The <Agent> agent failed after 1 retry.

Original Task: <task description>
Issue: <what went wrong>

[1] View full output
[2] Provide guidance and retry
[3] Skip this task
[4] Take over manually
[5] Assign to different agent
```

### Tool Grants

Agents have default tools. If an agent needs additional tools:

1. Agent signals in output: "TOOL_REQUEST: <tool> - <reason>"
2. Orchestrator logs the request
3. Orchestrator re-spawns agent with granted tool

Track grants in state:
```json
"grantedTools": {
  "market-researcher": ["Write"]
}
```

## Agent Spawning

When spawning an agent, construct the prompt:

```
<Read the persona file from skills/crew/<agent>.md>

You are now acting as this agent.

## Project Context
Goal: <goal>
Constraints: <constraints>

## Previous Work
<Include relevant artifacts from completed phases>

## Your Task
<Specific task for this agent in this phase>

## Output Requirements
- Save your deliverables to the appropriate docs/ folder
- Follow the Quality Criteria in your persona
- If you need tools beyond your defaults, output: TOOL_REQUEST: <tool> - <reason>
```

Use the Task tool:
```
Task(
  description="<Agent Name>: <brief task>",
  prompt=<constructed prompt>,
  subagent_type="general-purpose"
)
```

## State Management

### orchestrator-state.json

```json
{
  "goal": "Build a SaaS invoicing app",
  "constraints": ["Must support Stripe"],
  "currentPhase": "design",
  "completedPhases": ["research", "planning"],
  "agents": {
    "market-researcher": {
      "status": "complete",
      "artifacts": ["docs/research/mrd.md", "docs/research/competitive-analysis.md"]
    }
  },
  "pendingDecisions": [],
  "grantedTools": {},
  "retryCount": {}
}
```

### context.md

```markdown
# Project Context: <Goal>

## Goal
<Full goal statement>

## Constraints
- <constraint 1>
- <constraint 2>

## Key Decisions
- **<date> (<phase>)**: <decision made>

## Open Questions
- <question needing resolution>

## Cross-Agent Notes
- <Agent>: <note for other agents>
```

Update both files after each agent completes.
