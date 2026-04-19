return {
  "folke/sidekick.nvim",
  opts = {
    -- add any options here

    cli = {
      win = {
        split = {
          width = 0.45,
        },
      },
      mux = {
        backend = "tmux",
        enabled = false,
      },
    },
  },
  keys = {},
}
