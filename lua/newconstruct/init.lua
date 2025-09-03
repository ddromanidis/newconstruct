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

  -- New logic to find the end of the type definition
  local insertion_line = line_num
  local current_line_content = vim.api.nvim_buf_get_lines(0, line_num - 1, line_num, false)[1]

  if current_line_content and string.find(current_line_content, "struct") then
    local original_cursor = vim.api.nvim_win_get_cursor(0)
    -- Search for the opening brace from the current line downwards (within a reasonable range)
    local open_brace_pos = vim.fn.searchpos('{', 'nW', line_num + 20)

    if open_brace_pos and open_brace_pos[1] > 0 then
      -- Temporarily move cursor to the opening brace
      vim.api.nvim_win_set_cursor(0, open_brace_pos)
      -- Find the matching closing brace
      local close_brace_pos = vim.fn.searchpairpos('{', '', '}', 'n')
      if close_brace_pos and close_brace_pos[1] > 0 then
        insertion_line = close_brace_pos[1]
      end
    end
    -- Restore original cursor position
    vim.api.nvim_win_set_cursor(0, original_cursor)
  end

  -- 3. Build and run the command.
  local command = { executable, "-file=" .. file_path, "-line=" .. tostring(line_num) }
  local stderr_lines = {}

  vim.fn.jobstart(command, {
    stdout_buffered = true,
    stderr_buffered = true,

    on_stderr = function(_, data, _)
      for _, line in ipairs(data) do
        if line ~= "" then
          table.insert(stderr_lines, line)
        end
      end
    end,

    on_exit = function(_, exit_code, _)
      if exit_code ~= 0 then
        local err_message = table.concat(stderr_lines, "\n")
        vim.notify(
          "newconstruct: tool failed.\n" .. err_message,
          vim.log.levels.ERROR,
          { title = "NewConstruct Plugin" }
        )
      end
    end,

    on_stdout = function(_, data, _)
      -- Start with a blank line for better formatting
      local lines_to_insert = { "" }
      for _, line in ipairs(data) do
        if line ~= "" then
          table.insert(lines_to_insert, line)
        end
      end

      if #lines_to_insert <= 1 then
        -- This message is now less important, as on_exit will show the real error.
        -- We only show it if the tool exited successfully but produced no output.
        if #stderr_lines == 0 then
          vim.notify("newconstruct: no output received from tool", vim.log.levels.WARN)
        end
        return
      end

      -- 4. Insert the generated code at the calculated line.
      vim.api.nvim_buf_set_lines(0, insertion_line, insertion_line, false, lines_to_insert)
      vim.notify("Constructor generated!", vim.log.levels.INFO)
    end,
  })
end

return M

