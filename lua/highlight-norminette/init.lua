local M = {}

M.setup = function ()
    M.namespace = vim.api.nvim_create_namespace("highlight-norminette")

    vim.api.nvim_create_autocmd({"BufWritePost", "BufEnter"}, {
        group = vim.api.nvim_create_augroup("Highlight-Norminette", { clear = true }),
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
	local diagnostics = {}
	for i, normerr in ipairs(output) do
		if (i ~= 1) then
			local diagnostic = vim.diagnostic.match(normerr, "%(line: +(%d+), col: +(%d+)%):	+(.*)$", {"lnum","col","message"})
			diagnostic.message = "Norme error: " .. diagnostic.message
			vim.fn.systemlist("echo " .. diagnostic.message .. " >> ~/Documents/lalalog")
			table.insert(diagnostics, diagnostic)
		end
	end
	vim.diagnostic.set(M.namespace, 0, diagnostics)
end

return M
