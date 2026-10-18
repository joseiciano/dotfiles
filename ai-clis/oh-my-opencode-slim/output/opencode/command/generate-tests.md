---
description: Plan tests to support the implementation of a new features, enabling test driven development.
agent: orchestration
permissions:
  bash: allow
  read: allow
  grep: allow
  glob: allow
  edit: allow
  external_directory:
    "~/dotfiles/opencode/.config/opencode/**": allow
---

Arguments Received: `$ARGUMENTS`

## Pre-requisites

Analyze and under the plan file given. A deep and thorough understanding of the codebase and plan is needed.

- [ ] Use @council to generate viewpoints on understanding the codebase
- [ ] Use @oracle to track what is needed for test coverage of our current ticket
  - [ ] Use @explorer to dig through the codebase
  - [ ] Use @librarian to dig through documentation
- [ ] Load the TDD skill to understand what we are looking for in test coverage

## Test Generation

Decide what tests are needed to fully support the implementation of the ticket. We are working with a test-driven development approach, so make sure we cover all important cases. 


