-- lua/newconstruct/init.lua

local M = {}

--- Calls the newconstruct tool and inserts the generated code.
function M.generate()
  local executable = "newconstruct"

  -- 1. Check if the binary is available.
  if vim.fn.executable(executable) == 0 then
    vim.notify(
      "newconstruct: executable not found in PATH. Please run 'go install github.com/ddromanidis/newconstruct@latest'",
      vim.log.levels.ERROR,
      { title = "NewConstruct Plugin" }
    )
    return
  end

  -- 2. Get Neovim context.
  local file_path = vim.fn.expand('%:p')
  local line_num = vim.api.nvim_win_get_cursor(0)[1]

  -- 3. Build and run the command.
  local command = { executable, "-file=" .. file_path, "-line=" .. tostring(line_num) }

  vim.fn.jobstart(command, {
    stdout_buffered = true,
    on_exit = function(_, exit_code, _)
      if exit_code ~= 0 then
        vim.notify("newconstruct: tool failed with exit code " .. exit_code, vim.log.levels.ERROR)
      end
    end,
    on_stdout = function(_, data, _)
      local lines_to_insert = {}
      for _, line in ipairs(data) do
        if line ~= "" then
          table.insert(lines_to_insert, line)
        end
      end

      if #lines_to_insert == 0 then
        vim.notify("newconstruct: no output received from tool", vim.log.levels.WARN)
        return
      end

      -- 4. Insert the generated code into the buffer.
      vim.api.nvim_buf_set_lines(0, line_num, line_num, false, lines_to_insert)
      vim.notify("Constructor generated!", vim.log.levels.INFO)
    end,
  })
end

return M
