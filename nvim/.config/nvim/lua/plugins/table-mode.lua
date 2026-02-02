return {
  "dhruvasagar/vim-table-mode",
  event = { "BufReadPost", "BufNewFile" }, -- Load when you open/create a file
  cmd = { "TableModeToggle", "TableModeEnable" }, -- Load when you run these commands
  init = function()
    -- Optional: Change the table leader trigger if you want
    -- The default is <leader>tm
  end,
}
