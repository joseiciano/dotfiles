return {
  "folke/sidekick.nvim",
  opts = {
    -- add any options here

    cli = {
      win = {
        split = {
          width = 0.45,
        },
      },
      mux = {
        backend = "tmux",
        enabled = false,
      },
    },
  },
  keys = {
    {
      "<leader>aa",
      function()
        local sessions =
          require("sidekick.cli.state").get({ attached = true, name = "opencode", terminal = true, cwd = true })
        if #sessions > 0 then
          local terminal = sessions[1].terminal
          terminal:toggle()
          if terminal:is_open() then
            terminal:focus()
          end
        else
          local tool = require("sidekick.config").get_tool("opencode")
          require("sidekick.cli.session").setup()
          require("sidekick.cli.state").attach({ tool = tool }, { show = true, focus = true })
        end
      end,
      desc = "toggle or create opencode session",
    },
    {
      "<leader>aA",
      function()
        require("sidekick.cli").toggle({ name = "opencode", focus = true })
      end,
      desc = "Toggle Existing OpenCode Session",
    },
  },
}
