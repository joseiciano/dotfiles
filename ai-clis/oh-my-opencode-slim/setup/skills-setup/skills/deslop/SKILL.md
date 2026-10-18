---
name: deslop
description: Reviews and rewrites generated prose to remove AI-writing tells, generic filler, promotional tone, canned structure, and markup/citation artifacts. Use when asked to review output, deslop text, polish AI-written copy, or avoid signs from Wikipedia:Signs of AI writing.
author: joseiciano
version: "1.0.0"
---

# Deslop

Use this skill to review text before sending, publishing, committing, or pasting. Goal: keep substance, remove patterns that read like unreviewed AI output.

## Default workflow

1. Identify purpose, audience, and format.
2. Scan for tells below.
3. Remove unsupported analysis, puffery, and generic conclusions.
4. Replace abstractions with concrete facts from context.
5. Simplify structure. Prefer direct sentences over ornate framing.
6. Preserve technical accuracy, citations, quotes, code, and required style guides.
7. Return either:
   - brief issue list + revised text, when reviewing provided prose
   - revised text only

## High-priority fixes

### Significance inflation

Remove claims that make ordinary facts sound historically important without evidence. Watch for: stands as, serves as, testament to, vital/significant/crucial/pivotal/key role, underscores/highlights its importance, reflects broader, symbolizes ongoing/enduring/lasting, contributes to, setting the stage for, evolving landscape, indelible mark, deeply rooted.

Fix by naming specific effect, actor, date, metric, or source-backed consequence. If no support exists, delete.

### Source theater

Remove source-counting prose that argues for notability rather than reporting facts. Watch for: independent coverage, local/regional/national media outlets, trade publications, profiled in, featured by, written by a leading expert, active social media presence, claims that sources "demonstrate significance" without saying what they report.

Fix by stating sourced facts directly. Let citations carry attribution unless attribution itself matters.

### Superficial analysis and promotion

Delete analytical gloss not grounded in evidence. Watch for: highlighting, underscoring, emphasizing, ensuring, reflecting, symbolizing, cultivating, fostering, enhancing, valuable insights, align with, resonate with, sentence-ending "-ing" phrases that add vague significance.

Replace marketing tone with neutral facts. Watch for: boasts, vibrant, rich, profound, showcasing, exemplifies, commitment to, natural beauty, nestled, in the heart of, groundbreaking, renowned, diverse array, gateway to, seamless, value-driven, world-class.

Fix with concrete facts and measurable descriptions. Avoid praise unless attributed and relevant.

### Vague attribution

Challenge unsupported group claims. Watch for: observers say, experts argue, critics note, industry reports suggest, several sources/publications, widely regarded, commonly viewed, often seen as, "such as" before lists pretending to be representative.

Fix by naming source, narrowing claim, or removing.

### Formula conclusions

Remove outline-like endings unless user asked for outlook/challenges. Watch for: "Despite these challenges...", "Future outlook", "Challenges and legacy", generic "continued growth/evolution remains uncertain" endings.

Fix by ending on last useful fact or concrete next step.

## Language tells

### AI-vocabulary clusters

Reduce clusters of: additionally, delve, key, crucial, robust, pivotal, intricate/intricacies, interplay, tapestry, landscape, bolster, foster, garner, showcase, meticulous/meticulously, enduring, valuable, underscore/highlight as verbs. One such word may be fine. Clusters are not.

### Plain verbs

Prefer plain "is/are/has" when accurate. Avoid inflated substitutes: serves as, stands as, marks, represents, boasts, features, maintains, offers, refers to, encompasses.

### Rhetorical templates

Avoid formulaic constructions: not just X but also Y, not X but Y, X rather than Y. Rewrite directly.

### Rule of three

Cut triplets used for rhythm instead of precision: three adjective strings or three abstract nouns. Keep only distinct, necessary items.

### Elegant variation

Do not swap terms just to avoid repetition. Reuse exact technical nouns when clarity matters.

## Formatting and artifacts

Review formatting for: unnecessary Title Case headings, overuse of boldface, inline-header bullet lists (`**Thing:** explanation`) when prose works better, em dash overuse, emoji as headings or bullet markers, tables used where bullets or prose are clearer, curly quotes in code/CLI/JSON/plain-text contexts, skipped heading levels, thematic breaks before headings.

Remove chatbot residue: "Of course!", "Certainly!", "I hope this helps", "Would you like...", "Let me know...", "Here is a...", "more detailed breakdown", knowledge-cutoff disclaimers, "as of my last update", "based on available information/search results" when not needed, placeholder brackets or fill-in templates left unresolved, hidden instructions, draft notes, or comments meant for the writer.

Use direct task-specific language.

## Markup and citation artifacts

When reviewing Markdown, wikitext, docs, or sourced prose, scan for: stray Markdown in non-Markdown contexts (`**bold**`, `# heading`, `1.` lists), broken wikitext/templates/categories, `turn0search0` and links to search-result placeholders, `contentReference`, `oaicite`, `oai_citation`, `attached_file`, `grok_card`, `attribution` / `attributableIndex` JSON fragments, `:::writing` blocks, nonexistent templates/categories, broken external links, invalid DOI/ISBN formats, DOI links pointing to unrelated papers, book citations missing page numbers when page-specific claims need them, unconventional or unused named references, `utm_source=` tracking links.

Fix obvious artifacts. Flag unverifiable citation problems rather than inventing replacements.

## Review output format

When user supplies text and asks for review:

```markdown
## Deslop findings

- [severity] Issue: specific quote or pattern. Fix: specific action.

## Revised text

...
```

Severity:

- `high`: unsupported claim, hallucinated citation/markup artifact, promotional overclaim
- `medium`: repeated AI-style pattern affecting trust
- `low`: style preference or minor polish

When user asks to rewrite only, skip findings and return revised text.

## Rewrite principles

- Prefer concrete nouns and verbs.
- Keep useful nuance; remove fake nuance.
- Use shorter sentences when meaning survives.
- Keep one idea per sentence.
- Use "because" only when cause is supported.
- Attribute opinions to named sources.
- Do not add facts not present in input/context.
- Do not make prose quirky to hide AI tone.
- Do not replace all formal language; fix excess, not expertise.

Before returning, ask:

- Does every significance claim have evidence?
- Could this sentence apply to hundreds of topics? If yes, rewrite or delete.
- Are any phrases there only to sound polished?
- Did formatting become simpler?
- Did citations or source claims stay honest?
- Would concise human reviewer write it this way?
