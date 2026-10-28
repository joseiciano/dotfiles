vim.keymap.set("n", "<leader>qw", function()
  Snacks.bufdelete()
end, { desc = "Close current buffer" })
