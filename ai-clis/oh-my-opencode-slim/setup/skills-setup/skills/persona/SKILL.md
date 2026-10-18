---
description: Create detailed personas for a given problem
---

**Anti-Patterns (What This Is NOT)**
- **Not validated research:** Don't treat it as fact—it's a hypothesis
- **Not a replacement for user research:** Use it to *guide* research, not avoid it
- **Not demographic data alone:** Age and location don't explain behavior
- **Not permanent:** Proto-personas should evolve as you learn

**Patterns ("What This Is")**
- **Speed:** Align teams quickly without waiting for months of research. Helps us quickly kick off product development with a good clear goal. 
- **Focus:** Provides a shared reference point for "who we're building for"
- **Hypothesis framing:** Makes assumptions explicit, which can then be validated
- **Prevents generic design:** "Design for everyone" = design for no one

**Why Use Personas**
- Early-stage product development (before extensive user research)
- Kicking off a new feature or pivot
- Aligning stakeholders on target users
- Identifying research gaps (who do we need to interview?)

## Persona Sections

1. **Gather Relevant Information**
Collect the following:
- **Analytics:** Usage data, demographics, behavioral patterns
- **Market data:** Industry reports, competitor user bases
- **Stakeholder insights:** Sales/support/CS teams who interact with users
- **Product context:** What problem are you solving? 

**If missing context:** Don't fabricate—note gaps and plan research to fill them. Prompt the user if more information is needed. 

2. **Create Persona Identity**
- Give the persona an **alliterative, memorable name** (makes it easier to reference).

```markdown
### Name
- [Alliterative name, e.g., "Manager Mike," "Startup Sarah," "Enterprise Emma"]
```

**Quality checks:**
- **Memorable:** Can the team recall it easily?
- **Not generic:** Avoid "User 1" or "Persona A"

3. **Think of the Persona's Background**:
Describe who this person is in the real world.

```markdown
### Bio & Demographics
- [Age range]
- [Geographic location]
- [Social status (married, single, family, etc.)]
- [Online presence (active on LinkedIn, avoids social media, etc.)]
- [Leisure activities]
- [Career status (job title, industry, seniority)]
```

**Quality checks:**
- **Behavioral, not just demographic:** Don't stop at "30-40 years old, lives in SF"—add "Works remotely, active in Slack communities, juggles 3 side projects"
- **Context-relevant:** Only include demographics that influence product decisions

**Example:**
- "35-45 years old, lives in urban areas (NYC, SF, Austin)"
- "Director-level at mid-sized tech companies (50-500 employees)"
- "Active on LinkedIn and Twitter, attends 2-3 conferences per year"
- "Married with young kids, values work-life balance"
- "Plays rec sports on weekends, listens to business podcasts during commute"

4. **Capture Their Voice**
Use real or representative quotes that reveal how they think and speak.

```markdown
### Quotes
- "[Quote 1 revealing what they say, feel, or think]"
- "[Quote 2 revealing frustrations or motivations]"
- "[Quote 3 revealing attitudes or beliefs]"
```

**Quality checks:**
- **Authentic:** Use real quotes from interviews/support tickets if available
- **Revealing:** Quotes should expose mindset, not just facts ("I need better tools" is weak; "I'm drowning in manual work and can't focus on strategy" is strong)

**Example:**
- "I spend 10 hours a week in status meetings that could be emails."
- "I'm tired of tools that promise automation but require a developer to set up."
- "My team expects me to have answers immediately, but I'm constantly searching for data."

5. **Document Their Context**
What problems or frustrations does this persona experience? 

```markdown
### Pains
- [Pain point 1 related to the problem space]
- [Pain point 2 related to the problem space]
- [Pain point 3 related to the problem space]
```

**Quality checks:**
- **Specific:** "Frustrated with tools" is vague; "Spends 3 hours/week manually copying data between tools" is specific
- **Related to your product:** Focus on pains your product could address

What behaviors, actions, or outcomes are they pursuing?

```markdown
### What is This Person Trying to Accomplish?
- [Behavior or outcome 1]
- [Behavior or outcome 2]
- [Behavior or outcome 3]
```

**Quality checks:**
- **Observable:** Can you see this behavior? ("Get promoted" is internal; "Deliver projects 2 weeks ahead of schedule" is observable)
- **Outcome-focused:** Not tasks ("use dashboards") but results ("make data-driven decisions faster")

What are their wants, needs, dreams?

```markdown
### Goals
- [Goal 1: want, need, or dream]
- [Goal 2: want, need, or dream]
- [Goal 3: want, need, or dream]
```

**Quality checks:**
- **Short-term and long-term:** Include tactical goals ("ship feature by Q2") and aspirational goals ("become VP within 3 years")
- **Personal and professional:** "Spend more time with family" can be as relevant as "increase team productivity"

6. **How We Help**: 
Think of our product and solution. How exactly does our solution help them alleviate their pain points. 

```markdown
### How We Help
- We provide x that helps them in case of (scenario)
```

## Examples

```markdown
### Name
- Manager Mike

### Bio & Demographics
- 35-42 years old, lives in urban/suburban areas (Chicago, Seattle, Austin)
- Director of Product at mid-sized B2B SaaS companies (100-500 employees)
- Married with 2 kids, commutes 30 min by car, values work-life balance
- Active on LinkedIn and ProductHunt, attends 1-2 PM conferences per year
- Reads PM blogs/newsletters (Lenny's, Stratechery), listens to podcasts
- Plays rec basketball on weekends

### Quotes
- "I spend more time in status meetings than actually building product."
- "My CEO asks me for data I don't have, and it takes 3 days to get it from engineering."
- "Every tool promises to save time, but they all require a week of onboarding."

### Pains
- Spends 10+ hours/week in status meetings and writing updates
- No single source of truth for product metrics—data is scattered across tools
- Pressure to ship faster, but team is stretched thin

### What is This Person Trying to Accomplish?
- Deliver roadmap milestones on time without burning out the team
- Make data-driven prioritization decisions in real-time
- Communicate progress to execs without manual reporting overhead

### Goals
- Be seen as a strategic thinker, not just a feature factory manager
- Get promoted to VP of Product within 2 years
- Spend more time with family (leave work by 6pm)

### Attitudes & Influences
- **Decision-Making Authority:** Can approve tools up to $15k/year; needs VP/CFO approval above that
- **Decision Influencers:** Peer PMs in Slack communities, former colleagues, analyst reports (Gartner)
- **Beliefs & Attitudes:**
  - Skeptical of tools that require developer setup
  - Values ease of use over feature depth
  - Prefers tools that integrate with existing stack (Jira, Slack, Figma)
  - Willing to pay more for great UX and support
```

**Why this works:**
- Specific demographics tied to behavior (not just "35-42")
- Quotes reveal real frustrations (not generic platitudes)
- Pains are measurable and specific
- Goals include professional and personal motivations
- Decision-making context is clear

---

## Example 2: Bad Proto-Persona (Too Generic)

```markdown
### Name
- John

### Bio & Demographics
- 30-50 years old
- Lives somewhere
- Works in tech

### Quotes
- "I want better tools."

### Pains
- Tools are bad

### What is This Person Trying to Accomplish?
- Use good software

### Goals
- Be productive

### Attitudes & Influences
- **Decision-Making Authority:** Maybe
- **Decision Influencers:** People
- **Beliefs & Attitudes:** Likes good things
```

**Why this fails:**
- Age range is too broad (20-year span)
- No behavioral context ("works in tech" = meaningless)
- Quotes are generic ("better tools" = every persona ever)
- Pains are vague ("tools are bad" = not actionable)
- No specific goals or influences

**How to fix it:**
- Narrow demographics: "35-45, Director-level, B2B SaaS"
- Add behavioral details: "Remote-first, active in PM communities"
- Use real quotes: "I spend 5 hours/week chasing down status updates"
- Specify pains: "No visibility into what engineering is building"
- Define goals: "Get promoted to VP within 2 years"
