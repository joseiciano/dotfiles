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

Spawn 1 @oracle subagent to handle generating the implementation plan. Use this prompt **exactly**:

```markdown
You are needed to draft up an implementation plan for the given scenario: $DESCRIPTION. 

Analyze the codebase and any necessary documentation, then draft up an implementation plan that is able to be handed-off to implementation agents. 

Be as detailed as possible, providing step-by-step details and file-by-file change-lists. 

## Output

Return just the following: 

1. A markdown formatted implementation plan
```

### Workflow Steps

1. Spawn an @oracle subagent to handle planning and detailing the work done as part of this implementation. 
  1a. Analyze `$SPEC_PLAN`, search the codebase for any necessary context using @explorer subagents.
  1b. Analyze `$SPEC_PLAN`, search for any documentation needed using @librarian subagents. 
  1c. Detail the following that will be needed:
    - What files will need to be added/changes
    - What variables/logic will need to be added/changed
2. Implement the work detailed via @fixer subagents
3. After implementation is complete, call a @reviewer-orchestrator with the following prompt:

```markdown
Run the `review` skill on the work completed on this branch. Include any committed and un-committed work. 

Have the final review outputted to `code_reviews/<ticket>/code_review_x.md` where `x` starts at 1 and increments up each time if the previous exists. 

If `<ticket>` does not exist, generate a 1-3 hyphenated summary (e.g. `test-local-dev`) to be the name. 
```

4. Analyze the review status:
  - If review is "LGTM" or "LGTM with Comments", **stop here**
  - Otherwise, continue to step 5 for reviewing and implementing any changes. 

5. Analyze the review doc and see what changes are pointed out. Implement the changes requested using @fixer subagents.
6. Repeat steps 3-5 until you get an "LGTM" or "LGTM with Comments" as the final review status. 
7. Analyze the current changes, cut them into small, concise commits. 
8. Prompt the user the following:

```markdown
Implementation: Complete
Final Review Status: <Review status from last `code_reviews/<ticket>/code_review_x.md`
Revisions Done: <How many code_reviews were generated as part of this loop>

Would you like to create a pull request for these changes?
```

**Note**: For the review cycles you **must** always use the `review` skill.

