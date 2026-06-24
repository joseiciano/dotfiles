---
description: iterate on code review changes 
agent: orchestration
permissions:
  bash: allow
  read: allow
  grep: allow
  glob: allow
  edit: deny
  external_directory:
    "~/dotfiles/opencode/.config/opencode/**": allow

---

Analyze the latest code review in `<...codebase directory>/prompts/code_review/code_review_x.md`. The latest is the one with the **highest** number for `x`. 

Iterate on the changes mentioned in there that are `serious concerns` using @oracle. **DO NOT ITERATE ON ANY OTHER TIER UNLESS EXPLICITLY STATED**. 

**IF THERE ARE NO SERIOUS CONCERNS IN THE REVIEW, STOP HERE AND PROMPT THE USER IF THEY WOULD LIKE TO REVIEW THE NON-SERIOUS CONCERNS (minor nits, warnings)**

Once those changes are done, spawn a new @reviewer-orchestrator and use the `review` skill to re-review and generate a new `code_review_(x+1).md` file. 
