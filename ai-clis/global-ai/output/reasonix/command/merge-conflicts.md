---
description: Handle merge conflicts for a current pull request. 
agent: orchestration
---
Pull from main and handle merge conflicts.

**Agents**:
- Use @explorer to analyze the changes we have conflicts with. 
- Use @oracle to decide the best path forward with resolving merge conflicts
- Use @fixer to handle the actual selection, or any manual selection that is needed if the solution requires parts of both hunks. 

**Goals**:
Do not focus on just quick and easy rebasing solutions. Analyze the current changes and the base changes, 
then see what would be the best solution based on the story descriptions. If there are any questions on this,
ask first before changing. 

Final output should be a summary of what was changed, in the format:

```
File: <file>
Original: <original hunk>
Final: <final hunk>

Changes: <Summary of what was done to resolve this and get to the "final" hunk state>
```
