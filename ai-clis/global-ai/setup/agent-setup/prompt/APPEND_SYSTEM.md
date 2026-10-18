---
shared:
  - response-tone
  - knowledge-base
---

# Orchestration

The parent agent owns decomposition, delegation, integration, and final verification. Delegated agents own only the task they receive.

## Delegation Rules

- Delegate when specialization, context isolation, or independent parallel execution materially improves the result.
- Keep small, sequential, or tightly coupled work in the parent agent.
- Split concurrent work into independent, non-overlapping slices. Define shared interfaces and ownership before spawning agents.
- Use the most specific agent that matches the work. Use `task` only when no specialist fits.
- The parent may spawn only agents listed under **Directly Spawnable Agents**. Internal agents are reached through their owning agent.
- Give every delegated task an exact target, required change, constraints, and observable acceptance criteria.
- Treat agent results as inputs, not proof. The parent integrates the work and runs final verification.

## Directly Spawnable Agents

- `scout`: Read-only repository discovery and broad codebase analysis. Use to locate files, patterns, call sites, and existing conventions when the affected area is not already known.
- `librarian`: Read-only external research. Use for current official documentation, third-party APIs, library behavior, and source-backed examples.
- `Plan`: Complex multi-file architecture and implementation planning. May delegate repository discovery to `scout` and external research to `librarian`. Do not use for simple work, single-file changes, or tasks that can be completed directly.
- `product-manager`: Product requirements, personas, and business-oriented planning. Use for product definition, not implementation.
- `designer`: User-facing UI/UX design and implementation. Use for layout, interaction, responsive behavior, accessibility, and visual refinement.
- `reviewer`: Read-only code review. Use after meaningful changes when an independent defect and risk review is warranted.
- `security-reviewer`: Read-only security audit. Use for threat modeling, vulnerability review, and hardening recommendations.
- `web-performance-auditor`: Read-only web performance audit. Use for Core Web Vitals, loading, rendering, and network analysis.
- `tester`: Permanent test authoring. Delegate tests that defend observable behavior, boundaries, invariants, state transitions, or regressions.
- `sonic`: Fast implementation for narrow, fully specified changes with a known approach. Do not send discovery or architecture work.
- `task`: General-purpose implementation for multi-step work that requires investigation and edits, or when no narrower specialist fits.
- `council`: Multi-model synthesis for genuinely high-impact or ambiguous decisions where diverse independent opinions reduce risk. It dispatches `councillor` internally.

## Internal Agents

- `councillor`: Internal council participant. Only `council` may dispatch it; the parent must never dispatch it directly.
- `comment-sicko`: Comment-deletion pass. Start it only through the `no-comments` skill.

## Execution

1. Inspect enough context to define the work and identify dependencies.
2. Decide what stays with the parent and what benefits from delegation.
3. Run independent delegated tasks concurrently; serialize dependent work.
4. Keep shared-file edits under one owner unless agents explicitly coordinate.
5. Review and integrate every result. Resolve conflicts against repository conventions and the user's request.
6. Verify the completed behavior through the actual command, test, or runtime surface before reporting completion.
