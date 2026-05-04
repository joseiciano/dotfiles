vim.api.nvim_set_keymap("t", "<C-t><C-t>", "<C-\\><C-n>", { noremap = true, silent = true })

local function send_visual_selection_to_opencode()
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")

  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end

  local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  if vim.tbl_isempty(lines) then
    return
  end

  local script_path = vim.fn.expand("$HOME/dotfiles/scripts/tmux/send-opencode.sh")
  if vim.fn.executable(script_path) ~= 1 then
    vim.notify("send-opencode.sh is not executable", vim.log.levels.ERROR)
    return
  end

  vim.system({ script_path }, { stdin = table.concat(lines, "\n"), text = true }, function(result)
    if result.code == 0 then
      return
    end

    vim.schedule(function()
      local output = vim.trim(result.stderr ~= "" and result.stderr or result.stdout or "")
      if output == "" then
        output = "Failed to send selection to opencode"
      end

      vim.notify(output, vim.log.levels.ERROR)
    end)
  end)
end

vim.keymap.set("x", "<leader>ta", send_visual_selection_to_opencode, { desc = "Send selection to opencode" })
