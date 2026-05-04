vim.keymap.set("x", "p", "P", { desc = "Paste without replacing register" })

-- Confirm selection (Yes)
vim.keymap.set("i", "<C-y>", "<C-y>", { desc = "Confirm completion" })

-- Abort/Close menu (Exit)
vim.keymap.set("i", "<C-e>", "<C-e>", { desc = "Abort completion" })

vim.keymap.set({ "n", "v", "o" }, "<Left>", "h", { remap = false })
vim.keymap.set({ "n", "v", "o" }, "<Down>", "j", { remap = false })
vim.keymap.set({ "n", "v", "o" }, "<Up>", "k", { remap = false })
vim.keymap.set({ "n", "v", "o" }, "<Right>", "l", { remap = false })

vim.keymap.set("n", "<C-Left>", "<C-w>h")
vim.keymap.set("n", "<C-Down>", "<C-w>j")
vim.keymap.set("n", "<C-Up>", "<C-w>k")
vim.keymap.set("n", "<C-Right>", "<C-w>l")
