local M = {}

M.setup = function ()
    M.namespace = vim.api.nvim_create_namespace("norminette")

    vim.api.nvim_create_autocmd({"BufWritePost", "BufEnter"}, {
        group = vim.api.nvim_create_augroup("Norminette", { clear = true }),
        pattern = {"*.c", "*.h"},
        callback = M.check_current_buffer,
    })
end

M.check_current_buffer = function ()
    vim.diagnostic.reset(M.namespace, 0)

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
				diagnostic.message = "Norme error: " .. diagnostic.message
				table.insert(diagnostics, diagnostic)
			end
		end
		vim.diagnostic.set(M.namespace, 0, diagnostics)
    end
end

return M
