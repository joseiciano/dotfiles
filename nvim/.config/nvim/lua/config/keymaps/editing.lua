vim.keymap.set("x", "p", "P", { desc = "Paste without replacing register" })

-- Confirm selection (Yes)
vim.keymap.set("i", "<C-y>", "<C-y>", { desc = "Confirm completion" })

-- Abort/Close menu (Exit)
vim.keymap.set("i", "<C-e>", "<C-e>", { desc = "Abort completion" })
