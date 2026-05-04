local helpers = require("config.git_worktree")

local function notify(level, message)
  Snacks.notify[level](message, { title = "git-worktree" })
end

local function prompt(opts, on_confirm)
  Snacks.input.input(opts, function(value)
    if not value then
      return
    end

    value = vim.trim(value)
    if value == "" then
      return
    end

    on_confirm(value)
  end)
end

local function confirm(prompt_text, on_confirm)
  Snacks.picker.select({ "No", "Yes" }, { prompt = prompt_text }, function(choice)
    if choice == "Yes" then
      on_confirm()
    end
  end)
end

local function git(args, opts)
  local result = vim.system(args, vim.tbl_extend("force", { text = true }, opts or {})):wait()
  if result.code ~= 0 then
    return nil, vim.trim(result.stderr or result.stdout or "Git command failed")
  end

  return result
end

local function current_worktree_path(git_worktree)
  git_worktree.setup_git_info()
  return git_worktree.get_current_worktree_path()
end

local function select_worktree(prompt_text, cb, opts)
  opts = opts or {}

  local git_worktree = require("git-worktree")
  local current_path = current_worktree_path(git_worktree)
  local result, err = git({ "git", "worktree", "list", "--porcelain" })
  if not result then
    notify("error", err)
    return
  end

  local worktrees = helpers.parse_worktrees(result.stdout)
  if opts.exclude_current then
    worktrees = vim.tbl_filter(function(item)
      return item.path ~= current_path
    end, worktrees)
  end

  if #worktrees == 0 then
    notify("warn", "No matching worktrees found")
    return
  end

  Snacks.picker.select(worktrees, {
    prompt = prompt_text,
    format_item = function(item)
      local branch = item.branch or (item.detached and "detached") or item.head or "unknown"
      local current = item.path == current_path and "● " or "  "
      return string.format("%s%s — %s", current, branch, item.path)
    end,
    snacks = { title = "Git Worktrees" },
  }, cb)
end

local function switch_worktree()
  local git_worktree = require("git-worktree")
  local current_path = current_worktree_path(git_worktree)

  select_worktree("Switch worktree", function(item)
    if not item or item.path == current_path then
      return
    end

    git_worktree.switch_worktree(item.path)
  end)
end

local function init_worktree_repo()
  prompt({ prompt = "Git repository URL: " }, function(repo_url)
    prompt({ prompt = "Parent directory: ", default = vim.fn.getcwd() }, function(parent_dir)
      if not vim.uv.fs_stat(parent_dir) then
        notify("error", "Directory does not exist: " .. parent_dir)
        return
      end

      local repo_name = helpers.repo_name_from_url(repo_url)
      if not repo_name then
        notify("error", "Could not determine repository name")
        return
      end

      local bare_repo_path = vim.fs.joinpath(parent_dir, repo_name .. ".git")
      local initial_worktree_path = vim.fs.joinpath(parent_dir, repo_name)

      if vim.uv.fs_stat(bare_repo_path) or vim.uv.fs_stat(initial_worktree_path) then
        notify("error", "Target paths already exist")
        return
      end

      local clone_result, clone_err = git({ "git", "clone", "--bare", repo_url, bare_repo_path })
      if not clone_result then
        notify("error", clone_err)
        return
      end

      local head_result, head_err = git({ "git", "--git-dir=" .. bare_repo_path, "symbolic-ref", "--short", "HEAD" })
      if not head_result then
        notify("error", head_err)
        return
      end

      local default_branch = vim.trim(head_result.stdout)
      local add_result, add_err = git({
        "git",
        "--git-dir=" .. bare_repo_path,
        "worktree",
        "add",
        initial_worktree_path,
        default_branch,
      })

      if not add_result then
        notify("error", add_err)
        return
      end

      vim.cmd("cd " .. vim.fn.fnameescape(initial_worktree_path))
      require("git-worktree").setup_git_info()
      notify("info", "Initialized worktree repo at " .. initial_worktree_path)
    end)
  end)
end

local function create_worktree()
  local git_worktree = require("git-worktree")
  git_worktree.setup_git_info()

  local root = git_worktree.get_root()
  if not root then
    notify("error", "Open a git repository before creating a worktree")
    return
  end

  prompt({ prompt = "Worktree / branch name: " }, function(name)
    local path = helpers.worktree_path(root, name)
    if not path then
      notify("error", "Could not determine worktree path")
      return
    end

    git_worktree.create_worktree(path, name, "main")
  end)
end

local function delete_worktree()
  local git_worktree = require("git-worktree")

  select_worktree("Delete worktree", function(item)
    if not item then
      return
    end

    confirm("Delete " .. item.path .. "?", function()
      git_worktree.delete_worktree(item.path, false, {
        on_success = function()
          vim.schedule(function()
            notify("info", "Deleted worktree " .. item.path)
          end)
        end,
        on_failure = function(err)
          vim.schedule(function()
            local stderr = err and err.stderr_result and table.concat(err:stderr_result(), "\n")
              or "Failed to delete worktree"
            notify("error", vim.trim(stderr))
          end)
        end,
      })
    end)
  end, { exclude_current = true })
end

return {
  "ThePrimeagen/git-worktree.nvim",
  config = function()
    require("git-worktree").setup()
  end,
  keys = {
    {
      "<leader>gws",
      switch_worktree,
      desc = "Switch Git Worktree (Snacks)",
    },
    {
      "<leader>gwi",
      init_worktree_repo,
      desc = "Init Git Worktree",
    },
    {
      "<leader>gwc",
      create_worktree,
      desc = "Create Git Worktree",
    },
    {
      "<leader>gwd",
      delete_worktree,
      desc = "Delete Git Worktree (Snacks)",
    },
  },
}
