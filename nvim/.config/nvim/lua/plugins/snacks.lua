local function notify(level, message)
  Snacks.notify[level](message, { title = "tmux windows" })
end

local function confirm(prompt_text, on_confirm)
  Snacks.picker.select({ "No", "Yes" }, { prompt = prompt_text }, function(choice)
    if choice == "Yes" then
      on_confirm()
    end
  end)
end

local function tmux(args)
  local result = vim.system(vim.list_extend({ "tmux" }, args), { text = true }):wait()
  if result.code ~= 0 then
    return nil, vim.trim(result.stderr or result.stdout or "tmux command failed")
  end

  return result
end

local function current_tmux_session()
  local result, err = tmux({ "display-message", "-p", "#{session_name}" })
  if not result then
    return nil, err
  end

  local session = vim.trim(result.stdout)
  if session == "" then
    return nil, "Could not determine current tmux session"
  end

  return session
end

local function list_tmux_windows()
  local result, err = tmux({
    "list-windows",
    "-a",
    "-F",
    "#{session_name}\t#{window_index}\t#{window_name}\t#{window_active}",
  })
  if not result then
    return nil, err
  end

  local items = {}
  for _, line in ipairs(vim.split(result.stdout, "\n", { trimempty = true })) do
    local fields = vim.split(line, "\t", { plain = true })
    if #fields >= 4 then
      local session = fields[1]
      local index = fields[2]
      local name = fields[3]
      local active = fields[4] == "1"

      items[#items + 1] = {
        session = session,
        index = index,
        name = name,
        active = active,
        target = string.format("%s:%s", session, index),
      }
    end
  end

  return items
end

local function switch_tmux_window(item)
  local result, err = tmux({ "switch-client", "-t", item.session })
  if not result then
    notify("error", err)
    return
  end

  result, err = tmux({ "select-window", "-t", item.target })
  if not result then
    notify("error", err)
  end
end

local function parse_new_window_target(input, default_session)
  local session, name = input:match("^([^:]+):(.+)$")
  session = vim.trim(session or default_session or "")
  name = vim.trim(name or input)

  if session == "" or name == "" then
    return nil, nil
  end

  return session, name
end

local function create_tmux_window(input)
  local default_session, session_err = current_tmux_session()
  if not default_session then
    notify("error", session_err)
    return
  end

  local session, name = parse_new_window_target(input, default_session)
  if not session or not name then
    notify("warn", "Enter a tmux window name")
    return
  end

  confirm(string.format("Create tmux window %q in session %q?", name, session), function()
    local result, err = tmux({ "new-window", "-t", session, "-n", name })
    if not result then
      notify("error", err)
      return
    end

    local target = { session = session, target = session .. ":" .. name }
    switch_tmux_window(target)
    notify("info", string.format("Created tmux window %s:%s", session, name))
  end)
end

local function open_tmux_windows_picker()
  local windows, err = list_tmux_windows()
  if not windows then
    notify("error", err)
    return
  end

  Snacks.picker.select(windows, {
    prompt = "Tmux windows",
    format_item = function(item)
      local current = item.active and "●" or " "
      return string.format("%s %s:%s — %s", current, item.session, item.index, item.name)
    end,
    snacks = {
      title = "Tmux Windows",
      layout = { preset = "select" },
      preview = "none",
      actions = {
        confirm = function(picker, item)
          local input = vim.trim(picker.input:get())
          picker:close()

          if item then
            switch_tmux_window(item.item)
            return
          end

          if input ~= "" then
            create_tmux_window(input)
            return
          end

          notify("warn", "No tmux window selected")
        end,
      },
    },
  }, function() end)
end

return {
  {
    "folke/snacks.nvim",
    opts = {
      bufdelete = {},
      picker = {
        hidden = true,
        ignored = true,
        exclude = { "node_modules", "dist" },
        sources = {
          explorer = {
            layout = {
              layout = {
                width = 30,
              },
            },
          },
        },
      },
      lazygit = {},
      terminal = {},
      statuscolumn = {
        left = { "sign", "mark" },
      },
    },
    keys = {
      {
        "<leader>be",
        function()
          Snacks.picker.buffers()
        end,
        desc = "Buffers",
      },
      {
        "<leader>ge",
        function()
          Snacks.picker.git_status()
        end,
        desc = "Git Status (Changes)",
      },
      {
        "<leader>se",
        function()
          Snacks.picker.lsp_symbols({
            layout = {
              preset = "sidebar",
              position = "left",
            },
          })
        end,
        desc = "LSP Symbols",
      },
      {
        "<leader>ld",
        function()
          Snacks.terminal("lazydocker", {
            win = {
              style = "float",
              width = 0.9,
              height = 0.9,
            },
          })
        end,
        desc = "Lazydocker (Snacks)",
      },
      {
        "<leader>te",
        function()
          open_tmux_windows_picker()
        end,
        desc = "Tmux Windows",
      },
      {
        "<leader>tt",
        function()
          Snacks.terminal.toggle(nil, {
            id = "persistent_term",
            win = {
              style = "bottom",
              height = 0.4,
            },
          })
        end,
        desc = "Toggle Persistent Terminal",
      },
      {
        "<leader>tT",
        function()
          Snacks.terminal.open(nil, {
            win = {
              style = "bottom",
              height = 0.4,
            },
          })
        end,
        desc = "New Terminal (Bottom)",
      },
      {
        "<leader>ff",
        function()
          Snacks.picker.files({ cwd = vim.fn.getcwd() })
        end,
        desc = "Find Files (CWD)",
      },
      {
        "<leader>fF",
        function()
          Snacks.picker.files()
        end,
        desc = "Find Files (Root)",
      },
      -- {
      --   "<leader>me",
      --   function()
      --     Snacks.picker.marks()
      --   end,
      --   desc = "Marks",
      -- },
    },
  },
}
