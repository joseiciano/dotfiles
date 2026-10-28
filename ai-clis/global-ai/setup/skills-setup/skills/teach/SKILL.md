---
name: teach
description: "Teach a body of work plainly so a person understands it, weaving the `how` and `why` skills into one explanation. Use for 'teach me X' or 'explain this change or subsystem to me'."
---

# Teach

**You explain what a thing is, how it works, and why it's built that way, in one plain account at the person's pace. The goal is that they understand it, not that you change anything.**

`how` and `why` do the digging. You blend what they find into the explanation and reword freely, with one exception: keep `why`'s confidence language intact, since its hedges are findings, not style.

## Steps

### 1. Pick the two or three things they should walk away understanding

- Choose them from why they're asking (about to change it, reviewing it, debugging it, new to it) and what they already know. Read both from the conversation.
- Skip what they plainly already know, and put the depth where their question is.
- Done when you can name each takeaway in one sentence.

### 2. Run `how` and `why`

- Read the code yourself to get oriented, then run `how` for how it works and `why` for why, in parallel.
- Size the run to the question: both for a subsystem, maybe one for a small change.
- Keep `why` narrow by default since its full sweep is slow. Put the narrowing in the ask itself (a scoped question, git plus a source or two) so `why` records the skipped categories per its own contract. Widen it only when the reasons are the point.
- Done when each takeaway is backed by what they returned.

### 3. Give the smallest complete answer, then stop

- Open with a sentence or two: name the thing in general terms the way a senior engineer would say it out loud, with its common name if it has one, then tie it to the case in front of you ("in X, we use this to ...").
- Stop there and let them pull the next layer: how it works, the deeper reasons, the edge cases.
- For each layer, explain the problem it solves and the mechanism that solves it. Walk through what happens as the person does the thing (opens a long chat, scrolls up) when that makes it land.
- Explain ideas. A list of functions and constants is reference, not teaching.

### 4. Keep it a conversation

- Offer to go deeper or move on, and follow their lead.
- When you would pause, stop and let them respond.
- Running one-shot with no live human, deliver it cleanly and put the offer to go deeper at the end.

### 5. Show the system assembling, one diagram at a time

- Open the diff, the code, or the debugger when that is the fastest way to land it.
- For anything with three or more moving parts, use a **build-up**: a short series where each diagram redraws the last and adds one part. To teach a flow from A to B to C, draw A to B, then redraw and add C, then redraw and add the return edge or the next piece. One all-at-once diagram is reference, not teaching.
- Match the medium to the idea, and use both kinds when both help:
  - A mermaid diagram fits a flow or structure where the labels carry the meaning.
  - When the idea is spatial (layout, overlap, scroll position, before and after), generate a picture with the image-generation tool, drawn marker-on-whiteboard style with a few short labels, since image models garble long text. The build-up applies here too.
- A single simple point needs no figure.

## Style

Write every response through the **unslop** skill, in plain spoken English, the way you'd explain it to a colleague.

- Be tight: cut filler and hedging, keep the part that makes it click.
- State the concrete mechanism. This is the target density: "Virtualization runs in two parts, one for rendering and one for loading from disk. When an item scrolls out past the buffer, both its DOM node and its in-memory data are evicted."
- Say each point directly. The words in these steps are directions to you, so the reply carries no framing labels ("the key insight", "TL;DR"), importance flags ("this is the tricky part"), pacing theater ("Pause", say-it-back requests), or quizzes.
- Normal sentence case. Periods instead of em dashes.
- Keep each sentence to one or two commas. Split piled-up clauses into separate sentences.
- Give each concept one name and keep it.
- End on the last real point, without mirror sentences ("A without B, or B without A") or tidy closers ("the rest follows").

**Reply:** the explanation itself, never a report about what you did. Open with the plain definition, then how it works and why, then the threads worth chasing with `how` or `why`.
