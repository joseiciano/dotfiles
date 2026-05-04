vim.keymap.set("n", "<leader>qw", "<cmd>bdelete<cr>", { desc = "Close current buffer" })

vim.keymap.set("n", "<leader>qQ", function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_get_option_value("buflisted", { buf = buf }) then
      local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
      local modified = vim.api.nvim_get_option_value("modified", { buf = buf })

      if buftype ~= "terminal" and modified then
        vim.api.nvim_buf_call(buf, function()
          vim.cmd("silent! update")
        end)
      end
    end
  end

  vim.cmd("quitall")
end, { desc = "Save non-terminal buffers and quit" })

-- Tmux session
local function send_line_ref()
  local file = vim.fn.expand("%:p")
  local line = vim.fn.line(".")
  -- Format: file_path:line_number
  local cmd = string.format("tmux send-keys -t right '%s:%s' Enter", file, line)
  os.execute(cmd)
end

vim.keymap.set("n", "<leader>tr", send_line_ref)
