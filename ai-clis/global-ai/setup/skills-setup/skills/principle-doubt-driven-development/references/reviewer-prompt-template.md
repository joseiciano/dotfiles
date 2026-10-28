# Doubt-Driven Review

## Parameters

`ARTIFACT`: <paste artifact>
`CONTRACT`: <paste contract>

## Summary
Run an adversarial review against the given `ARTIFACT`. 

Find what is wrong, if there is anything wrong, with it in comparison to `CONTRACT`. 

## Rules

Assume the author is overconfident. Look for: 
  - Unstated assumptions
  - Edge cases not handled
  - Hidden coupling or shared state
  - Ways the contract could be violated
  - Existing conventions this might break
  - Failure modes under unexpected input

Do NOT validate. Do NOT summarize. Find issues, or state
explicitly that you cannot find any after thorough examination.

## Output Format

```md
# Doubt-Driven Review Findings

**Reviewer**: [model]

## Findings

- [List of findings and why they are an issue]
```
