---
description: iterate on code review changes 
agent: orchestration
---

## Task 

Loop in the following manner: 
- Run a code review
- Iterate on the changes in the review
- Re-review until we get an `Approved` status

## Review Background

Analyze the `docs/` path and pass in as `--background` flag information any product and functional spec docs that are relevant to the ticket at hand. 

## Workflow

### Step 1: Generate Code Review
Spawn a @reviewer subagent with the following prompt:

```markdown
Run the `review` SKILL on the work given to you, analyzing the changes we current have on this Git branch.

## Review-Result Output File

The code review should be outputted to `code_reviews/<ticket>/code_review_x.md` where `x` starts at 1 and increments up each time if the previous exists. If the ticket includes numbers (e.g. "5-7-new-api-route.md"), the numbers are the ticket number (file created should be `code_reviews/5-7/code_review_1.md` for example).

**Note**: If `<ticket>` does not exist, prior to calling the AI reviewer CLI, generate a 1-3 hyphenated summary (e.g. `test-local-dev`) to be the name. 

**Note**: Always verify if there is already a folder for the current of work. If one already exists, do not create another. Ensure that if there is a number associated with the ticket, that is the ticket name. 

## Final Output

1. Output the code review to the file mentioned above. The command/orchestrator must create the parent directory and write the final Markdown review using shell redirection or `tee` — not the edit/write tools (these are denied). For example:
    `mkdir -p "$(dirname "$output_file")"; <review-output-command> | tee "$output_file"`

2. Output the review to the user as well. Do not show anything other what the review/skill mentions as the output. 
```

### Step 2: Analyze Latest Review

Analyze the latest code review generated. 

If there are **NO** **CRITICAL**, **HIGH**, or **MEDIUM** comments: Prompt the user with the following:
```
Reviews Generated: <number of code reviews generated>
Comments Revised: <number of comments addressed>
```
and **STOP HERE**.

Otherwise, continue to step 3

### Step 3: Address Review Comments

**IF THERE ARE NO CRITICAL, HIGH, OR MEDIUM-level COMMENTS, STOP HERE**

Spawn an @oracle subagent to address the comments. Spawn with this prompt:

```markdown
## Task

Address the following **CRITICAL**, **HIGH**, and **MEDIUM**-level comments generated in <path to latest code review>.

- [ ] For each change, analyze the codebase to see what is needed. Make sure to use @explorer subagents when needed. 

- [ ] If needed, check external documentation with @librarian subagents. 

- [ ] Implement the changes using @fixer subagents. 

## Final Output

After addressing the comments, output the following:

- <Comment>: 
  - **Resolution**: 1-2 sentence brief summary of what was changed and the files edited/added/deleted to accommodate this.
```

### Step 4: Re-loop

Re-run the workflow from step 1 using a new @reviewer subagent.
