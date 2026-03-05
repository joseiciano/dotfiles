-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
vim.api.nvim_set_keymap("t", "<C-t><C-t>", "<C-\\><C-n>", { noremap = true, silent = true })

-- Fancy Save
vim.keymap.set("n", "<leader>qQ", function()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    -- Check if buffer is valid and loaded
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_get_option_value("buflisted", { buf = buf }) then
      local buftype = vim.api.nvim_get_option_value("buftype", { buf = buf })
      local modified = vim.api.nvim_get_option_value("modified", { buf = buf })

      -- Only save if it's not a terminal and has changes
      if buftype ~= "terminal" and modified then
        vim.api.nvim_buf_call(buf, function()
          vim.cmd("silent! update")
        end)
      end
    end
  end
  vim.cmd("quitall")
end, { desc = "Save non-terminal buffers and quit" })

-- Change delete to black hole by default
vim.keymap.set({ "n", "v" }, "d", '"_d', { noremap = true, desc = "Delete (Black Hole)" })
vim.keymap.set("n", "dd", '"_dd', { noremap = true, desc = "Delete Line (Black Hole)" })

-- 1. Normal Mode: map 'cv' followed by a motion to the original delete operator.
-- This allows you to do 'cvw', 'cv$', etc., which acts like the original 'd{motion}'.
vim.keymap.set("n", "<leader>cp", "d", { noremap = true, desc = "Cut (to Unnamed Register)" })

-- 2. Visual Mode: map 'cv' to the original delete of the visual selection.
-- This is used after selecting text with 'v' or 'V' and then pressing 'cv'.
vim.keymap.set("v", "<leader>cp", "d", { noremap = true, desc = "Cut Selection (to Unnamed Register)" })

-- 3. Linewise Cut: map 'cv' + 'cv' to the original 'dd' linewise cut.
vim.keymap.set("n", "<leader>cpv", "dd", { noremap = true, desc = "Cut Line (to Unnamed Register)" })

-- Normal mode, <leader>o triggers g*
vim.keymap.set("n", "<leader>o", "g*", { desc = "Highlight word under cursor" })

-- 1. Shared Helper Function
local function wrap_with_span(color, is_normal_mode)
  if not vim.bo.modifiable then
    return
  end

  -- If called from Normal mode, we force visual selection of the word first
  if is_normal_mode then
    vim.cmd("normal! viw")
  end

  local s_start = vim.fn.getpos("v")
  local s_end = vim.fn.getpos(".")

  local open_tag = string.format('<span style="background-color: %s;">', color)
  local close_tag = "</span>"

  -- Exit visual mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", true)

  local r1, c1 = s_start[2], s_start[3]
  local r2, c2 = s_end[2], s_end[3]

  -- Adjust for back-to-front selection
  if r1 > r2 or (r1 == r2 and c1 > c2) then
    r1, r2 = r2, r1
    c1, c2 = c2, c1
  end

  -- Insert tags
  -- Note: r-1 because API is 0-indexed, c2/c1-1 logic for column placement
  vim.api.nvim_buf_set_text(0, r2 - 1, c2, r2 - 1, c2, { close_tag })
  vim.api.nvim_buf_set_text(0, r1 - 1, c1 - 1, r1 - 1, c1 - 1, { open_tag })
end

--- 2. Visual Mode (Uppercase)
vim.keymap.set("v", "<leader>lY", function()
  wrap_with_span("yellow", false)
end, { desc = "Wrap selection (yellow)" })
vim.keymap.set("v", "<leader>lO", function()
  wrap_with_span("orange", false)
end, { desc = "Wrap selection (orange)" })

--- 3. Normal Mode (Lowercase AND Uppercase)
-- Now we pass 'true' to indicate we want to auto-select the word
local modes = { "n" }
for _, mode in ipairs(modes) do
  vim.keymap.set(mode, "<leader>ly", function()
    wrap_with_span("yellow", true)
  end, { desc = "Wrap word (yellow)" })
  vim.keymap.set(mode, "<leader>lo", function()
    wrap_with_span("orange", true)
  end, { desc = "Wrap word (orange)" })
  vim.keymap.set(mode, "<leader>lY", function()
    wrap_with_span("yellow", true)
  end, { desc = "Wrap word (yellow)" })
  vim.keymap.set(mode, "<leader>lO", function()
    wrap_with_span("orange", true)
  end, { desc = "Wrap word (orange)" })
end
