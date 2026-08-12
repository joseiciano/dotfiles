local function strip_frontmatter(content)
  -- Normalize CRLF to LF for detection while preserving the body as-is.
  local normalized = content:gsub("\r\n", "\n")
  if normalized:sub(1, 3) ~= "---" then
    return content
  end
  -- Find the line after the opening delimiter (index past the first "\n").
  local _, body_start = normalized:find("\n", 1, true)
  if not body_start then
    return content
  end
  -- Locate the closing delimiter line (skip the leading "\n---" and trailing "\n").
  local close_start = normalized:find("\n---\n", body_start, true)
  local skip = 5
  if not close_start then
    -- closing delimiter at EOF without trailing newline
    close_start = normalized:find("\n---$", body_start)
    skip = 4
    if not close_start then
      return content
    end
  end
  local body = normalized:sub(close_start + skip)
  -- If the body was split across CRLF boundaries, restore CRLF line endings.
  if content:find("\r\n", 1, true) then
    body = body:gsub("\n", "\r\n")
  end
  return body
end

local prompts = {}
do
  local dir = vim.fn.expand("$HOME") .. "/dotfiles/ai-clis/global-ai/output/opencode/command"
  local files = vim.fn.glob(dir .. "/*.md", false, true)
  for _, file in ipairs(files) do
    local name = vim.fn.fnamemodify(file, ":t:r")
    local f = io.open(file, "r")
    if f then
      local content = f:read("*a")
      f:close()
      prompts[name] = strip_frontmatter(content)
    end
  end
end

return {
  "folke/sidekick.nvim",
  opts = {
    -- add any options here
    cli = {
      prompts = prompts,
      win = {
        split = {
          width = 0.45,
        },
      },
      mux = {
        backend = "tmux",
        enabled = false,
      },
      tools = {
        reasonix = {
          cmd = { "reasonix" },
        },
        mimocode = {
          cmd = { "mimo" },
        },
      },
    },
  },
  keys = {
    -- {
    --   "<leader>aa",
    --   function()
    --     local sessions =
    --       require("sidekick.cli.state").get({ attached = true, name = "opencode", terminal = true, cwd = true })
    --     if #sessions > 0 then
    --       local terminal = sessions[1].terminal
    --       terminal:toggle()
    --       if terminal:is_open() then
    --         terminal:focus()
    --       end
    --     else
    --       local tool = require("sidekick.config").get_tool("opencode")
    --       require("sidekick.cli.session").setup()
    --       require("sidekick.cli.state").attach({ tool = tool }, { show = true, focus = true })
    --     end
    --   end,
    --   desc = "toggle or create opencode session",
    -- },
    -- {
    --   "<leader>aA",
    --   function()
    --     require("sidekick.cli").toggle({ name = "opencode", focus = true })
    --   end,
    --   desc = "Toggle Existing OpenCode Session",
    -- },
  },
}
