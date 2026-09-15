return {
	'tpope/vim-fugitive',
	cmd = { 'G', 'Git', 'GBrowse', 'GDelete', 'GMove', 'Gdiffsplit', 'Ggrep', 'Gread', 'Gvdiffsplit', 'Gwrite' },
	keys = {
		{ '<leader>gs', '<cmd>tab Git<cr>', desc = 'Open [G]it [S]tatus in a new tab' },
		{ '<leader>gc', '<cmd>Git commit<cr>', desc = '[G]it [C]ommit' },
		{ '<leader>gb', '<cmd>Git blame<cr>', desc = '[G]it [B]lame' },
		{ '<leader>g1', '<cmd>diffget LO<cr>', desc = 'Get changes from [1] Local' },
		{ '<leader>g2', '<cmd>diffget BA<cr>', desc = 'Get changes from [2] Base' },
		{ '<leader>g3', '<cmd>diffget RE<cr>', desc = 'Get changes from [3] Remote' },
		{ '<leader>gh', '<cmd>diffget //2<cr>', desc = 'Get changes from [h]eader/Base' },
		{ '<leader>gl', '<cmd>diffget //3<cr>', desc = 'Get changes from [l]ocal/Remote' },
	},
	config = function ()

		vim.keymap.set('n', '<leader>gs', ':tab Git <CR>', { desc = 'Open [G]it [S]tatus in a new tab' })
		vim.keymap.set('n', '<leader>gc', ':Git commit <CR>', { desc = '[G]it [C]ommit' })
		vim.keymap.set('n', '<leader>gb', ':Git blame <CR>', { desc = '[G]it [B]lame' })

		-- 3 way merge
		vim.keymap.set('n', '<leader>g1', ':diffget LO<CR>', { desc = 'Get changes from [1] Local' })
		vim.keymap.set('n', '<leader>g2', ':diffget BA<CR>', { desc = 'Get changes from [2] Base' })
		vim.keymap.set('n', '<leader>g3', ':diffget RE<CR>', { desc = 'Get changes from [3] Remote' })

		-- 3 Way diff
		vim.keymap.set('n', '<leader>gh', ':diffget //2<CR>', { desc = 'Get changes from [h]eader/Base' })
		vim.keymap.set('n', '<leader>gl', ':diffget //3<CR>', { desc = 'Get changes from [l]ocal/Remote' })

		-- Diffsplit in tab need to refactor later
		-- https://github.com/tpope/vim-fugitive/issues/1451
		vim.cmd 'au User FugitiveIndex nmap <buffer> dt :Gtabedit <Plug><cfile><Bar>Gdiffsplit<CR>'
	end

}
