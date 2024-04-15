-- ~/.config/nvim/lua/plugins/norminette/init.lua
local M = {}

M.setup = function ()
    -- Create a custom apigen namespace to make sure we don't mess
    -- with other diagnostics.
    M.namespace = vim.api.nvim_create_namespace("norminette")

    -- Create an autocommand which will run the check_current_buffer
    -- function whenever we enter or save the buffer.
    vim.api.nvim_create_autocmd({"BufWritePost", "BufEnter"}, {
        group = vim.api.nvim_create_augroup("Norminette", { clear = true }),
        -- apigen currently only parses annotations within *.api.go
        -- files so those are the only files we want to check within
        -- neovim as well.
        pattern = "*.c",
        callback = M.check_current_buffer,
    })
end

M.check_current_buffer = function ()
    -- Reset all diagnostics for our custom namespace. The second
    -- argument is the buffer number and passing in 0 will select
    -- the currently active buffer.
    vim.diagnostic.reset(M.namespace, 0)

    -- Get the path for the current buffer so we can pass that into
    -- the command below.
    local buf_path = vim.api.nvim_buf_get_name(0)

    -- Running `apigen -check FILE_PATH` will print error messages
    -- to stderr but won't generate any code.
    local cmd = "python3 -m norminette " .. buf_path

    -- You can also use vim.fn.system to run an external command.
    -- In our case the error output is printed on multiple lines.
    -- The first line will print "LINE:COL" and the second line the
    -- error message itself. vim.fn.systemlist will return a lua
    -- table containing each line instead of a single string. 
    local output = vim.fn.systemlist(cmd)
    local exit_code = vim.v.shell_error
    vim.diagnostic.config({ virtual_text = true })

    -- `apigen` exits with 0 on success and greater zero on error
    if (exit_code ~= 0) then
        -- parse line and col from the first line of the output
        -- TODO: should probably do some error checking here ;)
	for i, normerr in ipairs(output) do
		if (i ~= 1) then
			local line, col = string.match(normerr, "%(line: +(%d+), col: +(%d+)%)")
			-- vim.diagnostic.set allows you to set multiple diagnostics
			-- for the given buffer. We only set one because `apigen`
			-- currently exits on the first error it finds.
			vim.diagnostic.set(M.namespace, 0, {
			    {
				lnum = tonumber(line),
				col = tonumber(col),
				message = "Norme error: " .. string.match(normerr, "%(line: +%d+, col: +%d+%):	+(.*)$")
			    }
			})
		end
	end
    end
end

return M
