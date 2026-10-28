# Visual direction

The no-design-system branch of [`../SKILL.md`](../SKILL.md). The output is a **design contract** that stands in for the missing design system: every later visual decision traces to it.

## 1. Gather references

Take references from the product team, or search a trusted catalogue. Study two or three relevant screens and record their decisions on hierarchy, density, navigation, controls, responsive behaviour, and interaction states. Done when each screen has a decision recorded for each of the six. With no references available, record the assumptions you are designing on instead.

## 2. Choose a direction

Answer four questions:

- **Purpose**: what problem does the interface solve, and for whom?
- **Tone**: one named aesthetic, held throughout: minimal, maximalist, editorial, brutalist, retro-futuristic, organic, luxury, playful, art deco, soft, industrial.
- **Constraints**: framework, performance budget, accessibility level.
- **Differentiation**: the one thing a visitor will remember.

Refined minimalism and bold maximalism both qualify; what qualifies is that the tone was chosen. Choose fresh for each project: fonts, palettes, and layouts from the last project are the AI aesthetic one step removed.

## 3. Write the design contract

The contract names:

- The screen's job, its primary action, its required states, and its responsive rules.
- **Typography**: a characterful display face paired with a refined body face.
- **Palette**: a dominant colour with sharp accents, defined as CSS variables.
- **Composition**: the layout's governing idea: asymmetry, overlap, diagonal flow, grid-breaking elements, generous negative space, or controlled density.
- **Atmosphere**: the surface treatment the tone calls for: gradient mesh, noise, grain, geometric pattern, layered transparency, or a deliberate flat.
- **Motion**: one orchestrated page-load sequence with staggered reveals, in CSS for HTML and the Motion library for React.
- The patterns this screen rejects, each paired with what it uses instead.

Done when every item above has an answer specific to this product.

## 4. Build to the contract

Rebuild the useful structure from the references in the product's own components, tokens, content, and visual language; branding, proprietary text, imagery, and exact layouts stay with their owners. Match code complexity to the tone: maximalism earns elaborate effects, minimalism earns precise spacing and type.
