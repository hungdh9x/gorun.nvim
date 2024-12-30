vim.api.nvim_create_user_command("GoRun", function()
  require("gorun").open()
end, {})
