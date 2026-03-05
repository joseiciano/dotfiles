return {
  {
    "folke/snacks.nvim",
    opts = {
      bufdelete = {},
      picker = {
        hidden = true,
        ignored = false,
        exclude = { "node_modules", "dist" },
        sources = {
          explorer = {
            layout = {
              layout = {
                width = 35,
              },
            },
          },
        },
      },
      lazygit = {},
      terminal = {},
    },
    keys = {
      {
        "<leader>es",
        function()
          Snacks.picker.lsp_symbols({
            layout = {
              preset = "vscode",
              preview = "main",
            },
          })
        end,
        desc = "LSP Symbols (VSCode Layout)",
      },
      {
        "<leader>yy",
        function()
          Snacks.bufdelete()
        end,
        desc = "Delete Current Buffer",
      },
      {
        "<leader>ya",
        function()
          Snacks.bufdelete.all()
        end,
        desc = "Delete All Buffers",
      },
      {
        "<leader>yo",
        function()
          Snacks.bufdelete.other()
        end,
        desc = "Delete Other Buffers",
      },
      {
        "<leader>tl",
        function()
          Snacks.lazygit.open()
        end,
        desc = "Lazygit",
      },
      {
        "<leader>ld",
        function()
          Snacks.terminal("lazydocker", {
            win = {
              style = "float", -- Opens in a floating window
              width = 0.9,
              height = 0.9,
            },
          })
        end,
        desc = "Lazydocker (Snacks)",
      },
      {
        "<leader>tf",
        function()
          local file = vim.api.nvim_buf_get_name(0)
          local cmd = (file ~= "" and vim.bo.buftype == "") and ('yazi "' .. file .. '"') or "yazi"

          Snacks.terminal.open(cmd, {
            win = {
              style = "float",
              width = 0.9,
              height = 0.9,
            },
          })
        end,
        desc = "Yazi (Current File)",
      },
      {
        "<leader>ty",
        function()
          Snacks.terminal.open("yazi", {
            cwd = vim.fn.getcwd(),
            win = { style = "float" },
          })
        end,
        desc = "Yazi (CWD)",
      },
      {
        "<leader>tY",
        function()
          Snacks.terminal.toggle("yazi", {
            win = { style = "float" },
            -- This ID ensures toggle finds the "yazi" session specifically
            id = "yazi_terminal",
          })
        end,
        desc = "Toggle Latest Yazi Session",
      },
      {
        "<leader>ts",
        function()
          Snacks.terminal.toggle(nil, {
            id = "persistent_term", -- Ensures this specific terminal is remembered
            win = {
              style = "float",
              width = 0.8,
              height = 0.8,
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
              style = "float",
              width = 0.8,
              height = 0.8,
            },
          })
        end,
        desc = "Open New Terminal (Non-persistent)",
      },
    },
  },
}
