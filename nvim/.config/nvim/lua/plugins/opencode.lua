return {
  "sudo-tee/opencode.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        anti_conceal = { enabled = false },
        file_types = { "markdown", "opencode_output" },
      },
      ft = { "markdown", "Avante", "copilot-chat", "opencode_output" },
    },
    "saghen/blink.cmp",
    "folke/snacks.nvim",
  },
  opts = {
    default_mode = "orchestration",

    keymap = {
      editor = {
        ["<leader>aa"] = { "toggle" },
        ["<leader>ai"] = { "open_input" },
        ["<leader>aI"] = { "open_input_new_session" },
        ["<leader>ao"] = { "open_output" },
        ["<leader>af"] = { "toggle_focus" },
        ["<leader>aF"] = { "timeline" },
        ["<leader>aq"] = { "close" },
        ["<leader>ass"] = { "select_session" },
        ["<leader>asr"] = { "rename_session" },
        ["<leader>acp"] = { "configure_provider" },
        ["<leader>acv"] = { "configure_variant" },
        ["<leader>aca"] = {
          function()
            require("opencode.api").select_agent()
          end,
          desc = "Configure Agent",
        },
        ["<leader>at"] = { "add_visual_selection", mode = { "v" } },
        ["<leader>aT"] = { "add_visual_selection_inline", mode = { "v" } },
        ["<leader>aoz"] = { "toggle_zoom" },
        ["<leader>aov"] = { "paste_image" },
        ["<leader>ado"] = { "diff_open" },
        ["<leader>adn"] = { "diff_next" },
        ["<leader>adp"] = { "diff_prev" },
        ["<leader>adq"] = { "diff_close" },
        ["<leader>adrP"] = { "diff_revert_all_last_prompt" },
        ["<leader>adrp"] = { "diff_revert_this_last_prompt" },
        ["<leader>adra"] = { "diff_revert_all" },
        ["<leader>adrt"] = { "diff_revert_this" },
        ["<leader>adrs"] = { "diff_restore_snapshot_file" },
        ["<leader>adrS"] = { "diff_restore_snapshot_all" },
        ["<leader>aws"] = { "swap_position" },
        ["<leader>awt"] = { "toggle_tool_output" },
        ["<leader>awr"] = { "toggle_reasoning_output" },
        ["<leader>ae"] = { "quick_chat", mode = { "n", "x" } },
      },
      output_window = {
        ["<leader>aoS"] = { "navigate_session_tree", { "child", "picker" } },
        ["<leader>aoP"] = { "navigate_session_tree", { "parent" } },
        ["<leader>aoB"] = { "navigate_session_tree", { "sibling", "picker" } },
        ["<leader>aoD"] = { "debug_message" },
        ["<leader>aoO"] = { "debug_output" },
        ["<leader>aods"] = { "debug_session" },
        -- Default output controls
        ["<esc>"] = { "close" },
        ["<C-c>"] = { "cancel" },
        ["]]"] = { "next_message" },
        ["[["] = { "prev_message" },
        ["<tab>"] = { "toggle_pane", mode = { "n", "i" } },
        ["i"] = { "focus_input", "n" },
        ["<M-r>"] = { "cycle_variant", mode = { "n" } },
      },
    },
  },
  config = function(_, opts)
    require("opencode").setup(opts)
  end,
}
