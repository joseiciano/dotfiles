---
name: smart-dumb-component
description: Enforces smart/dumb frontend component separation (business logic vs rendering logic).
author: joseiciano
version: "1.0.0"
---

# Smart-Dumb Component Pattern

Use this skill when implementing or refactoring frontend components.

## Definition

- Smart-Dumb component structures frontend code components in two components: a high level "smart" component, and a rendering logic "dumb" component.

**Why Use**
- Structures code in a clean, organized way
- Separates business logic from rendering logic 

**When to Use**:
- Front-end code built with modern frameworks (React, NextJS, Astro)
- Pages have a dependency on information fetched from a server

## Goal
Separate concerns clearly:

- **Smart component**: orchestration and business logic
- **Dumb component**: rendering and presentational UI

This keeps components easier to test, reuse, and maintain.

## Smart Component

A smart component is the publicly exposed entrypoint used by pages/components (for example, `Foo`).
It prepares data and passes render-ready props to its dumb counterpart.

**Rules**:
- Is the publicly exposed version of the component
- Is what will be imported and used by other files when we need a component, `Foo`.
- Will **Always** call a dumb component to handle the rendering logic

**What It Does**:
- Handles state checks
- Handles auth checks
- Handles http calls
- Handles query param parsing
- Handles hook calls
- Everything that is not rendering logic, goes here

**What It Does Not Do**:
- Rendering logic
- CSS, HTML, JSX

**Example**: 
```typescript
import {FooDumb} from "./foo-dumb"

export type FooProps = {

}

export function Foo(props: FooProps) {
  const [isAuthed] = useAuth();
  const [myProfile]  = useProfile();

  return <FooDumb 
    authed = {!!isAuthed}
    profile = {myProfile}
  />
}
```

## Dumb Component

A dumb component contains only rendering logic.
It receives all required data via props and focuses only on UI.
**Rules**:
- Holds all the rendering logic. 
- Does no more than UI work. 

**What It Does**:
- All rendering logic
- HTML, CSS, JSX

**What It Does Not Do**:
- Handle any higher level business logic 
- Make http calls
- Handle checks against query params unless passed in as a prop

**Example**:
```typescript
export type FooDumbProps = {
  authed: boolean;
  profile: unknown;
};

export function FooDumb(props: FooDumbProps) {
  return (
    <div>
      <h1>{String(props.authed)}</h1>
    </div>
  );
}
```

## Guidelines
When working on smart-dumb components, **always** follow these guidelines.

**What to do**:
- Keep files small whenever possible. 
- Separate smart and dumb component in two files (a "smart" component file and a "dumb" component file).
- Use smart/dumb component logic whenever possible to maintain structure in UI logic.
- Smart components should be the public import target.
- Dumb components should stay pure/presentational and prop-driven.
- If logic is not rendering-related, move it out of the dumb component.

**Example File Structure**:

```typescript
|/routes
| - foo/
|  - index.tsx // Stores the route specific logic (redirects, etc.). Imports foo-smart. 
|  - foo-smart.tsx // <-- Smart logic for the page. Imports foo-dumb and calls it
|  - foo-dumb.tsx // <-- Rendering logic for the page. 
```

```typescript
|/components
| - foo/
|  - index.tsx // <-- Barrel imports foo-smart and types
   - foo-smart.tsx // <-- Holds smart component logic 
   - foo-dumb.tsx // <-- Holds rendering logic. Does not get barrel imported
   - types.tsx // <-- Holds types specific to this component
```

