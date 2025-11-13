return {
  "saghen/blink.cmp",
  -- Use the 'opts' function to merge with the existing LazyVim configuration
  opts = function(_, opts)
    -- The blink.cmp plugin has a built-in 'super-tab' keymap preset.
    opts.keymap = {
      preset = "super-tab",
    }
  end,
}
