return {
  "fnune/recall.nvim",
  version = "*",
  opts = {
    -- -- Required to avoid raw mark characters in Snacks statuscolumn
    -- sign = "󰁯 ",
    -- sign_highlight = "@comment.note",
  },
  config = function(_, opts)
    local recall = require("recall")
    recall.setup(opts)

    -- Keymaps
    vim.keymap.set("n", "<leader>mm", recall.toggle, { desc = "Recall: Toggle Mark" })
    vim.keymap.set("n", "<leader>mn", recall.goto_next, { desc = "Recall: Next Mark" })
    vim.keymap.set("n", "<leader>mp", recall.goto_prev, { desc = "Recall: Previous Mark" })
    vim.keymap.set("n", "<leader>mc", recall.clear, { desc = "Recall: Clear All" })

    -- Snacks Picker Integration
    vim.keymap.set("n", "<leader>me", function()
      require("recall.snacks").pick()
    end, { desc = "Recall: List Marks (Snacks)" })
  end,
}
