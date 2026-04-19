return {
  "dhruvasagar/vim-table-mode",
  event = { "BufReadPost", "BufNewFile" },
  cmd = { "TableModeToggle", "TableModeEnable" },
  init = function()
    vim.g.table_mode_map_prefix = "<leader>t"
  end,
  config = function()
    vim.keymap.set("n", "<leader>tt", "<cmd>Tableize<cr>", { desc = "Tabelize" })
  end,
}
