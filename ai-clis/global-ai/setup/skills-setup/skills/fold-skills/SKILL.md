---
name: fold-skills
description: Analyze two or more skills to see if they overlap, and fold them into one entry point (a merged skill or a wrapper skill with a router) to reduce redundancy and keep the root goal of the skills consistent.
disable-model-invocation: true
---

# Fold Skills

Analyze two or more skills to reduce redundancy and fold them into one entry point.

If the skills cover similar fields, analyze what is the best route to resolve this. The end result is one entry point covering all fronts: either a single merged skill, or a wrapper skill that routes to each original skill.

## Prerequisite: Argument Parsing

Arguments Received: `$ARGUMENTS`

Parse the following from `$ARGUMENTS`:
- `$SKILLS_LIST`: A list containing the list of skills we are to analyze. 

It is **required** that `$SKILLS_LIST` contains two or more skills. 

If it does not, stop here and prompt the user: 

```md
To use this skill, we require two or more skills to be passed. 
```

## Guideline 

### Step 1: Analyze given skills

Analyze the given skills and understand what they cover. Do they cover the same ground (i.e. are they both talking about the same cli tool?) Think specifically on the domain. 

Also label each skill by its **kind**. Step 2 uses this label.

| Kind | What it looks like |
| --- | --- |
| procedure | Step-by-step workflow the agent executes, with checklists and guardrails (e.g. "provision a DB, write `.env`, report the claim URL") |
| reference | Knowledge or an index of docs the agent looks things up in (e.g. "connection methods: see link") |
| standard | Rules and best practices applied while writing or reviewing (e.g. "always paginate queries") |

#### Example
**The following examples would be considered redundant:**
- Two skills talking about best practices in a framework
- Two skills talking about how to use Postgres
- Multiple skills covering the same cli that could be covered under one wrapper skill containing this information in references that is routed to (i.e. how the `cloudflare` skill)
- Two skills covering different products of the same provider (i.e. a provider's platform guide and a procedure for one of its products)

**The following example would not be considered redundant:**
- One skill is about how to use a database, and the other is a skill for using a provider of the database 
- Both skills are used in a domain (backend), but cover different parts of it (i.e. one covers api design, the other covers controller-service-repository patterns)


#### Result

- If some skills are found to not be redundant, stop processing them. From here on out remove them from `$SKILLS_LIST` and act as if they were not in consideration. 
- If all skills are found to not be redundant, stop here entirely. Prompt the following to the user: 

```md
All skills were found to not be redundant. Stopping here.

Skills Analyzed:
- Bullet point list of skills
```

- If two or more skills were found to be redundant, continue to the next step. 

If we made it here, prompt the following to the user:

```
Skills found to be redundant:
- Bullet point list of skills in the form (skill1:skill2:skill3:...skilln)

Skills found not to be redundant:
- Bullet point list of skills
```

### Step 2: Consider Folding

For the redundant skills, decide the **shape** of the fold. This is an explicit decision, not a default.

**Merge** into one skill only when both are true:
- All skills are the same kind (from Step 1).
- They cover the same tool or topic (i.e. two "Postgres best practices" skills).

**Wrapper** when any of these is true:
- The skills differ in kind (i.e. one procedure and one reference). Merging a procedure into a reference skill buries the steps under topic headings the agent skims past.
- They share a domain or provider but cover distinct products or tools under it.

Do not fold one existing skill into another just because the existing one already acts as a router. If the kinds differ, create a neutral wrapper named after the domain (i.e. `neon`) and make each original skill a sub-reference under it.

Also consider:
1. We want to cover all the information that is in all skills. Ideally we do not lose anything unless it is found to be incorrect or deprecated. 
2. We want at the end one entry point that is best for this.
3. Rules shared by all skills belong in the wrapper's `SKILL.md`, not duplicated in each reference.

Bring up the final recommendation to the user. Wait for their confirmation before continuing. Prompt in the following format:

```md
Skill Analysis: 

## <final-skill-name> - Folds <skill1>, <skill2>, ...
**Shape**: merge | wrapper - <one-line reason: kinds + domain>
**Recommendation**:
  - Bullet point list of changes

Please Confirm if you want these changes to occur. 
```

For the bullet point list, keep it simple and concise, as if you were explaining to a well-knowledged senior engineer who is busy with multiple other projects. 

### Step 3: Perform Folding

After confirmation, perform folding of the skill. 

#### Merge

Combine the content into the surviving skill's `SKILL.md` (or its `references/`), merge the trigger phrases into its `description`, and delete the other skill directories.

#### Wrapper

Create the wrapper with this layout (same pattern as the `cloudflare` skill):

```
<wrapper>/
  SKILL.md                              # router
  references/
    <original-skill>/guide.md           # the original SKILL.md body
    <original-skill>/<other-files>.md   # the original's references, kept next to its guide
```

When building it:
- Strip the frontmatter from each moved `SKILL.md`. Only the wrapper has frontmatter.
- Fix relative links inside moved files so they resolve from their new location.
- In the wrapper's frontmatter, merge every original's trigger phrases into `description`, and add a `references:` list naming each sub-reference.
- In the router, give each route its "use when" conditions and its kind (i.e. "this route is a procedure; follow its workflow step by step").
- Put rules shared across the originals in the wrapper's `SKILL.md`.

#### Both shapes

- Delete the original skill directories. Use `mv`, not `git mv`. The skills directory may be untracked, and `git mv` fails on untracked files.
- Search `ai-clis/` (excluding `output/` directories) for the old skill names. Update the skill tables in `global-ai/setup/agent-setup/agents-shared/*.md` and the `skills:` lists in the `claude:`, `opencode:` and `omp:` blocks of `global-ai/setup/agent-setup/agents/*.md`. Report matches in other harnesses (i.e. `oh-my-opencode-slim`) to the user instead of skipping them silently.

#### Generate output

From `ai-clis/`, run:

```bash
make install-claude
```

Skills are built once, into `global-ai/output/claude/skills/` (linked as `~/.claude/skills`); opencode and oh-my-pi read them from there.

Then verify the new skill exists in `global-ai/output/claude/skills/` and that the old skills are gone.
