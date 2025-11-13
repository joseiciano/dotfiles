return {
  -- Set Catppuccin as the default colorscheme for LazyVim
  {
    "LazyVim/LazyVim",
    dependencies = {
      "folke/snacks.nvim",
    },
    opts = {
      colorscheme = "catppuccin",
    },
  },

  -- Configure the Catppuccin plugin itself
  {
    "catppuccin/nvim",
    lazy = false,
    opts = { flavour = "macchiato", transparent = false },
  },

  {
    "folke/tokyonight.nvim",
    lazy = false,
    opts = { style = "moon", transparent = false },
    -- stylua: ignore
  },
  {
    "loctvl842/monokai-pro.nvim",
    lazy = false, -- Set to load immediately
  },

  {
    "sainnhe/sonokai",
    lazy = false, -- Set to load immediately
  },

  {
    "Mofiqul/dracula.nvim",
    lazy = false, -- Set to load immediately
  },

  {
    "rebelot/kanagawa.nvim",
    lazy = false, -- Set to load immediately
    opts = {
      theme = "dragon",
      transparent = false,
    },
  },
}
