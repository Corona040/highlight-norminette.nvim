local M = {}

local enable = true

M.setup = function ()
    M.namespace = vim.api.nvim_create_namespace("highlight-norminette")

    vim.api.nvim_create_autocmd({"BufWritePost", "BufEnter"}, {
        group = vim.api.nvim_create_augroup("Highlight-Norminette", { clear = true }),
        pattern = {"*.c", "*.h"},
        callback = M.check_current_buffer,
    })
	vim.api.nvim_create_user_command("NormeEnable", M.enable, {})
	vim.api.nvim_create_user_command("NormeDisable", M.disable, {})
	vim.api.nvim_create_user_command("NormeToggle", M.toggle, {})
end

M.enable = function()
	enable = true
	M.check_current_buffer()
end

M.disable = function()
	enable = false
    vim.diagnostic.reset(M.namespace, 0)
end

M.toggle = function()
	if enable then
		M.disable()
	else
		M.enable()
	end
end

M.check_current_buffer = function ()
    vim.diagnostic.reset(M.namespace, 0)
	if enable then
		local buf_path = vim.api.nvim_buf_get_name(0)

		local cmd = "python3 -m norminette " .. buf_path

		local output = vim.fn.systemlist(cmd)
		local exit_code = vim.v.shell_error

		vim.diagnostic.config({ virtual_text = true })
		if (exit_code ~= 0) then
			local diagnostics = {}
			for i, normerr in ipairs(output) do
				if (i ~= 1) then
					local diagnostic = vim.diagnostic.match(normerr, "%(line: +(%d+), col: +(%d+)%):	+(.*)$", {"lnum","col","message"})
					if not (diagnostic == nil) then
						diagnostic.message = "Norme error: " .. diagnostic.message
						table.insert(diagnostics, diagnostic)
					end
				end
			end
			if not (next(diagnostics) == nil) then
				vim.diagnostic.set(M.namespace, 0, diagnostics)
			end
		end
	end
end

return M
