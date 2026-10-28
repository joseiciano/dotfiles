---
name: to-questionnaire
description: Turn a decision you can't fully answer into a questionnaire for someone else to fill in.
argument-hint: '[topic or decision]'
disable-model-invocation: true
---

# To-Questionnaire

Turn something the user can't answer alone into a **questionnaire**: a Markdown document they hand to one person to fill in async, or fill out together over a meeting. The recipient holds knowledge the user lacks; the questionnaire pulls it out of them.

**Grill the send, not the subject.** Interview the user only about the _send_, which they can always answer: who it goes to, and what they need back. The questions in the document then target the **gap** between what the recipient knows and what the user needs.

## Process

### Step 1: Who is it going to?

Ask, in one exchange, the recipient's role, expertise, and relationship to the user. This fixes the questionnaire's tone and how much context it must carry. Skip anything the arguments or conversation already answer.

Done when you know who the recipient is and what they know that the user doesn't.

### Step 2: What do you need back?

Ask, in one exchange, the specific decisions or facts the user can't resolve alone and needs from this person.

Done when you have a concrete list of what the user must walk away able to do or decide.

### Step 3: Write the questionnaire

Fill [`references/questionnaire-template.md`](references/questionnaire-template.md) with questions aimed at the gap from Steps 1–2. Order questions most-important-first, since async may give you only one pass. Group them under `##` theme headings once there are more than a handful.

Write it to `to-questionnaire-<slug>.md` in the current directory (slug from the topic) and reply with the path.

Done when the file exists and every item from Step 2 maps to a question.

## Verification

- [ ] Every item the user named in Step 2 maps to at least one question.
- [ ] Each question asks one idea and has an answer stub beneath it.
- [ ] _Why this matters_ lines appear only on questions that could be misread or invite a throwaway answer.
- [ ] The Context section lets a recipient who wasn't in the user's head answer well.
