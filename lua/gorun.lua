local M = {}

---@class gorun.Config
---@field name string: name of run
---@field cwd string: current directory
---@field buildFlags string: build flags
---@field tmux_target string: which to running. Format: {sessionName}:{windowName}.{panelIndex} or {windowName}.{panelIndex}

--- Show UI to select configurations
--- Configuration should be follow https://github.com/golang/vscode-go/blob/master/docs/debugging.md#launchjson-attributes
---@param path string?: path to file configurations
function M.open(path)
  local configs = M.load_config_file(path)

  if #configs == 0 then
    vim.notify "Configurations not found"
    return
  end

  local opts = {
    prompt = "Select❯ ",
    format_item = function(item)
      return "Run " .. item.name
    end,
  }

  vim.ui.select(configs, opts, M.on_choice)
end

--- Handle selected item
---@param item gorun.Config
function M.on_choice(item, _)
  if not item then
    return
  end

  vim.notify(string.format("Running %s at %s", item.name, item.tmux_target), vim.log.levels.INFO)

  local commands = {
    "C-c",
    string.format("cd %s", item.cwd),
    string.format("go build %s -o %s", item.buildFlags, item.name),
    "clear",
    string.format("./%s", item.name),
  }

  for _, command in ipairs(commands) do
    vim.cmd(string.format([[exe 'silent !tmux send-keys -t %s %q ENTER']], item.tmux_target, command))
  end
end

--- Return default path. Like: {workspaceFolder}/.vscode/launch.json
--- @return string
function M.default_path()
  -- Determine the project root using LSP
  local lsp_clients = vim.lsp.get_clients { bufnr = vim.api.nvim_get_current_buf() }
  for _, client in ipairs(lsp_clients) do
    if client.config.root_dir then
      return client.config.root_dir .. "/.vscode/launch.json"
    end
  end

  local vscode_root = vim.fs.find(".vscode", { path = vim.fn.getcwd(), upward = true })[1]
  if vscode_root then
    return vscode_root .. "/launch.json"
  end

  return vim.fn.getcwd() .. "/.vscode/launch.json"
end

--- Load configurations from file.
--- File fomat like https://code.visualstudio.com/docs/editor/debugging#_launchjson-attributes
---@param path string?
---@return gorun.Config[]
function M.load_config_file(path)
  local resolved_path = path or M.default_path()
  local result = {}

  local fp = io.open(resolved_path, "r")
  if not fp then
    return result
  end

  local json = fp:read "*a"
  local ok, data = pcall(vim.json.decode, json)

  if not ok or type(data) ~= "table" then
    vim.notify(string.format("Error parsing: %s", data), vim.log.levels.ERROR)
    return result
  end

  if not data.configurations then
    vim.notify("launch.json must have a 'configurations' key", vim.log.levels.ERROR)
    return result
  end

  if type(data.configurations) ~= "table" then
    vim.notify("'configurations' must is array", vim.log.levels.ERROR)
    return result
  end

  for _, configRaw in ipairs(data.configurations) do
    -- validate field here
    assert(configRaw.name, "Configuration in launch.json must have a 'name' key")
    assert(configRaw.cwd, "Configuration in launch.json must have a 'cwd' key")
    assert(configRaw.tmux_target, "Configuration in launch.json must have a 'tmux_target' key")

    local temp = {
      name = configRaw.name,
      cwd = configRaw.cwd,
      tmux_target = configRaw.tmux_target,
      buildFlags = configRaw.buildFlags or "",
    }

    table.insert(result, temp)
  end

  return result
end

return M
