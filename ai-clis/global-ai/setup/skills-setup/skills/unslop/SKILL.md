---
name: unslop
description: "Cut AI tells from prose: docs, READMEs, PR descriptions, commit messages, and chat replies. Use for 'unslop' or when writing or editing text. For AI-generated patterns in code, use code-simplification."
---

# Unslop

Edit text to remove AI patterns. Scan for the patterns below, then rewrite. Preserve meaning and match the intended tone.

## Patterns to detect and fix

Rule numbers are stable ids that other skills cite. A removed rule leaves a gap.

### Content

3. **Superficial -ing phrases.** "highlighting...", "ensuring...", "reflecting...", "showcasing...", "fostering...". Delete or expand with real sources.
5. **Vague attributions.** "Experts believe", "Industry reports suggest", "Some critics argue". Name the source or delete.
34. **Significance inflation.** "stands as a testament to", "played a pivotal role", "underscores its importance", "reflects broader trends", "left an indelible mark", "setting the stage for". Ordinary facts dressed as historic ones. Name the specific effect, actor, date, metric, or source-backed consequence. If no support exists, delete.
35. **Source theater.** Prose that counts coverage instead of reporting facts: "received independent coverage", "profiled in national media outlets", "featured by trade publications", "written by a leading expert", claims that sources "demonstrate significance" without saying what they report. State the sourced facts directly and let citations carry attribution, unless attribution itself matters.

### Language

7. **AI vocabulary.** Additionally, crucial, delve, enduring, enhance, fostering, garner, interplay, intricate, landscape (abstract), pivotal, showcase, tapestry (abstract), testament, underscore, vibrant. Replace with plain words.
8. **Fancy ways to say "is".** "serves as", "stands as", "boasts", "features". Say "is" or "has".
9. **"Not just X, but Y."** State the point directly instead.
10. **Rule of three.** Don't force ideas into groups of three. Use the natural number.
11. **Synonym cycling.** Protagonist, main character, central figure, hero all in one paragraph. Pick one, repeat it.
12. **False ranges.** "from X to Y" where X and Y aren't on a meaningful scale. List topics directly.

### Style

13. **Em dash overuse.** Avoid em dashes entirely. Use periods or commas only (no parentheses, no en dashes, no hyphen-as-dash substitutes). If a thought needs separation, end the sentence or use a comma.
14. **Colon overuse.** Colons are fine before a list or example, not as mid-sentence connectors. "If you're coming from traditional automation: instead of registering event handlers, you describe conditions" adds nothing with the colon. Rewrite to let the point stand on its own without comparison framing. "Describing when the scheduler should fire works best as plain English." Same meaning, no crutch punctuation.
15. **Boldface overuse.** Don't bold every proper noun or acronym.
16. **Inline-header lists.** The tell is a bold label and colon that restates the line: "**Performance:** Performance improved...". Convert those to prose. A bold lead-in that ends in a period, names the item, and is followed by genuinely new detail ("**Schema in TypeScript.** Tables live in one file.") is fine, not a tell.
17. **Title case headings.** Use sentence case.
18. **Decorative emojis.** Remove from headings and bullets.
19. **Curly quotes.** Use straight quotes.

### Communication artifacts

20. **Chatbot phrases.** "I hope this helps!", "Let me know if...", "Of course!", "Certainly!", "Found the smoking gun!" Remove.
22. **Sycophantic tone.** "Great question! You're absolutely right!" Respond directly.

### Filler

23. **Filler phrases.** "In order to" becomes "To". "Due to the fact that" becomes "Because". Delete "It is important to note that".
24. **Excessive hedging.** "could potentially possibly be argued that it might" becomes "may".
25. **Generic conclusions.** "The future looks bright." State specific plans or facts.

### Jargon

26. **Abstract metaphor nouns.** Substrate (base), wedge, wedge in (add), vector (way, method), locus, vantage, nexus, primitive as a noun, harness as a metaphor, surface as in "API surface", bedrock, scaffolding as a metaphor, modality, paradigm, gold-plating (more than the job needs), ratchet as a metaphor (the mechanism's real name, or a limit that only tightens), evacuate for moving code (move out), endgame (the last phase), north star, flywheel. These read as technical but usually have a plainer concrete word. Pick the concrete word.

### Markup and citation artifacts

36. **Tool residue and placeholders.** `turn0search0` and links to search-result placeholders, `contentReference`, `oaicite`, `oai_citation`, `attached_file`, `grok_card`, `attribution`/`attributableIndex` JSON fragments, `:::writing` blocks, unresolved fill-in brackets or templates, knowledge-cutoff disclaimers ("as of my last update", "based on available search results" when not needed), hidden instructions or draft notes meant for the writer. Remove.
37. **Broken or dishonest citations.** Stray Markdown in non-Markdown contexts (`**bold**`, `# heading` in wikitext or plain text), broken templates, categories, or external links, invalid DOI/ISBN formats, DOI links pointing to unrelated papers, book citations missing page numbers when page-specific claims need them, unconventional or unused named references, `utm_source=` tracking links. Fix obvious artifacts. Flag unverifiable citation problems instead of inventing replacements.

### Plain speech

27. **Say what it does, not how it feels.** "the database stays close at hand", "SQL you can read", "types that follow your schema" name a feeling. The fix names the mechanism or a number: "`.toSQL()` returns the exact string sent to the database", "a column rename fails the build". Ask what the sentence tells the reader to do or know, then write that. If you can't restate it as a concrete instruction, fact, or number, cut it. One more check: if the sentence could appear unchanged in another project's docs, it says nothing about this one. Cut it.
28. **Shorten or split dense sentences.** If the reader has to backtrack to parse a sentence, break it in two or drop clauses. One idea per sentence.
29. **Active voice.** Prefer it. Catch "is/are/was/were + past participle" and name the actor: "queries are validated" becomes "the compiler validates queries", "the file is parsed by the loader" becomes "the loader parses the file". Passive is fine only when the actor is unknown or genuinely doesn't matter.
30. **Cut adverbs, or use a stronger verb.** "runs quickly" becomes "is fast" or the number, and "significantly improves" becomes the measured delta. An adverb propping up a weak verb means the verb is wrong.
31. **Prefer the plain word.** "utilize" and "leverage" become "use", "facilitate" becomes "help", "numerous" becomes "many", "in the event that" becomes "if". The fancier synonym is rarely clearer.
32. **Mannered prose.** Metaphor or flourish where a literal phrase exists: aphorisms ("wire it or delete it"), rhetorical fragments for effect, personified code ("the plan holds it"), figurative verbs ("rides along", "stands on"), stock framing phrases. "A dial worth turning" becomes "a parameter worth varying". Say what you mean. Rule 26 covers the metaphor nouns.
33. **Over-compression.** Dropped articles, verbless fragments, symbol-speak, and abbreviations that make the reader decode instead of read. "Parser rejects bad date → exit 2, no write" becomes "The parser rejects a bad date, exits with code 2, and writes nothing." Write whole sentences with their articles and verbs, and spell out arrows and abbreviations.

## Review output format

When the user supplies text and asks for review:

```markdown
## Unslop findings

- [severity] Issue: specific quote or pattern. Fix: specific action.

## Revised text

...
```

Severity:

- `high`: unsupported claim, hallucinated citation or markup artifact, promotional overclaim
- `medium`: repeated AI-style pattern affecting trust
- `low`: style preference or minor polish

When the user asks to rewrite only, skip findings and return revised text.

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

