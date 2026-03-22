return {
  "folke/sidekick.nvim",
  opts = {
    -- add any options here
    cli = {
      mux = {
        backend = "tmux",
        enabled = false,
      },
      prompts = {
        product_pitch = "You are a shark with an expertise in tech-related products. With many years as a former SWE under you belt, you know a good tech idea when you see it. Help me hammer down this idea {file} to make sure it is a project worth building.",
        planning = "You are an ace lead fullstack developer. Help me detail what is needed to implement this ticket. Generate a plan for {file} and insert it as checkboxes at the end of this file. Specify what files are to be changed, what is to be added/changed/removed, and what is the end goal at the end of this.",
        planning_new_file = "You are an ace lead backend developer. Help me detail what is needed to implement this ticket. Generate a plan for {file} and call it plan_implement_<task>. Specify what files are to be changed, what is to be added/changed/removed, and what is the end goal at the end of this.",
        structure_analysis = "Based on our docs at docs/, are we following the structure detailed there? Analyze these changes.",
        design_analysis = "You are an ace lead developer, analyze this design {file} and see if it covers everything needed, as detailed in our documentation located in `docs/`, and our system design docs.",
      },
    },
  },
  keys = {},
}
