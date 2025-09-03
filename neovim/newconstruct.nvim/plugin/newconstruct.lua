-- plugin/newconstruct.lua

-- This code creates a user command that users can call, like :NewConstruct
-- It's wrapped in a check to prevent errors if the plugin is loaded more than once.
if not vim.fn.exists(":NewConstruct") then
  vim.api.nvim_create_user_command(
    "NewConstruct",
    function()
      -- When the command is run, it calls the 'generate' function
      -- from your main module located in lua/newconstruct/init.lua
      require("newconstruct").generate()
    end,
    {
      desc = "Generate a constructor for the Go type under the cursor",
    }
  )
end
