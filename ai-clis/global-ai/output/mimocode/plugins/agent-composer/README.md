# Agent Composer Plugin

This plugin dynamically loads agent definitions from markdown files in the `agents/` directory, with support for reusable prompt snippets from `agents_shared/` and beyond.

## How it works

1. Place agent markdown files in `agents/`.
2. Each file can include YAML frontmatter with agent configuration fields.
3. Use the `shared` frontmatter field to include one or more snippets.
4. Shared files can themselves include other shared files recursively.
5. Headings in included files are demoted based on nesting depth.
6. The plugin merges generated agents into `config.agent`, with existing explicit config taking precedence.

## File Structure

```
plugins/agent-composer/
  index.ts          # Plugin entry point
  agents/           # Agent definition markdown files
  agents_shared/    # Reusable prompt snippets
  references/       # Additional reference docs
```

## Agent File Format

```markdown
---
name: my-agent
model: openai/gpt-4o
shared: common-rules
---

Your base prompt here.
```

### Frontmatter Fields

- `name` — Agent name (defaults to filename without extension)
- `shared` — String or array of strings referencing files to include (see Include Resolution below)
- Any standard agent config field (`model`, `permission`, `steps`, etc.)

### Aliases

The plugin normalizes deprecated frontmatter aliases toward current opencode naming:
- `permissions` → `permission`
- `maxSteps` → `steps`

## Shared Snippets

Files in `agents_shared/` are markdown files that can include their own `shared` frontmatter for recursive composition. Their content is appended to the agent prompt in the order specified by the `shared` field.

### Include Resolution

The `shared` field accepts two kinds of references:

1. **Bare names** — resolved inside `agents_shared/`:
   ```yaml
   shared: coding-information
   ```
   This loads `agents_shared/coding-information.md`.

2. **Relative paths** — resolved relative to the file that contains the `shared` field:
   ```yaml
   shared: ../references/skills-guide.md
   ```
   This is useful for shared files that pull in reference docs from other plugin directories.

### Allowed Roots

For security, resolved paths must lie inside one of the following approved roots:
- The plugin's `agents_shared/` directory
- The plugin's `references/` directory
- The local `.config/opencode/skills/` directory
- The global `~/.config/opencode/skills/` directory

References that resolve outside these roots are skipped with a warning.

### Heading Demotion

When a file is included via `shared`, its ATX markdown headings (`#`, `##`, etc.) are demoted by the include depth:

- First include level: `#` → `##`, `##` → `###`, etc.
- Second nested level: bump by 2, etc.
- Maximum level is capped at `######`.

This keeps heading hierarchies sensible when composing nested documents.

### Cycle Protection

If shared files form an include cycle (A includes B includes A), the plugin detects it, warns, and skips the recursive include to avoid infinite loops.

## Example

**agents/my-reviewer.md:**
```markdown
---
name: reviewer
model: openai/gpt-4o
shared:
  - style-guide
  - security-checklist
---
You are a code reviewer. Focus on clarity and correctness.
```

**agents_shared/style-guide.md:**
```markdown
Follow the project's style guide: use TypeScript strict mode, prefer const, and avoid any.
```

**agents_shared/security-checklist.md:**
```markdown
---
shared: ../references/owasp-top-10.md
---
Security checks: validate all inputs, avoid eval, and sanitize user data.
```

The resulting `reviewer` agent will have its prompt composed of the base body + both shared snippets, with the OWASP reference nested inside `security-checklist` and its headings demoted accordingly.
