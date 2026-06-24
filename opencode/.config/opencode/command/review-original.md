---
description: Run an ai review against current changes. Ensuring the best iteration of changes comes out
agent: reviewer-orchestrator
permissions:
  bash: allow
  read: allow
  grep: allow
  glob: allow
  edit: deny
  external_directory:
    "~/dotfiles/opencode/.config/opencode/**": allow
---

Arguments Received: `$ARGUMENTS`

Run a thorough local AI code review of all current changes. 

**Note**: Unless explicitly dictated, **always** review the current branch against `main` (`origin/main`).

## Input Arguments 

This command provides the following arguments:

- `ticket` (**OPTIONAL**): A path to the ticket that the current changes are implemented for. If no ticket was provided, assume there is none.  
- `description` (**OPTIONAL**): A description of what these changes are to do. **IF `ticket` IS NOT PROVIDED, THIS FIELD IS REQUIRED** 

## Review Steps

### Step 1: Gather Diff

**Goal**:
Review command preloads git review data before agent handoff. Use injected context for current branch against `origin/main`.

Store:
- `TARGET_BRANCH` - target branch for review
- `BASE_SHA` - output of `git merge-base`
- `CHANGED_FILES` - list from `git diff --name-status`
- `DIFF_STAT` - summary from `git diff --stat`
- `FULL_DIFF` - full patch from git diff

If git is unavailable or the working directory is not a git repository, stop and tell the user. 

### Step 2: Gather Optional MR Context

1. Read the `ticket` provided with an @explorer to extract information on what the change is to do. 

2. If the `ticket` is unavailable, go off the `description` and feel free to ask the user for more information if it not clear enough. 

### Step 3: Hand off to review-orchestrator

You now have everything needed. Use @review-orchestrator and follow its instructions exactly, passing:

- `CHANGED_FILES`
- `DIFF_STAT`
- `FULL_DIFF`
- `BASE_SHA`
- `MR_CONTEXT` (if available, otherwise empty)
- `TARGET_BRANCH`

> Classify files into `code` and `docs` categories. Assess risk tier (trivial/lite/full). Select and run the appropriate reviewer passes from @reviewer-code-quality, @reviewer-security, @reviewer-performance, and @reviewer-documentation - in parallel if possible, sequentially otherwise. Each reviewer returns XML per "reviewers-shared".  Deduplicate findings, apply the judge pass, determine the overall decision, and print the final review as markdown. 

## Output

The review-orchestrator prints the final review as **markdown** directly to the conversation. Specialist reviewers return intermediate **XML** that the review-orchestrator consumes internally - do not surface raw XML to the user. Post the output of the final review in the chat and in `(repo)/ticket/code-review-x.md` where `x` starts at 1 and is incremented if there is already a file with that name. 

## Diagram

The given diagram details the steps that are to be done.

**Note**: **ALWAYS CALL THE INDIVIDUAL REVIEWER SUBAGENTS IN PARALLEL**
**WHEN POSSIBLE (i.e. Opencode), RUN THE SUBAGENTS IN PARALLEL AND WAIT FOR ALL TO COMPLETE**

```mermaid
flowchart td 
  client --> command[Calls review command]
  command --> reviewer-orchestrator[Starts code review]
  reviewer-orchestrator --> reviewer-agents-md[Calls @reviewer-agents-md to review agents.md files]
  reviewer-orchestrator --> reviewer-code-quality[Calls @reviewer-code-quality to review code quality in diffs]
  reviewer-orchestrator --> reviewer-code[Calls @reviewer-code to review general code in diffs]
  reviewer-orchestrator --> reviewer-documentation[Calls @reviewer-documentation to review documentation against current changes]
  reviewer-orchestrator --> reviewer-performance[Calls @reviewer-performance to review changes against performance expectations]
  reviewer-orchestrator --> reviewer-security[Calls @reviewer-security to reviewer changes for security risks]

  reviewer-agents-md --> reviewer-orchestrator[Send back review data]
  reviewer-code-quality --> reviewer-orchestrator[Send back review data]
  reviewer-code --> reviewer-orchestrator[Send back review data]
  reviewer-documentation --> reviewer-orchestrator[Send back review data]
  reviewer-performance --> reviewer-orchestrator[Send back review data]
  reviewer-security --> reviewer-orchestrator[Send back review data]

  reviewer-orchestrator -- "filters and anaylzes reviews from subagents" --> output[outputs final review]
```
