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

Analyze our functional spec and/or system design documents. Make sure they all follow the same page and that there are no discrepancies. 

**Things to look out for**:
- Are we changing tech stacks between sections? (ex: going from react to angular, swapping from postgres to nosql)
- Are we changing defined data schemas (ex: removing/adding a field to the same data structure in two different sections)
- Are we changing service structure between sections/docs (ex: Are we using an outbox pattern in one section then changing it to a queue in another?)
- Are there any documents that are now out of date or obsolete?

### Step 2: Functional Discrepancies Analysis 

If there are any data drifts found from the last step, call a new @oracle to see what we can do to reconcile. Analyze our docs, prompt the user for more information if needed, and see what can be done to fix this. 

### Step 3: Product Discrepancies

Call a @product-manager subagent to analyze our product documents. Compare them to our functional spec. Make sure we are covering all bases and that our documents are aligned. 

**Things to look out for**:
- Do our docs cover the entire solution we are planning for the current product?
- Are there any gaps in what product features we mentioned including and what our design currently covers?

### Step 4: Product Discrepancies Analysis

If there are any drifts found from the last step, call a new @product-manager-mini, and a new @oracle subagent to see what we can do to reconcile. The oracle subagent is to give us a functional engineering pov, and the product-manager-mini is to give us a product viewpoint. 

## Final Output

Generate the final output for the caller as follows:

```markdown
# Product Drift Analysis

## Functional Analysis
 
### Data Drifts 
- Bullet point list of what drifts occur, N/A if none 

### Recommended Changes
- Bullet point list of changes to make 

## Product Analysis 

**Covers Product Solution**: "Entirely" | "Covers Some" | "Drifts detected, missing major features"

### Data Drifts
- Bullet point list of what drifts occur, N/A if none 

### Recommended Changes
- Bullet point list of changes to make 

```
