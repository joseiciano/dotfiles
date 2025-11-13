-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
vim.api.nvim_set_keymap("t", "<C-t><C-t>", "<C-\\><C-n>", { noremap = true, silent = true })

local function replace_current_word()
  local current_word = vim.fn.expand("<cword>")

  -- 1. Check for word
  if current_word == "" then
    print("Cursor is not on a word. Operation aborted.")
    return
  end

  -- 2. Prompt for replacement
  local prompt = string.format("Replace %s by?", current_word)
  local replacement_word = vim.fn.input(prompt .. " ")

  if replacement_word == nil or replacement_word == "" then
    print("Replacement cancelled.")
    return
  end

  -- 3. Perform file-wide substitution
  local escaped_current = vim.fn.escape(current_word, "~/\\")
  local escaped_replacement = vim.fn.escape(replacement_word, "~/\\")

  -- This substitution command is solid: %s for file-wide, \V for literal match, I for case-insensitive
  local command = string.format("%%s/\\V%s/%s/geI", escaped_current, escaped_replacement)
  vim.cmd(command)
  print(string.format("Replaced all occurrences of '%s' with '%s'.", current_word, replacement_word))
end

-- Set the keymap to call the now-global function
vim.keymap.set("n", "<leader>cc", replace_current_word, {
  noremap = true,
  silent = true,
  desc = "Replace word under cursor and all occurrences in file",
})

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

