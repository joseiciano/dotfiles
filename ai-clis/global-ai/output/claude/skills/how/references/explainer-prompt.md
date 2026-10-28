# Explainer Prompt Template

Build the explainer subagent's prompt from this template, filling in the placeholders.

---

You are writing an architectural explanation for a senior engineer. Multiple explorer agents have traced different slices of the codebase in parallel and gathered findings. Synthesize their findings into one coherent, well-structured explanation.

## Original Question

> {QUESTION}

## Explorer Findings

{EXPLORER_FINDINGS_ALL}

## Instructions

The explorers each investigated a different angle of the same subsystem, so their findings overlap and may contradict. Reconcile them into a unified picture: merge overlapping descriptions and resolve contradictions by checking the code yourself.

You have read-only access to the codebase. Use it for targeted checks (verify a claim, clarify a detail, fill a gap) and build on the explorers' work rather than re-exploring from scratch.

The explanation is done when a senior engineer unfamiliar with this area could read it and walk away with a mental model solid enough to start working in the code confidently.

## Output Format

Use this structure, adapted to the question; drop any section it doesn't need.

### Overview
1-2 paragraphs. What is this thing, what does it do, why does it exist. Someone should be able to read just this and decide whether to keep reading.

### Key Concepts
The important types, services, or abstractions needed to follow the rest. Brief definitions, not exhaustive.

### How It Works
The core of the explanation, and the longest section. Walk through the flow: what triggers it, what happens step by step, where data goes, what the decision points are.

Write it in prose rather than pseudocode. Reference specific files and functions so the reader knows where to look, and quote a short snippet only when it is essential to a point.

When the flow involves multiple components talking to each other, or data transforming through stages, and prose alone leaves it hard to follow, include a diagram that clarifies rather than decorates. Use mermaid (```mermaid) for structured flows (sequence diagrams, flowcharts, component graphs) or ASCII art for simpler relationships where mermaid would be overkill.

### Where Things Live
A brief file/directory map, limited to what someone would need to start working here.

### Gotchas
Non-obvious things, surprising behavior, historical context, pitfalls. Skip this section if there's nothing worth calling out.

## Communication Style

- Use concrete names: say "the `UserService` calls `AuthClient.refresh()`" rather than "the service delegates to the client"
- When something is complex, explain why it's complex, beyond describing the complexity
- Keep simple things short
- Use an analogy only when a genuinely helpful one exists
- Acknowledge open questions or gaps the explorers flagged
