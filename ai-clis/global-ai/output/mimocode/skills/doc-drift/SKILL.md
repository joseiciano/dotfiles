---
name: doc-drift
description: Analyze current technical and product documentation for any data drifts and discrepancies. Use when reviewing exist documentation. 
command: true
---

## Summary

This skill is used to review existing documentation and making sure they all follow the same north star. 

Use in cases of creating or modifying existing documentation. 

## Goal

The goal here is to analyze our current documents and to make sure our functional specs do not have any discrepancies between them, and that our functional specs align with our product document. 

## Steps
### Step 1: Finding Documentation

Search the codebase for documentation. Categorize it into three:

- `$SYSTEM`: Functional-related documentation. Hard technicals (i.e. API routes, Functional Specs, System Design Documents)
- `$PRODUCT`: Product-related documentation. Business related (i.e. PRD, individual ticket stories)
- `$STORIES`: Individual story tickets to be worked on. 

### Step 2: Search for System Discrepancies

Call @engineering-manager to review `$SYSTEM` for any discrepancies or data drifts in our system-related documents. 

Prompt the engineering-manager as follows (**always follow this format**):

```markdown
## Task
Identify any data drifts or discrepancies in the following documentation path(s):

- $SYSTEM (use the actual path here in this variable)

**Things to look out for**:
- Are we changing tech stacks between sections? (ex: going from react to angular, swapping from postgres to nosql)
- Are we changing defined data schemas (ex: removing/adding a field to the same data structure in two different sections)
- Are we changing service structure between sections/docs (ex: Are we using an outbox pattern in one section then changing it to a queue in another?)
- Are there any documents that are now out of date or obsolete?
- Are the functional spec and system design documents up to date with the rest of the documentation?
- Do we have a functional spec or system design diagram? **MARK THIS AS A DISCREPANCY IF NOT EXISTS**

## Output 
Discrepancies Found: 
| File Name | Path to File | File Paths with discrepancies | Explanation | 
| --- | --- | --- | --- |
| (Name of file) | (Full path to the file) | (Path to the files that there are discrepancies with) | Explanation of why there are discrepancies with the given files |
```

Store the output table from engineering-manager in this variable:
- `$FUNCTIONAL_DISCREPANCIES`

### Step 3: Think of System Discrepancy Solutions
If there are any `$FUNCTIONAL_DISCREPANCIES` found, plan out how to reconcile these issues. 

Call @plan to think of a way to figure this out. Prompt it with the following: 

```markdown
Analyze the following discrepancies in the following files
$FUNCTIONAL_DISCREPANCIES

Research and think of the best way to fix these data drifts. 
- Call @explorer subagents in parallel to search the codebase
- Call @librarian subagents in parallel to research any documentation
- If there are any questions left, prompt the user. Never assume anything. 

When researching, make sure the plan you think of addresses these questions:
- Do we still fix the original issue? 
- What way will be the most like the original plan? 
- What way will be the path of least resistance? 

Create a plan to do fix this. Use this format:
| File Path | File Paths with discrepancies | Potential Resolution | 
| --- | --- | --- | 
| (Path to file) | (Path to all files with discrepancies to the original file) | Suggested fix for this issue |
```

### Step 4: Search for Product Discrepancies
Call @product-manager to review `$SYSTEM` for any discrepancies or data drifts in our system-related documents. 

Prompt the product-manager as follows (**always follow this format**):

```markdown
## Task
Identify any data drifts or discrepancies in the following documentation path(s):

- $PRODUCT (use the actual path here in this variable)

**Things to look out for**:
- Do our docs cover the entire solution we are planning for the current product?
- Are there any gaps in what product features we mentioned including and what our design currently covers?

## Output 
Discrepancies Found: 
| File Name | Path to File | File Paths with discrepancies | Explanation | 
| --- | --- | --- | --- |
| (Name of file) | (Full path to the file) | (Path to the files that there are discrepancies with) | Explanation of why there are discrepancies with the given files |
```

Store the output table from engineering-manager in this variable:
- `$PRODUCT_DISCREPANCIES`

### Step 5: Think of Product Discrepancy Solutions
If there are any `$PRODUCT_DISCREPANCIES` found, plan out how to reconcile these issues. 

Call @plan to think of a way to figure this out. Prompt it with the following: 

```markdown
Analyze the following discrepancies in the following files
$PRODUCT_DISCREPANCIES

Research and think of the best way to fix these data drifts. 
- Call @explorer subagents in parallel to search the codebase
- Call @librarian subagents in parallel to research any documentation
- If there are any questions left, prompt the user. Never assume anything. 

When researching, make sure the plan you think of addresses these questions:
- Do we still fix the original issue? 
- What way will be the most like the original plan? 
- What way will be the path of least resistance? 

Create a plan to do fix this. Use this format:
| File Path | File Paths with discrepancies | Potential Resolution | 
| --- | --- | --- | 
| (Path to file) | (Path to all files with discrepancies to the original file) | Suggested fix for this issue |
```

### Step 6: Story Analysis

Search for any data drifts in stories. We want to make sure that all stories align with each other and flow into one another where appropriate. 

We do not want stories that step on each other's toes or go off into completely different directions. 

Call @engineering-manager to review `$STORIES` for any discrepancies or data drifts in our story tickets. 

Prompt the engineering-manager as follows (**always follow this format**): 

```markdown
## Task
Identify any data drifts or discrepancies in the following documentation path(s):

- $STORIES (use the actual path here in this variable)

**Things to look out for**:
- Do our docs cover the entire solution we are planning for the current product?
- Are there any gaps in what product features we mentioned including and what our design currently covers?
- Do any tickets cover the same body of work? 
- Do any tickets change direction in what is to be done? 
- Are any tickets out of work order?

## Output 
Discrepancies Found: 
| File Name | Path to File | File Paths with discrepancies | Explanation | 
| --- | --- | --- | --- |
| (Name of file) | (Full path to the file) | (Path to the files that there are discrepancies with) | Explanation of why there are discrepancies with the given files | 
```

Store the output table from engineering-manager in this variable:
- `$TICKET_DISCREPANCIES`

### Step 7: Think of Story Discrepancies Solutions

If there are any `$TICKET_DISCREPANCIES` found, plan out how to reconcile these issues. 

Call @plan to think of a way to figure this out. Prompt it with the following: 

```markdown
Analyze the following discrepancies in the following files
$TICKET_DISCREPANCIES

Research and think of the best way to fix these data drifts. 
- Call @explorer subagents in parallel to search the codebase
- Call @librarian subagents in parallel to research any documentation
- If there are any questions left, prompt the user. Never assume anything. 

When researching, make sure the plan you think of addresses these questions:
- Do we still fix the original issue? 
- What way will be the most like the original plan? 
- What way will be the path of least resistance? 

Create a plan to do fix this. Use this format:
| File Path | File Paths with discrepancies | Potential Resolution | 
| --- | --- | --- | 
| (Path to file) | (Path to all files with discrepancies to the original file) | Suggested fix for this issue |
```

### Step 8: Synthesize Final Output

Reading both plan files, as well as the drifts, generate a final output for the user. 

```markdown
# Data Drift Analysis

## Functional Drifts
- (File Path)
  - Bullet point list of what drifts occur. 
  - **Recommended Fix**: (Recommended fix from Step 3)

### Recommended Changes
- Bullet point list of changes to make

## Product Analysis

### Solution Coverage

"Entirely" | "Covers Some" | "Drifts detected, missing major features"

### Data Drifts
- (File Path)
  - Bullet point list of what drifts occur. 
  - **Recommended Fix**: (Recommended fix from Step 5)

### Recommended Changes
- Bullet point list of what changes to make

## Story Analysis

### Stories In Sync

"Entirely" | "Some discrepancies" | "Many drifts"

### Data Drifts
- (File Path to Story)
  - Bullet point list of what drifts occur. 
  - **Recommended Fix**: (Recommended fix from Step 7)
```

If there are any data drifts, output this file in `plans/MM-DD-YY-Drift-X.md` where `X` starts at 1 and increments if already exists. 

## What to Look For 

- Differences in programming languages (JS vs Go)
- Tech stack differences (i.e. one file mentions using a queue, the other has the data just written to a database)
- Tech stack changes (i.e. SQL vs noSQL in different documents)
- Different codebase structure (i.e. monorepo vs different repos for different services)

## What Not to Look Out For

- "Use X instead of Y"-style suggestions
- The lack of a mention of something in a document. If it is not needed in a doc, it does not need to be stated. 
- "To be done in X"-style references when it's already stated in some other doc/the doc itself. 


