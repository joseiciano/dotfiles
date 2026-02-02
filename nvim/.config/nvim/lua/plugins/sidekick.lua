return {
  {
    "folke/sidekick.nvim",
    keys = {
      {
        "<leader>ao",
        function()
          require("sidekick.cli").show({ name = "opencode", focus = true })
        end,
        desc = "Sidekick (OpenCode)",
      },
      {
        "<leader>ag",
        function()
          require("sidekick.cli").show({ name = "gemini", focus = true })
        end,
        desc = "Sidekick (Gemini)",
      },
      {
        "<leader>ac",
        function()
          require("sidekick.cli").show({ name = "codex", focus = true })
        end,
        desc = "Sidekick (Codex)",
      },
      {
        "<leader>al",
        function()
          require("sidekick.cli").show({ name = "claude", focus = true })
        end,
        desc = "Sidekick (Claude)",
      },
    },
    opts = {
      -- Your existing sidekick config goes here
    },
  },
}
