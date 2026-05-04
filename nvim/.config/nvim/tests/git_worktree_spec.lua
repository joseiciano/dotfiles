package.path = table.concat({
  vim.fn.getcwd() .. "/lua/?.lua",
  vim.fn.getcwd() .. "/lua/?/init.lua",
  package.path,
}, ";")

local helpers = require("config.git_worktree")

local worktrees = helpers.parse_worktrees(table.concat({
  "worktree /tmp/repo",
  "HEAD 1234567",
  "branch refs/heads/main",
  "",
  "worktree /tmp/repo-feature",
  "HEAD abcdef0",
  "branch refs/heads/feature/test",
  "",
}, "\n"))

assert(#worktrees == 2, "expected two parsed worktrees")
assert(worktrees[1].path == "/tmp/repo", "expected first worktree path")
assert(worktrees[1].branch == "main", "expected first branch name")
assert(worktrees[2].branch == "feature/test", "expected nested branch name")

assert(helpers.repo_name_from_url("git@github.com:org/repo.git") == "repo", "expected SSH repo name")
assert(helpers.repo_name_from_url("https://github.com/org/repo") == "repo", "expected HTTPS repo name")
assert(helpers.worktree_parent("/projects/repo.git") == "/projects", "expected bare repo parent")
assert(helpers.worktree_parent("/projects/repo") == "/projects", "expected repo parent")
assert(
  helpers.worktree_path("/projects/repo.git", "feature-test") == "/projects/feature-test",
  "expected sibling worktree path"
)
