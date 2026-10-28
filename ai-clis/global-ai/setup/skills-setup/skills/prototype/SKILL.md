---
name: prototype
description: Build a throwaway prototype to answer a design question. Use when the user wants to sanity-check whether a state model or logic feels right, or explore what a UI should look like.
---

# Prototype

Generate a temporary prototype to answer a specific question about the current project. 

## Pick a Playbook

Identify the type of question we want to answer, using the user's prompt, surrounding code, or by asking the user. Then, redirect it to the specific playbook. 

- [**logic**](./playbooks/logic.md):
  - **Used For**: Understanding business logic, data models, and data flow from a high level (PM) point-of-view
  - **What this answers**: "Is this the best way to represent this data?"
- [**ui**](`./playbooks/ui.md`):
  - **Used For**: Viewing and testing multiple UI suggestions for the best one. 
  - **What this answers**: "What is the best way to show this in the UI?"

## Rules that apply to all branches

1. **Throwaway from day one, and clearly marked as such.**  
  - Place the prototype code close to where it will be used (next to the module or page it's prototyping). 
  - Always name it such that a casual reader can see it's a prototype and meant to have a temporary existence (`X_prototype.<file_type>`).
  - For throwaway UI routes, obey whatever routing convention the project already uses; don't invent a new top-level structure.
2. **Trivial to run.** 
  - A prototype should have a simple command in the project's task runner to open it: `pnpm <name>`, `python <path>`, `bun <path>`, etc. A logic demo is a single HTML file the user double-clicks. 
  - No thinking should be required to start it. 
3. **No persistence by default.** 
  - State lives in memory. Persistence is the thing the prototype is _checking_, not something it should depend on. 
  - If the question explicitly involves a database, hit a scratch DB or a local file with a clear "PROTOTYPE, wipe me" name.
4. **Skip the polish.** 
  - No tests, no error handling beyond what makes the prototype _runnable_, no abstractions. The point is to learn something fast.
5. **Surface the state.** 
  - After every action or variant switch, print or render the full relevant state so the user can see what has changed. 
6. **Capture it when done.** 
  - Fold any validated decision into the real code. 
  - Capture the prototype that was validated and store it in the knowledge base. 
  - It will not be in the final branch, but will be easily retrievable from the knowledge base as a data source for why something was done a certain way. 
