---
name: commit-pull-request
description: Formatting and guidelines for creating commits and github pull requests
---

## Goal
- Prepare clean commits
- Create pull requests with the correct title/description format
- Verify all required checklist items before finalizing

## Behavior
- Be concise and execution-focused.
- If there is ambiguity (ticket id, story file, rebase conflict handling), ask for confirmation.
- Keep changes traceable and aligned with the final PR description.

### Tools to Use

**Always** use git cli and Github cli to get the information needed for the pull request. **DO NOT USE ANY OTHER TOOL (i.e. MCPS) TO GET THIS INFORMATION**

## Workflow
1. Inspect git status/diff/log to understand pending changes.
3. Create clear, descriptive commit message title/body for each commit.
4. Create PR title and description using the required format/template from the skill.
5. Confirm final output includes what was committed, PR link, and verification status.

### Output Format
For the output format you send back to the user, reference the following: 

```markdown
## Summary

(What was committed and prepared for the PR)

## Commits
- Commit SHA(s)
- Commit Message(s)

## PR
- PR Title
- PR URL

## Verification
**Main Synced/Rebased**: Yes | No + note
**Lint**: Pass/fail
**Stories Status Updated**: Yes | No
```

## Git Commits

### Commit Standards

- **Clarity**: Even though commits are squashed on merge, each individual commit in the PR must have a clear, descriptive title and body.
- **Verification**: Keep commit history understandable so individual changes can be verified against the final pull request description.
- **Simple**: Commits should be simple, covering a singular feature modification (i.e. if multiple files are needed to implement a route that is fine, but having multiple routes should be under different commits). 

### Commit Example

- **Title**: Use a concise, descriptive commit title (include ticket reference when applicable).
- **Body**: Keep the body structured so the intent and verification are easy to review.

```text
[2-1.4] Implement authentication API routes

## What
- Added sign up route
- Added sign in route
- Added sign out route

## Why
- Users need to authenticate with their own accounts
- Enables account-specific profile information

## Testing
- Added integration tests
- Added unit tests

## Documentation
- Updated OpenAPI specification
```

## Pull Requests

### General Format

- Use concise bullet points. 1-2 sentences at most per point. If you need more, create a new bullet point. 
- Be explicit about what was done.
- Do not skip sections.

#### Required PR Title Format

- **Format**: `[MILESTONE:TICKETID] Short description of changes`
- **Requirement**: The title must always include the relevant ticket number or ticket name.

Example:

```text
[milestone-2:1.4] Implement API Route
```

#### Required PR Description Sections

Every pull request description must include all sections below:

1. **WHAT**: A clear and concise explanation of the changes introduced.
2. **WHY**: The rationale behind the changes and the problem solved.
3. **TESTING**: New tests added and all testing performed (manual and/or automated).
4. **DOCUMENTATION**: Any updates or additions made to project documentation.


##### PR Description Template

Use this template exactly:

```markdown
## What
- <change 1 - 1-2 sentences at most>
- <change 2 - 1-2 sentences at most>

## Why
- <reason 1 - 1-2 sentences at most>
- <reason 2 - 1-2 sentences at most>

## Testing
- <tests added>
- <manual/automated verification>

## Documentation
- <docs updated>
```

### Pull Request Checklist (ALWAYS)

Before creating or finalizing a pull request, ensure all items are complete:

- [ ] Pull the latest changes from `main` and handle rebase errors.
  - If unsure how to resolve a rebase/conflict, ask for confirmation before proceeding.
- [ ] `pnpm lint` returns no warnings or errors.
- [ ] In the related ticket file under `@stories`, set `status` to `done`.

## Merge Strategy

- **Squash and Merge**: All commits in a pull request must be squashed into a single clean commit when merged into `main`.

