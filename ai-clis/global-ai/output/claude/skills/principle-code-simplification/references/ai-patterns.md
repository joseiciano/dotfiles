# AI-Generated Code Patterns

The deslop branch: code an agent wrote, or a request to deslop a branch. Diff the branch against main and check every hunk for these patterns before the general pattern tables:

- Comments that restate the code or break the file's comment style
- Defensive checks or try/catch on paths the types or callers already guarantee
- Casts to `any` that exist only to silence a type error
- Nesting that early returns would flatten
- Anything else the surrounding file and codebase would not write

Defensive code comes out only where the path is trusted; error handling a caller relies on stays.

Keep edits minimal and focused. Done when every hunk has been checked against every pattern above; report the result in 1–3 sentences.
