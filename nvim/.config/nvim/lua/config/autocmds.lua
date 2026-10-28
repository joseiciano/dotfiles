-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local augroup = vim.api.nvim_create_augroup("user_diagnostic_hover", { clear = true })

vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  group = augroup,
  callback = function()
    vim.diagnostic.open_float(nil, {
      scope = "cursor", -- Show diagnostics for the cursor position
      focus = false, -- **This is the key:** do not focus the window
      source = "always", -- Or "if_many"
    })
  end,
  desc = "Show diagnostic float on hover",
})

local max_buffers = 100

vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function()
    local buffers = vim.fn.getbufinfo({ buflisted = 1 })
    if #buffers > max_buffers then
      vim.cmd("bd " .. buffers[1].bufnr)
    end
  end,
})

local function is_sidekick(win)
  return vim.w[win].sidekick_cli ~= nil
end

local function editor_wins()
  return vim.tbl_filter(function(w)
    return vim.api.nvim_win_get_config(w).relative == "" and not is_sidekick(w)
  end, vim.api.nvim_tabpage_list_wins(0))
end

-- Options sidekick sets on its window, which leak into buffers or splits that pass through it
local sidekick_wo = { "winhighlight", "colorcolumn", "cursorcolumn", "cursorline", "fillchars", "list", "listchars", "number",
  "relativenumber", "sidescrolloff", "signcolumn", "statuscolumn", "spell", "winbar", "wrap" }

local function reset_wo(win)
  vim.api.nvim_win_call(win, function()
    for _, opt in ipairs(sidekick_wo) do
      vim.cmd("setlocal " .. opt .. "<")
    end
  end)
end

local sidekick_layout = vim.api.nvim_create_augroup("user_sidekick_layout", { clear = true })

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = sidekick_layout,
  callback = function(ev)
    local win = vim.api.nvim_get_current_win()
    local term = vim.fn.bufnr("#")
    if not is_sidekick(win) or vim.b[ev.buf].sidekick_cli or term == -1 or not vim.b[term].sidekick_cli then
      return
    end
    local cursor = vim.api.nvim_win_get_cursor(win)
    vim.schedule(function()
      vim.api.nvim_win_set_buf(win, term)
      local target = editor_wins()[1]
      if not target then
        vim.api.nvim_set_current_win(win)
        vim.cmd("leftabove vsplit")
        target = vim.api.nvim_get_current_win()
      end
      vim.api.nvim_win_set_buf(target, ev.buf)
      reset_wo(target)
      pcall(vim.api.nvim_win_set_cursor, target, cursor)
      vim.api.nvim_set_current_win(target)
    end)
  end,
  desc = "Move files opened in the sidekick window to an editor window",
})

vim.api.nvim_create_autocmd("WinClosed", {
  group = sidekick_layout,
  callback = function()
    local widths = {}
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if is_sidekick(w) then
        widths[w] = vim.api.nvim_win_get_width(w)
      end
    end
    vim.schedule(function()
      local wins = vim.api.nvim_tabpage_list_wins(0)
      if #editor_wins() == 0 and #wins > 0 and is_sidekick(wins[1]) then
        local sk = wins[1]
        vim.api.nvim_set_current_win(sk)
        vim.cmd("leftabove vnew")
        reset_wo(0)
        if widths[sk] then
          vim.api.nvim_win_set_width(sk, widths[sk])
        end
      end
    end)
  end,
  desc = "Keep an editor window next to the sidekick terminal",
})
