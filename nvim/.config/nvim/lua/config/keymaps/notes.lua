local function run_new_worktree_branch(project_name, branch_name)
  local script_path = vim.fn.expand("$HOME/dotfiles/scripts/new-worktree-branch.sh")

  if vim.fn.executable(script_path) ~= 1 then
    vim.notify("new-worktree-branch.sh is not executable", vim.log.levels.ERROR)
    return
  end

  vim.system(
    { script_path, project_name, branch_name, "--prompt", "--agent", "orchestration" },
    { text = true },
    function(result)
      vim.schedule(function()
        if result.code == 0 then
          vim.notify(string.format("Started worktree for %s/%s", project_name, branch_name))
          return
        end

        local output = vim.trim(result.stderr ~= "" and result.stderr or result.stdout or "")
        if output == "" then
          output = string.format("Failed to create worktree for %s/%s", project_name, branch_name)
        end

        vim.notify(output, vim.log.levels.ERROR)
      end)
    end
  )
end

local function prompt_for_worktree(file_path)
  local project_name

  vim.ui.input({ prompt = string.format("Project name for %s: ", file_path) }, function(project_input)
    project_name = vim.trim(project_input or "")
    if project_name == "" then
      return
    end

    vim.ui.input({ prompt = "Branch name: " }, function(branch_input)
      local branch_name = vim.trim(branch_input or "")
      if branch_name == "" then
        return
      end

      run_new_worktree_branch(project_name, branch_name)
    end)
  end)
end

local function link_file_with_snacks()
  Snacks.picker.files({
    title = "Link or Create File",
    show_empty = true,
    transform = function(item)
      local path = (item.file or item.text or ""):gsub("\\", "/")

      if path:match("^plans/") or path:match("/plans/") then
        return item
      end

      if path:match("^prompts/") or path:match("/prompts/") then
        return item
      end

      if path:match("^stories/") or path:match("/stories/") then
        return item
      end

      return false
    end,
    confirm = function(picker, item)
      picker:close()
      local file_path

      if item then
        file_path = item.file or item.text
      else
        file_path = picker:input()
      end

      if file_path and file_path ~= "" then
        local link = string.format("[[%s]]", file_path)
        vim.api.nvim_put({ link }, "c", true, true)
        prompt_for_worktree(file_path)
      end
    end,
  })
end

vim.keymap.set("n", "<leader>an", link_file_with_snacks, { desc = "Spawn Worktree Session" })

local function embolden()
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("gsaiw*", true, false, true), "m", false)
end

vim.keymap.set("n", "gsawb", embolden, { desc = 'Bolden Current Word"' })
