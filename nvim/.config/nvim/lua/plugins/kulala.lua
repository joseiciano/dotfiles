return {
  {
    "mistweaverco/kulala.nvim",
    -- Note: LazyVim will automatically load this when you open a .http or .rest file
    ft = { "http", "rest" },
    keys = {
      {
        "<leader>rs",
        function()
          require("kulala").run()
        end,
        desc = "Send request",
      },
      {
        "<leader>ra",
        function()
          require("kulala").run_all()
        end,
        desc = "Send all requests",
      },
      {
        "<leader>rb",
        function()
          require("kulala").scratchpad()
        end,
        desc = "Open scratchpad",
      },
      {
        "<leader>rt",
        function()
          require("kulala").toggle_view()
        end,
        desc = "Toggle headers/body",
      },
      {
        "<leader>rc",
        function()
          require("kulala").from_curl()
        end,
        desc = "Import from curl",
      },
    },
    opts = {
      global_keymaps = false,
      -- These prefixes are used if you use the default keymaps;
      -- since we defined custom keys above, these are mostly fallback settings.
      global_keymaps_prefix = "<leader>r",
      kulala_keymaps_prefix = "",
    },
  },
}
