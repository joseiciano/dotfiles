---
description: Plan and implement multiple plan files end-to-end, creating tests and documentation as needed. 
agent: build
permissions:
  bash: allow
  read: allow
  grep: allow
  glob: allow
  edit: allow
  write: allow
  external_directory:
    "*": allow
---

## Pre-Requisites

Arguments Received: `$ARGUMENTS`

Parse the arguments as follows:

- `PLAN_FILES`: Array of file paths pointing to specific implementation plans

## Task


For each file in `PLAN_FILES`, do the following: 

- Call an @orchestration subagent to implement that specific plan file using the `implementation-loop` skill. Prompt it with the following:

```
## Task

1. Run the `implementation-loop` skill on the given file: $FILE

Ensure that the implementation is end-to-end and covers all details from the spec provided. 

2. Once implementation is complete, call the @review-orchestrator subagent to run the `review` skill and perform a code review. 

If we receive an `LGTM` or `LGTM with Comments` from this, accept this. Stop here so that the parent agent calling you can move on to the next ticket. 

If we do not receive an `LGTM` or `LGTM with Comments` from this, iterate on the feedback provided by the code review (found in prompts/code_review/) and re-run after the feedback.
```


## Requirements

The following requirements are necessary as part of this command. **Always** follow them. 

- One @orchestration agent for one plan file. If we move on to a new file, that is a new @orchestration call. 
- We want to iterate through each file in `PLAN_FILES` **SEQUENTIALLY**. Do not go out of order no matter what. If we are still implementing one, keep going until it is done before going to the next. 


