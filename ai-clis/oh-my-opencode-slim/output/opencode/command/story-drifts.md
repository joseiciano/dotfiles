---
description: analyze stories to see if there are any drifts
agent: Orchestration
---

Arguments Received: `$ARGUMENTS`

## Input

- `stories`: One or more story tickets


## What to Look For 
- Referencing files that do not exist
- Referencing logic that is not the current implementation (i.e. using REST when implementation is RPC). 
- Using technologies that are not in the current implemented tech stack
- Referencing the completion of stories/features that are not implemented as of this story. 

## Drift Resolution

For any drifts, bring it up the user in the following way:

```markdown
# Story Drifts

## <File>

### Drift: <Short 1 sentence on drift>

**Story Says**: 
  - <Point where story file drifts>

**Documentation Says**: 
  - <What documentation says>

**Drift**:
  - <How this is a drift>
```
