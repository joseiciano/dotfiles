return {
  {
    "folke/snacks.nvim",
    opts = {
      bufdelete = {},
      picker = {
        hidden = true,
        ignored = true,
      },
      lazygit = {},
      terminal = {},
    },
    keys = {
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
        "<leader>ty",
        function()
          Snacks.terminal.open("yazi", {
            win = {
              style = "float", -- Ensures it's a floating window
              width = 0.8, -- 80% of screen width
              height = 0.8, -- 80% of screen height
            },
          })
        end,
        desc = "Yazi (Terminal)",
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
        "<leader>tc",
        function()
          Snacks.terminal.open("yazi", {
            cwd = vim.fn.getcwd(),
            win = { style = "float" },
          })
        end,
        desc = "Yazi (CWD)",
      },
      {
        "<leader>tt",
        function()
          Snacks.terminal.toggle("yazi", {
            win = { style = "float" },
            -- This ID ensures toggle finds the "yazi" session specifically
            id = "yazi_terminal",
          })
        end,
        desc = "Toggle Latest Yazi Session",
      },
    },
  },
}
