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

### Step 1: Generate Spec_Plan if nonexistant

For this, load the `plan-implementation-plan` skill to see the proper format of an implementation plan. 

For the following cases:

- **IMPLEMENTATION PLAN EXISTS, SAME FORMAT AS `plan-implementation-plan`**: SKIP THE REST OF THIS STEP AND GO TO STEP 2
- **IMPLEMENTATION PLAN EXISTS, NOT SAME FORMAT AS `plan-implementation-plan`**: Modify the implementation plan to fit the expected format. SKIP EVERYTHING AFTER THIS AND GO TO STEP 2
- **IMPLEMENTATION PLAN DOES NOT EXIST**: If we do not have an implementation plan, we have to create one first. 

**SKIP THIS STEP IF WE ARE ALREADY GIVEN AN IMPLEMENTATION PLAN**

Spawn 1 @council subagent to handle generating the implementation plan. Use this prompt **exactly**:

```markdown
You are a council needed to draft up an implementation plan for the given scenario: $DESCRIPTION. 

View it from different viewpoints using multiple @councillor subagents, scour the codebase and any documentation for relevant information. 

Detail any changes that will be needed, what files to add/change, what variables/logic will we need. Use @explorer to dig through the codebase to figure, @librarian to check on documentation. 
```

### Step 2: Implement Plan

Analyze the implementation plan from Step 1. Implement it to completion. 

- Use parallel @explorer subagents to review codebases where needed
- Use parallel @librarian subagents to review codebase documentation
- Use parallel @fixer subagents where possible to implement as quickly as possible, while still maintaining thoroughness

Do not stop until all details are implemented from the implementation file and that all files planned are completed.

### Step 3: Review Implementation

Review the current implementation we completed from Step 2. Call a @reviewer with the following prompt:

```
Review the current work on this branch. Use the `review` skill to review current changes.  
```

You must **always** use the `review` skill for code reviews. 

The code review should be outputted to `code_reviews/<ticket>/code_review_x.md` where `x` starts at 1 and increments up each time if the previous exists. If the ticket includes numbers (e.g. "5-7-new-api-route.md"), the numbers are the ticket number (file created should be `code_reviews/5-7/code_review_1.md` for example).

**Note**: If `<ticket>` does not exist, prior to calling the AI reviewer CLI, generate a 1-3 hyphenated summary (e.g. `test-local-dev`) to be the name. 

**Note**: Always verify if there is already a folder for the current of work. If one already exists, do not create another. Ensure that if there is a number associated with the ticket, that is the ticket name. 

### Step 4: Address Concerns

**IF NO POINTS WERE BROUGHT UP IN THE CODE REVIEW FROM STEP 3 - SKIP TO STEP 5**

Analyze the code review generated in Step 3. We want to address any **high**, **medium** comments brought up in them. 

- Review with @explorer subagents what is needed to implement the points addressed. 
- Implement fixes with @fixer subagents. 

After implementing, spawn a new @reviewer and repeat steps 3-4 until we have no more **high** or **medium** comments. 

### Step 5: Final Output

Output completion of implementation to the end user. 

```
Status: Complete
Revisions: <Number of code reviews generated>
Outcome: 1-2 short non-dense sentence describing the outcome from this ticket. 

Would you like to create a pull request?
```

### Step 6: Pull Request

If the answer to the pull request question in Step 5 is yes, run the `commit-pull-request` skill to:

- Create commits for current changes
- Create a pull request for current changes

