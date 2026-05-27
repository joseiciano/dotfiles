---
description: Plan a product requirements document to get the high level construct of a product idea
agent: product-manager
---

Arguments Provided: `$ARGUMENTS`

Create a Product Requirements Diagram (PRD) on the given idea. If no idea is given, prompt the user to give the product they want to build. 

If you are given a PRD already. Analyze it and extract the arguments from it. Your task (if given an existing PRD) is to analyze it, fill in the missing gaps, and make sure it abides by the final output format. 

## Argument Parsing

Analyze arguments to see if the following information is provided. 

- `NAME`: The product name. 
- `PROBLEM`: What is the problem this product is meant to solves
- `OBJECTIVE`: What this product aims to do
- `AUDIENCE`: Who this product is for

If you are not able to understand any of these fields, prompt the user for more information. 

## Document Sections 

### Introduction

This section should serve as an eyecatcher. We use this section to get a high level overview of what the problem is, who is it for, and what are we trying to fix. 

Just because it is an eyecatcher, does not mean to be extravagant. No emojis, no jokes or bad comparisons. Focus on the hard facts that we can bring up. 

**Good Example**: "This document is to bring up the product requirements for Fishly, the social media app for fishers. Currently, fishermen have difficulties finding others in their area who have a similar hobby to them. And when trying to find people to join them on long excursions, it can be hard to find help. Fishly aims to solve that by giving an open platform for them to communicate with one another."

**Bad Example**: 
- (too short) "Fishly is the social media app for fishers."
- (too hard at trying to make a comparison) "Fishly is facebook for fishermen"

### Problem 

This section is where we go into the problem statements. Focus on the following:

  - **Pain Point**: What is the major problem we are looking to solve? What is our product for?
  - **Competitors**: Who out there has similar products to us. What do they provide and where are they lacking. 

Think about what we want to solve and make sure that it is explicit, clear, and easy to understand. 

### Solution

Spawn a @product-manager-mini subagent with the problem statement above to give a solution for this. 

This section is where we talk about the product we are building. How does it solve these pain points? How does it edge us over the competitors or puts us pound-for-pound against them?

### Personas

Spawn 3 @product-manager-mini subagents with the problem and solution statements above to create personas. Make sure they use the persona skill for this.

Prompt them with the following: "Use the 'Persona' skill to generate a persona for the problem `$problem_statement` that we aim to solve with `$solution`"

In this section, focus on generating user personas to help us get a clear picture of the customers that we will be serving. 

## Final Output

Shape the data from the subagents into the final format provided here. 

```markdown
# (product name) Product Requirements Document

## Introduction 

This document is to serve the product requirements for (product name). ...(1-3 more sentences serving a high level overview of the product)

## Problem

1-3 sentences talking about the problem that we are trying to solve. Feel free to break it down into bullet points if needed.

### Competitors
- **(competitor name)**: 1-3 sentences on the product they provide, where it competes with us, and where it currently lacks. 

## Solution

Talk about the solution we intend to provide. What are we intending to do? What is the way we intend to solve the problem mentioned above. 

### Features
- Bullet point list of features we intend to support

## Personas

### Persona (number): (name) - (position)
 
#### Bio and Demographics
- Bullet point list of general information on the persona 

#### Quotes
- Bullet point list of 1 sentence quotes that serve to give an idea of the persona and what is their pain points. 

#### Pain Points
- Bullet point list of the problems they face. This should give an idea of what our problem solves to fix

#### How We Help
- Bullet point list of how exactly our product intends to help them out
```

## Workflow Diagram

```mermaid
flowchart TD
   product-manager -- "1. Fetches problem statement based on research and data provided" --> pm_problem
   pm_problem -- "2. Gives back problem statement and competitors" --> product-manager
   
   product-manager -- "3. Asks to solve the solution to our problem, giving the problem statement and data we have so far." --> pm_solution_subagent
   pm_solution_subagent -- "4. Gives back the solution based on what we intend to do and the problem statement." --> product-manager

   pm_persona_subagent_1 -- "5. Generates user persona" --> product-manager

   pm_persona_subagent_2 -- "5. Generates user persona based on 1-4" <--> product-manager

   pm_persona_subagent_3 -- "5. Generates user persona" --> product-manager

   product-manager -- "6. Reviews and analyzes data given by subagents" --> product-manager 
   product-manager --> client[7. Generates final outputted prd document]
```
