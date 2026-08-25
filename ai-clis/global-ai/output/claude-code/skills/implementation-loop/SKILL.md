---
name: implementation-loop
description: End-to-end workflow for implementing a given ticket or well-defined multi-step plan. Should be used when given a plan or spec sheet to implement. 
---

This skill covers the end-to-end workflow for implementing a given plan. It should only be used when it's a multi-step plan that requires multiple steps to implement. 

## Arguments Received

Arguments Received: `$ARGUMENTS`

Parse the following from `$ARGUMENTS`:

- `$SPEC_PLAN`: Implementation plan we are to work on. 
- `$DESCRIPTION`: Details about implementation (**optional**). If `$SPEC_PLAN` is not provided, information should be here. 

## Task

### Pre-requisite, Generate Spec_Plan if nonexistant

**SKIP THIS STEP IF WE ARE ALREADY GIVEN AN IMPLEMENTATION PLAN**

If we are not given an implementation plan, we have to create one first. 

Spawn 1 @council subagent to handle generating the implementation plan. Use this prompt **exactly**:

```markdown
You are a council needed to draft up an implementation plan for the given scenario: $DESCRIPTION. 

View it from different viewpoints using multiple @councillor subagents, scour the codebase and any documentation for relevant information. 

## Task

1. Spawn 3 @councillor subagents. Give them the following prompt:
```
```
```


Implement `$SPEC_PLAN` end to end. 


1. Analyze if we are given a detailed plan. If `$SPEC_PLAN` is a full implementation plan, **SKIP TO STEP 2**. Otherwise,

Complete the following checklist: 
- [ ] Analyze the difficulty and clarity of the task we are given, 
  - [ ] If we are given a detailed plan, focus on implementing it and go to the next major bullet point. 
  - [ ] If we are not, generate a plan first to understand implementation details
    - [ ] If the task is simple, spawn an @oracle subagent to generate a plan on what to implement 
    - [ ] If the task is not simple, spawn 3 @council subagents to get viewpoints on what to implement, then use @oracle to generate the plan
  - [ ] Detail any changes that will be needed, what files to add/change, what variables/logic will we need. Use @explorer to dig through the codebase to figure, @librarian to check on documentation. 
- [ ] Based on the plan created above, implement using @fixer subagents. 
  - [ ]  For the implementation, make sure there are tests validating successful implementation. 
  - [ ] Make sure there are documentation changes included, if needed
- [ ] Cycle through revisions. **DO NOT** address comments modifying future tickets, only handle ones modifying the ticket we are working on right now. 
For each cycle, do the following:
  - [ ] Spawn a new @reviewer-orchestrator and do a code review using the  [`review`](~/dotfiles/opencode/.config/opencode/skills/review/SKILL.md) skill.   
  - [ ] Analyze if review status was "LGTM" or "LGTM with Comments". If so, stop here. 
  - [ ] If status was not "LGTM" or "LGTM with Comments", review changes needed and implement using @fixer
  - [ ] Spawn a new @reviewer-orchestrator subagent after the previous set of iterations, and repeat.
- [ ] Separate implementation into concise commits 
- [ ] Prompt the user if we would like to make a pull request. 

**Note**: For the review cycles you **must** always use the `review` skill.

## Implementation Diagram

```mermaid
flowchart TD
    Client[Client calls /implement to start implementation process] --> Orchestration[Create implementation plan]

    Orchestration --> Planner[Use @oracle to analyze if plan exists]
    Planner -- "Plan Exists" --> Plan[Spawn @oracle to implement plan]

    Planner -- "No plan - simple or concise task" --> OraclePlanner[spawn @oracle to generate plan]
    OraclePlanner <--> ExplorerPlanner[Use @explorer for codebase discovery]
    OraclePlanner <--> LibraryPlanner[Use @librarian for documentation discovery]
    OraclePlanner -- Using data from explorer and librarian, generate plan --> Plan[spawn @oracle to implement plan]
    
    Planner -- "No plan - large, complicated task" --> CouncilCall[Call the council to generate a detailed plan]
    CouncilCall --> Council1[Use @council to generate viewpoint 1]
    Council1 --> Oracle1[Use @oracle to generate plan]
    Oracle1 <--> Explorer1[Use @explorer for codebase discovery]
    Oracle1 <--> Library1[Use @librarian for documentation discovery]
    Oracle1 --> Plan1[Generates implementation plan based on research]

    CouncilCall --> Council2[Use @council to generate viewpoint 2]
    Council2 --> Oracle2[Use @oracle to generate plan]
    Oracle2 <--> Explorer2[Use @explorer for codebase discovery]
    Oracle2 <--> Library2[Use @librarian for documentation discovery]
    Oracle2 --> Plan2[Generates implementation plan based on research]

    CouncilCall --> Council3[Use @council to generate viewpoint 3]
    Council3 --> Oracle3[Use @oracle to generate plan]
    Oracle3 <--> Explorer3[Use @explorer for codebase discovery]
    Oracle3 <--> Library3[Use @librarian for documentation discovery]
    Oracle3 --> Plan3[Generates implementation plan based on research]

    Plan1 --> Council[Council selects the best of the implementation plans]
    Plan2 --> Council[Council selects the best of the implementation plans]
    Plan3 --> Council[Council selects the best of the implementation plans]

    Council -- "Using final plan generated by the council" --> Plan[spawn @oracle to implement plan]

    Plan --> FixerBlock1[Orchestration calls @fixer subagents to implement]
    Plan --> FixerBlock2[Orchestration calls @fixer subagents for tests]
    Plan --> FixerBlock3[Orchestration calls @fixer subagents to implement documentation if needed]

    FixerBlock1 --> Imp[Fixers implement code changes, enters review cycle]
    FixerBlock2 --> Imp[Fixers implement code changes, enters review cycle]
    FixerBlock3 --> Imp[Fixers implement code changes, enters review cycle]
    Imp --> Reviewer-Orchestrator[Orchestration spawns @reviewer-orchestrator agent for review, runs review skill]
    Reviewer-Orchestrator --> LGTMCheck["LGTM | LGTM with Comments | Minor Issues | Significant Concerns"]
    LGTMCheck -- "LGTM | LGTM with Comments" --> Commits[Split into concise commits]
    LGTMCheck -- "Minor Issues" --> ReviewOracle[Calls @oracle to review the changes suggested. implement with @fixer if needed. Call a new @reviewer-orchestrator agent to re-review]
    LGTMCheck -- "Significant Concerns" --> ReviewOracle[Calls @oracle to review the changes. implement with @fixer. Call a new @reviewer-orchestrator agent to re-review]
    ReviewOracle -- "Re-reviews after implementation" --> Reviewer-Orchestrator

    Commits --> EndUser["Ask user about creating a pull request"]
```

