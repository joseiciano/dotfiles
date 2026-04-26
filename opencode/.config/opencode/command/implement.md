---
description: Plan and implement a new task end to end, creating tests if needed. 
agent: orchestration
---

Implement $1 end to end. 

Complete the following checklist: 
- [ ] Create a plan to ensure we are able to successfully implement the details of this ticket. 
  - [ ] Use the @council to spawn 3 viewpoints on the details of the ticket to implement, the findings found by our other subagents. For each council, spawn an @oracle to analyze the details and come up with a successful plan. 
  - [ ] Detail any changes that will be needed, what files to add/change, what variables/logic will we need. Use @explorer to dig through the codebase to figure, @librarian to check on documentation. 
  - [ ] Analyze the findings from the council and use the best option as the plan 
- [ ] Based on the plan created above, implement using @fixer subagents. 
  - [ ]  For the implementation, make sure there are tests validating successful implementation. 
  - [ ] Make sure there are documentation changes included, if needed
- [ ] Cycle through revisions. Run a code review with the same considerations as the [`review`](~/.config/opencode/review.md) command. **DO NOT** address comments modifying future tickets, only handle ones modifying the ticket we are working on right now. 
  - [ ] Spawn a subagent to review the code, if there are any changes that need to be made implement
  - [ ] Spawn a new subagent after the previous set of iterations, and repeat until we get an LGTM.
- [ ] Separate implementation into concise commits 
- [ ] Prompt the user if we would like to make a pull request. 

## Implementation Diagram

```mermaid
flowchart TD
    Client[Calls /implement to start implementation process] --> Orchestration[Create implementation plan]

    Orchestration --> Council1[Use @council to generate viewpoint 1]
    Council1 --> Oracle1[Use @oracle to generate plan]
    Oracle1 <--> Explorer1[Use @explorer for codebase discovery]
    Oracle1 <--> Library1[Use @librarian for documentation discovery]
    Oracle1 --> Plan1[Generates implementation plan based on research]

    Orchestration --> Council2[Use @council to generate viewpoint 2]
    Council2 --> Oracle2[Use @oracle to generate plan]
    Oracle2 <--> Explorer2[Use @explorer for codebase discovery]
    Oracle2 <--> Library2[Use @librarian for documentation discovery]
    Oracle2 --> Plan2[Generates implementation plan based on research]

    Orchestration --> Council3[Use @council to generate viewpoint 3]
    Council3 --> Oracle3[Use @oracle to generate plan]
    Oracle3 <--> Explorer3[Use @explorer for codebase discovery]
    Oracle3 <--> Library3[Use @librarian for documentation discovery]
    Oracle3 --> Plan3[Generates implementation plan based on research]

    Plan1 --> Council[Council selects the best of the implementation plans]
    Plan2 --> Council[Council selects the best of the implementation plans]
    Plan3 --> Council[Council selects the best of the implementation plans]

    Council --> FixerBlock1[Orchestration calls @fixer subagents to implement]
    Council --> FixerBlock2[Orchestration calls @fixer subagents for tests]
    Council --> FixerBlock3[Orchestration calls @fixer subagents to implement documentation if needed]

    FixerBlock1 --> Imp[Fixers implement code changes, enters review cycle]
    FixerBlock2 --> Imp[Fixers implement code changes, enters review cycle]
    FixerBlock3 --> Imp[Fixers implement code changes, enters review cycle]
    Imp --> Reviewer[Orchestration calls review command, spawns subagent for review]
    Reviewer --> LGTMCheck["LGTM | Good, with minor nits | Needs work"]
    LGTMCheck -- "LGTM" --> Commits[Split into concise commits]
    LGTMCheck -- "Good, with minor nits" --> ReviewOracle[Calls @oracle to review the changes. implement with @fixer if needed]
    LGTMCheck -- "Needs Work" --> ReviewOracle[Calls @oracle to review the changes. implement with @fixer.]
    ReviewOracle -- "Re-reviews after implementation" --> Reviewer

    Commits --> EndUser["Ask user about creating a pull request"]
```
