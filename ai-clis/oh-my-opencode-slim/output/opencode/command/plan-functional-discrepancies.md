---
description: Analyze product and design docs to account for discrepancies
agent: orchestration
---

## Pre-requisites

This command must be called in a repository with a `docs/`, `product/`, and `system/` directory/sub-directory. 

**IF SUCH DIRECTORIES DO NOT EXIST, PROMPT THE USER AND STOP HERE**

## Goal

The goal here is to analyze our current documents and to make sure our functional specs do not have any discrepancies between them, and that our functional specs align with our product document. 

## Steps
### Step 1: Functional Spec Discrepancies

#### Step 1a: Find files 
Call @explorer to search for **only** functional spec or system design documents. 

Keep track of the following: 
- `FUNCTIONAL_SPEC`: path to functional spec document
- `DESIGN_DOC_PATHS`: list of paths to design documents

#### Step 1b: Search for Discrepancies
Call @engineering-manager to search for the following: 
- Functional spec documents
- System design documents

Analyze each one and look for any discrepancies or data drifts. 

Prompt the engineering-manager as follows (**always follow this format**):

```markdown
## Task
As an exceptional engineering manager with multiple years of experience, analyze the documents given in the following paths: 

- $FUNCTIONAL_SPEC (use the actual path here in this variable)
- $DESIGN_DOC_PATHS (use the actual path here in this variable)

to see if there any discrepancies in them. Search for the following: 

**Things to look out for**:
- Are we changing tech stacks between sections? (ex: going from react to angular, swapping from postgres to nosql)
- Are we changing defined data schemas (ex: removing/adding a field to the same data structure in two different sections)
- Are we changing service structure between sections/docs (ex: Are we using an outbox pattern in one section then changing it to a queue in another?)
- Are there any documents that are now out of date or obsolete?

## Output 
Discrepancies Found: 
| File Name | Path to File | File Paths with discrepancies | Explanation | 
| --- | --- | --- | --- |
| (Name of file) | (Full path to the file) | (Path to the files that there are discrepancies with) | Explanation of why there are discrepancies with the given files |
```

Store the output table from engineering-manager in this variable:
- `FUNCTIONAL_DISCREPANCIES`

#### Step 1c: Find Solutions
If there are any discrepancies found, send the `FUNCTIONAL_DISCREPANCIES` to an @oracle subagent to plan how to reconcile these fixes. Analyze our docs, prompt the user for information if needed, and see what can be done to fix this. 

Call the oracle subagent with the following prompt: 

```markdown
Analyze the following discrepanices in the following files
$FUNCTIONAL_DISCREPANICES

Search the codebase for solutions to fix these drifts. Call @explorer as needed to search the codebase, and figure out the best way to fix this drift while accounting for the following: 

- Do we still fix the original issue? 
- What way will be the most like the original plan? 
- What way will be the path of least resistance? 

Create a plan to do fix this. Use this format:
| File Path | File Paths with discrepancies | Potential Resolution | 
| --- | --- | --- | 
| (Path to file) | (Path to all files with discrepancies to the original file) | Suggested fix for this issue |
```

### Step 2: Product Discrepancies

#### Step 2a: Find files 
Call @explorer to search for **only** product documents (i.e. PRD, Story Tickets)  

Keep track of the following: 
- `PRODUCT_FILES`: list of paths to design documents

#### Step 2b: Search for Discrepancies
Call @product-manager to search for the following: 
- Functional spec documents
- System design documents

Analyze each one and look for any discrepancies or data drifts. 

Prompt the product-manager as follows (**always follow this format**):

```markdown
## Task
As an exceptional engineering manager with multiple years of experience, analyze the documents given in the following paths: 

- $PRODUCT_FILES (use the actual paths here in this variable)

to see if there any discrepancies in them. Search for the following: 

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
- `PRODUCT_DISCREPANCIES`

#### Step 2c: Find Solutions
If there are any discrepancies found, send the `PRODUCT_DISCREPANCIES` to an @oracle subagent to plan how to reconcile these fixes. Analyze our docs, prompt the user for information if needed, and see what can be done to fix this. 

Call a @product-manager subagent to analyze our product documents. Compare them to our functional spec. Make sure we are covering all bases and that our documents are aligned. 


### Step 4: Product Discrepancies Analysis

If there are any drifts found from the last step, call a new @product-manager-mini, and a new @oracle subagent to see what we can do to reconcile. The oracle subagent is to give us a functional engineering pov, and the product-manager-mini is to give us a product viewpoint. 

Prompt the oracle subagent with the following:
```markdown
Analyze the following discrepanices in the following files
$PRODUCT_DISCREPANICES

Search the codebase for solutions to fix these drifts. Call @explorer as needed to search the codebase, and figure out the best way to fix this drift while accounting for the following: 

- Do we still fix the original issue? 
- What way will be the most like the original plan? 
- What way will be the path of least resistance? 

Create a plan to do fix this. Use this format:
| File Path | File Paths with discrepancies | Potential Resolution | 
| --- | --- | --- | 
| (Path to file) | (Path to all files with discrepancies to the original file) | Suggested fix for this issue |
```

## Final Output

Generate the final output for the caller as follows:

```markdown
# Data Drift Analysis

## Functional Drifts
- (File Path)
  - Bullet point list of what drifts occur. Recommended Fix: (Recommended fix from oracle)

### Recommended Changes
- Bullet point list of changes to make

## Product Analysis

### Solution Coverage

"Entirely" | "Covers Some" | "Drifts detected, missing major features"

### Data Drifts
- (File Path)
  - Bullet point list of what drifts occur. Recommended Fix: (Recommended fix from oracle)

### Recommended Changes
- Bullet point list of what changes to make
```

