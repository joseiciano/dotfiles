---
name: review
description: Run a comprehensive AI review against current changes. Detect issue with code quality, thoroughness, security, performance, and documentation. 
permissions:
  bash: allow
  read: allow
  grep: allow
  glob: allow
  edit: deny
  external_directory:
    "~/dotfiles/opencode/.config/opencode/**": allow
---

Arguments Received: `$ARGUMENTS`

Run a comprehensive AI code review on the current branch's changes against `origin/main`.

## Input Arguments 

This command provides the following arguments:

- `ticket` (**OPTIONAL**): A path to the ticket that the current changes are implemented for. If no ticket was provided, assume there is none.  
- `description` (**OPTIONAL**): A description of what these changes are to do. **IF `ticket` IS NOT PROVIDED, THIS FIELD IS REQUIRED** 

## Review Steps

### Step 1: Gather Diff

1. Fill in the following variables 

- `TARGET_BRANCH` - `origin/main`
- `MERGE_BASE` - Compute merge base:
  ```bash
  git merge-base <TARGET_BRANCH>
  ```
- `CHANGED_FILES` - Gather list of changes files:
  ```bash
  git diff --name-status
  ```
- `DIFF_NUMSTAT` - Compute numstat for machine-readable line counts 
  ```bash
  git diff --numstat <merge-base> 
  ```
- `DIFF_STAT` - Compute stat for human-readable summary.
  ```bash
  git diff --stat <MERGE_BASE>
  ```

2. **Filter noise files**. From `CHANGED_FILES` and `DIFF_NUMSTAT`, exclude the following file patterns (they are not reviewable):
  - **Lock files**: `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `go.sum`
  - **Vendor Directories**: `vendor/*`, `node_modules/*`
  - **Minified Assets**: Files ending in `.min.js`, `.min.css`, `.bundles.js`
  - **Generated Files**: Paths containing `dist/`, `vendor/`

3. If there are no reviewable changes, prompt to user: "No reviewable changes detected." and **STOP HERE**. 

### Step 2: Gather Optional MR Context

If a `ticket` was provided, read it to extract information on what the final change is meant for. 

If `ticket` is unavailable, use the `description` the user provided. If this is not sufficient, or neither was passed in, prompt the user for more information. 

Store this information in the variable: `CHANGE_GOAL` using the following format:

```
GOAL: 
  - Bullet point list, 1-3 at most, of what this change is meant to do
```

### Step 3: Classify Files

Classify each reviewable file: 

| **File Type** | **Definition** |
| --- | --- |
| Code/Config | Any non-`.md` file (`.ts`, `.js`, `.py`, `.go`, `.sh`, `.yml`, `.json`, `.toml`, `.sql`, `.tf`, `.Dockerfile`, etc.) |
| Documentation | Any `.md` file |
| Deleted | Any deleted files in our list of changes. **Do not pass these to the reviewers** |


Keep this information in `CHANGED_FILES`. 

### Step 4: Assess Risk Tier

Using the total lines changed + updated file counts for review, classify the changes into a risk tier. 

| **Condition (evaluated in order)** | **Tier** |
| --- | --- |
| Any security-sensitive file detected OR > 50 files | **full** |
| <= 10 total lines changes AND <= 20 files | **trivial** | 
| <= 100 total lines changed AND <= files | **lite** |
| Everything else | **full** |

#### Security-Sensitive File Detection

A file is security-sensitive if:
  - Path contains `auth/`, `security/`, `secrets/`
  - Filename contains `.env`

#### Final Output

Print the final tier assessment using this example format: 

"**Risk Tier**: **lite** (47 lines, 8 lines, no security-sensitive files)"

### Step 5: Spawn Subagent Reviewers

#### Parallel Subagent Spawning 

Based on the risk tier, dispatch reviewers **as their own, separate subagent.** Spawn all subagents for a tier in a single message so they run concurrently. 

**If parallel sub-agent spawning is supported (i.e. Opencode)**: Run the subagents in parallel and wait for all to complete.

**If only sequential execution is available**: Run the subagents in the following order: `code_quality` -> `security` -> `performance` -> `documentation`.

#### Subagents to Spawn

Apply these rules/subagents in order. Earlier rules take precedence. **Only spawn the subagents that the tier is for. Do not overextend.** 

**Special Cases (evaluated before the tier table):**

| Condition | Subagents to run |
| --- | --- |
| All changed files are `.md` (docs-only diff) | Only spawn a @reviewer-documentation | 
| Any `.md` file is changed alongside code files | Always include @reviewer-documentation, regardless of tier |

**Tier defaults (applied after special cases):**

| Tier | Subagents to run |
| --- | --- |
| `trivial` | @reviewer-code, @reviewer-documentation, @reviewer-code-quality |
| `lite` | @reviewer-code, @reviewer-documentation, @reviewer-code-quality, @reviewer-agents-md |
| `full` | @reviewer-code, @reviewer-documentation, @reviewer-code-quality, @reviewer-agents-md, @reviewer-security, @reviewer-performance |


### Step 6: Synthesize Final Review

After all subagents return their results, coordinate the final review. 

**If all subagents found 0 issues, skip the judge pass.** Go directly to output. 

From each reviewer subagents review block, extract the following:
- `issue_count` -> integer 
- `summary` -> string 
- `recommendation` -> one of the five values defined in the `## shared structure` section
- `items` -> array of `{ tag, text }` (tag is the sole blocking determinant)
- `content` -> detailed findings

Review all findings. Apply the following:

  1. **Deduplication**: If the same issue is flagged by multiple subagents, keep ONE copy in the domain section where it best fits. Remove duplicates from other sections. 
  2. **Re-categorization**: Move misplaced findings to the correct section (e.g. a security issue is reported by a @reviewer-code-quality).
  3. **Reasonableness filter**: Drop findings that are: 
    - Speculative or theoretical without evidence in the actual diff. 
    - Nitpicky style preferences that linters handle. However, if the code changes generate linter errors based on what we have defined, that is ok. 
    - Issues in unchanged code
    - "Consider using library X"-style suggestions
    - Micro-optimizations without real-world impact. 

#### Overall Decision

**Bias tower approval.** Withhold only when the change is genuinely unsafe to merge. 

| Condition | Decision | 
| --- | --- |
| Any `BLOCKING` item | `significant_concerns` |
| => 3 `WARNING` items, OR a `WARNING` with explicit production/safety implact | `minor_issues` |
| 1-2 `WARNING` items, no production/safety impact | `approved_with_comments` |
| Only `INFO`/`SUGGESTION`/`QUESTION` items | `approved_with_comments` |
| No findings | `approved` |

| **Condition** | **Decision** |
| --- | --- |
| All clean, or only trivial suggestions | **Approved** |
| Only suggestion-severity items | **Approved with Comments** |
| Some warning items, no production risk, no criticals | **Approved with Comments** |
| Any critical item, OR production safety/security risk, OR significant standards violation | **Significant Concerns** |
| Multiple warnings suggesting a risk pattern, OR one warning with clear production impact | **Minor Issues** |

When in doubt, choose the less severe level. Errors/timeouts do **NOT escalate the decision. 

Write a concise `reason` (1-2 sentences) specific to what drove the decision. 

## Step 6: Emit Final Review

Print the final review in this format: 

```
## AI Code Review: <Decision (Approved | Approved with Comments | Minor Issues | Significant Concerns)>

**Reason**: <1-2 sentence justification>

**Risk Tier**: <tier>
**Reviewers**: <count>
**Changed Files**: <count>
**Changed Lines**: +X -Y
**Review generated from diff of `BASE_SHA` .. `HEAD` against `<TARGET_BRANCH>`.**

---

### Code Quality
**Status**: <lgtm | issues_found | error>
**Recommendation**: <value>
**Summary**: <one sentence>

<detailed findings>

--- 

### Security
[same structure]

--- 

### Performance
[same structure - omit section entirely if pass was not run]

--- 

### Documentation
[same structure - omit section entirely if pass was not run]

--- 

### AGENTS.md
[same structure - omit section entirely if pass was not run]

```

Each finding must start with a severity tag: `[BLOCKING]`, `[WARNING]`, `[INFO]`, `[SUGGESTION]`, `[QUESTION]`, followed by the following (presented in order):
  - File:line reference
  - What is wrong
  - How to fix it
Do NOT post this output elsewhere except this conversation as well as a new file in `prompts/code_review/code_review_x.md`, where `x` starts at 1 and increments if already exists. 
