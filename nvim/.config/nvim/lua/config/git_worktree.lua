local M = {}

function M.parse_worktrees(output)
  local worktrees = {}
  local current

  local function push()
    if current and current.path then
      table.insert(worktrees, current)
    end
    current = nil
  end

  for line in vim.gsplit(output or "", "\n", { plain = true, trimempty = false }) do
    if line == "" then
      push()
    else
      current = current or {}

      if vim.startswith(line, "worktree ") then
        current.path = line:sub(10)
      elseif vim.startswith(line, "branch ") then
        current.branch = line:sub(8):gsub("^refs/heads/", "")
      elseif vim.startswith(line, "HEAD ") then
        current.head = line:sub(6)
      elseif line == "detached" then
        current.detached = true
      elseif line == "bare" then
        current.bare = true
      end
    end
  end

  push()

  return worktrees
end

function M.repo_name_from_url(url)
  local normalized = vim.trim(url or ""):gsub("/+$", ""):gsub("%.git$", "")

  return normalized:match("/([^/]+)$") or normalized:match(":([^:]+)$")
end

function M.worktree_parent(root)
  if not root or root == "" then
    return nil
  end

  return vim.fs.dirname(root)
end

function M.worktree_path(root, name)
  local parent = M.worktree_parent(root)
  if not parent or not name or name == "" then
    return nil
  end

  return vim.fs.joinpath(parent, name)
end

return M
