-- Google Python Indentation Logic
-- This part defines the function that calculates the indentation.
local MAX_OFF = 50

function _G.GetGooglePythonIndent(lnum)
	vim.api.nvim_win_set_cursor(0, { lnum, 0 })

	local find_flags = 'bW'
	local syn_check =
	string.format("line('.') < %d ? 0 : (vim.fn.synIDattr(vim.fn.synID(line('.'), col('.'), 1), 'name') =~# '\\(Comment\\|String\\)$')", lnum - MAX_OFF)

	local par_pos = vim.fn.searchpairpos('(\\|{\\|\\[', '', ')\\|}\\|\\]', find_flags, syn_check)

	if par_pos[1] > 0 then
		local par_line = par_pos[1]
		local par_col = par_pos[2]
		local line_content = vim.api.nvim_buf_get_lines(0, par_line - 1, par_line, true)[1]

		if par_col ~= line_content:len() then
			return par_col
		end
	end

	-- Delegate to the default Python indent function if it exists,
	-- otherwise use a general C-style indent as a fallback.
	if vim.fn.exists '*python#GetIndent' == 1 then
		return vim.fn['python#GetIndent'](lnum)
	else
		return vim.fn.cindent(lnum)
	end
end

-- Configuration to apply the custom indentation for Python files.
-- This sets the 'indentexpr' for the current buffer to use the function defined above.
vim.opt_local.indentexpr = 'v:lua.GetGooglePythonIndent(v:lnum)'

-- These settings influence how Neovim handles indentation related to parentheses
-- and continuation lines, similar to the original VimL variables.
vim.opt_local.cinoptions = '&sw*2'
