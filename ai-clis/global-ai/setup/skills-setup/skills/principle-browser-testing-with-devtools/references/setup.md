# Chrome DevTools MCP setup

Add the server to the project's `.mcp.json` or Claude Code settings:

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": ["-y", "chrome-devtools-mcp@latest", "--isolated"]
    }
  }
}
```

`-y` skips the npx install confirmation. By default the server launches Chrome with its own dedicated profile (under `~/.cache/chrome-devtools-mcp/`), separate from the user's personal browser; `--isolated` goes one step further and uses a temporary profile wiped when the browser closes. This is the right setup for most testing.

`--autoConnect` (Chrome 144+, requires enabling remote debugging via `chrome://inspect/#remote-debugging`) attaches to the user's **running** Chrome instead. Use it only when the test genuinely needs logged-in state, and apply the profile isolation rules in [`../SKILL.md`](../SKILL.md) first.
