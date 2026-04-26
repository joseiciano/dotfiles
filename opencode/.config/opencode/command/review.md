---
description: Review current changes against initial story for correctness. 
agent: orchestration
---

Use @council to spawn 3 subagents to review of the current changes in our codebase. 

For each councillor, use @oracle to analyze the current changes and make sure that they are correct based on the related story document (found in docs/product/stories/stories). Make sure that the changes cover the bullet points and do not miss anything that was mentioned in the document. 

Checklist (use @oracle to plan this out):
- [ ] Are the current changes accurate to what was specified in the initial ticket document? 
- [ ] Are the current changes including relevant documentation changes
- [ ] Do the current changes follow the same code style followed by other changes and our AGENTS.md files? 
- [ ] After any rebasing that was done, the changes still align with each other and don't introduce any dead code.

To analyze specific code sections and diffs, use @explorer. If you need to review against documentation, use @librarian. 


Output the final format as follows:
```
Status: "LGTM" | "Needs Work" | "Good, with minor nits"

Description:
* <Bullet point list that summarizes the current code review>

Improvements: 
* <Bullet point list of what needs to be improved>
```

Note: If it is **LGTM**, we do not need an *improvements* section. This should only be included for "Needs Work" or "Good, with minor nits"

Analyze these councillor reviews, and use the average of these reviews to generate the final review. 

## Statuses 

For each review, the following statuses are the final status we can give for a code review.

- **LGTM**: The changes cover the ticket to the tee. We successfully implemented what is detailed in the ticket. This is the idea end state after implementing a ticket. 
- **Good, with minor nits**: The changes more or less cover what is detailed by the ticket. However, there are some areas that could use light improvements (i.e. better code style practices, better tests, using one abstracted function over two separate ones). Ok to approve and merge, but useful to list out the nits to the approver. 
- **Needs Work**: Do not approve. The ticket is not fully implemented or is done to a level not satisfiable. There could be missing details or incorrect implementation. Either way, do not approve this for merging. 

## Review Comments

For the final aggregated review, we could have comments needed to move a code review to LGTM. 

If the status is not **LGTM**, store the comments in a file. The file will need to be stored in `<repo>/prompts/<milestone>/<story>/code-review-01.md`. If the file already exists, increment the sequential number. `code-review-02`
