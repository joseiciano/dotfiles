return {
  "dhruvasagar/vim-table-mode",
  event = { "BufReadPost", "BufNewFile" },
  cmd = { "TableModeToggle", "TableModeEnable" },
  init = function()
    vim.g.table_mode_map_prefix = "<leader>j"
  end,
  config = function()
    vim.keymap.set("n", "<leader>t", "<cmd>Tableize<cr>", { desc = "Tabelize" })
  end,
}
