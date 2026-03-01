return {
  {
    "sindrets/diffview.nvim",
    dependencies = {
      -- Required dependency for the plugin to work correctly
      "nvim-lua/plenary.nvim",
    },
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" }, -- Commands to lazy-load the plugin
    keys = {
      -- Keymap to toggle the Diffview window
      {
        "dv",
        function()
          if next(require("diffview.lib").views) == nil then
            vim.cmd("DiffviewOpen")
          else
            vim.cmd("DiffviewClose")
          end
        end,
        desc = "Toggle Diffview window",
      },
    },
    -- Optional: Configuration options
    opts = {
      -- Add any custom options here
      -- Example: default_args = { DiffviewOpen = { "--imply-local" } }
    },
  },
}
