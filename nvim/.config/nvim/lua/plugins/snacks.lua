return {
  {
    "folke/snacks.nvim",
    opts = {
      bufdelete = {},
      picker = {
        hidden = true,
        ignored = true,
        exclude = { "node_modules", "dist" },
        sources = {
          explorer = {
            layout = {
              layout = {
                width = 30,
              },
            },
          },
        },
      },
      lazygit = {},
      terminal = {},
      statuscolumn = {
        left = { "sign", "mark" },
      },
    },
    keys = {
      {
        "<leader>be",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>ge",
        function()
          Snacks.picker.git_status()
        end,
        desc = "Git Status (Changes)",
      },
      {
        "<leader>se",
        function()
          Snacks.picker.lsp_symbols({
            layout = {
              preset = "sidebar",
              position = "left",
            },
          })
        end,
        desc = "LSP Symbols",
      },
      {
        "<leader>ld",
        function()
          Snacks.terminal("lazydocker", {
            win = {
              style = "float",
              width = 0.9,
              height = 0.9,
            },
          })
        end,
        desc = "Lazydocker (Snacks)",
      },
      {
        "<leader>ts",
        function()
          Snacks.terminal.toggle(nil, {
            id = "persistent_term",
            win = {
              style = "bottom",
              height = 0.4,
            },
          })
        end,
        desc = "Toggle Persistent Terminal",
      },
      {
        "<leader>tS",
        function()
          Snacks.terminal.open(nil, {
            win = {
              style = "bottom",
              height = 0.4,
            },
          })
        end,
        desc = "New Terminal (Bottom)",
      },
      {
        "<leader>ff",
        function()
          Snacks.picker.files({ cwd = vim.fn.getcwd() })
        end,
        desc = "Find Files (CWD)",
      },
      {
        "<leader>fF",
        function()
          Snacks.picker.files()
        end,
        desc = "Find Files (Root)",
      },
      -- {
      --   "<leader>me",
      --   function()
      --     Snacks.picker.marks()
      --   end,
      --   desc = "Marks",
      -- },
    },
  },
}
