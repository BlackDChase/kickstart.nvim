-- Adds git related signs to the gutter, as well as utilities for managing changes
-- NOTE: gitsigns is already included in init.lua but contains only the base
-- config. This will add also the recommended keymaps.

return {
	{
		'lewis6991/gitsigns.nvim',
		event = 'BufWritePost',
		cmd = 'Gitsigns',
		keys = {
			{ ']c', function()
				if vim.wo.diff then vim.cmd.normal { ']c', bang = true } else require('gitsigns').nav_hunk 'next' end
			end, desc = 'Jump to next git [c]hange' },
			{ '[c', function()
				if vim.wo.diff then vim.cmd.normal { '[c', bang = true } else require('gitsigns').nav_hunk 'prev' end
			end, desc = 'Jump to previous git [c]hange' },
			{ '<leader>hs', function() require('gitsigns').stage_hunk() end, desc = 'git [s]tage hunk' },
			{ '<leader>hs', function() require('gitsigns').stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, mode = 'v', desc = 'git [s]tage hunk' },
			{ '<leader>hr', function() require('gitsigns').reset_hunk() end, desc = 'git [r]eset hunk' },
			{ '<leader>hr', function() require('gitsigns').reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, mode = 'v', desc = 'git [r]eset hunk' },
			{ '<leader>hbs', function() require('gitsigns').stage_buffer() end, desc = '[B]uffer - git [S]tage' },
			{ '<leader>hbr', function() require('gitsigns').reset_buffer() end, desc = 'buffer git [R]eset' },
			{ '<leader>hu', function() require('gitsigns').stage_hunk() end, desc = 'git [u]ndo stage hunk' },
			{ '<leader>hp', function() require('gitsigns').preview_hunk() end, desc = 'git [p]review hunk' },
			{ '<leader>hfb', function() require('gitsigns').blame_line { full = true } end, desc = 'git [f]ull [b]lame' },
			{ '<leader>hb', function() require('gitsigns').blame_line() end, desc = 'git [b]lame line' },
			{ '<leader>hd', function() require('gitsigns').diffthis() end, desc = 'git [d]iff against index' },
			{ '<leader>hdc', function() require('gitsigns').diffthis '@' end, desc = 'git [D]iff against last [c]ommit' },
			{ '<leader>htb', function() require('gitsigns').toggle_current_line_blame() end, desc = '[T]oggle git show [b]lame line' },
			{ '<leader>htD', function() require('gitsigns').preview_hunk_inline() end, desc = '[T]oggle git show [D]eleted' },
			{ 'hs', '<cmd>Gitsigns select_hunk<cr>', mode = { 'o', 'x' }, desc = '[H]unk [S]elect' },
		},
		config = function(_, opts)
			opts.signs = {
				add          = { text = '+' },
				change       = { text = '~' },
				delete       = { text = '_' },
				topdelete    = { text = '‾' },
				changedelete = { text = '|' },
				untracked    = { text = '┆' },
			}
			require('gitsigns').setup(opts)
		end,

		opts = {
			on_attach = function(bufnr)
				if vim.b[bufnr].large_file_mode then
					return false
				end

				local gitsigns = require 'gitsigns'

				local function map(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, l, r, opts)
				end

				-- Navigation
				map('n', ']c', function()
					if vim.wo.diff then
						vim.cmd.normal { ']c', bang = true }
					else
						gitsigns.nav_hunk 'next'
					end
				end, { desc = 'Jump to next git [c]hange' })

				map('n', '[c', function()
					if vim.wo.diff then
						vim.cmd.normal { '[c', bang = true }
					else
						gitsigns.nav_hunk 'prev'
					end
				end, { desc = 'Jump to previous git [c]hange' })

				-- Actions
				-- visual mode
				map('v', '<leader>hs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [s]tage hunk' })
				map('v', '<leader>hr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'git [r]eset hunk' })
				-- normal mode
				map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
				map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
				map('n', '<leader>hbs', gitsigns.stage_buffer, { desc = '[B]uffer - git [S]tage' })
				map('n', '<leader>hbr', gitsigns.reset_buffer, { desc = 'buffer git [R]eset' })
				map('n', '<leader>hu', gitsigns.stage_hunk, { desc = 'git [u]ndo stage hunk' })
				map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
				map('n', '<leader>hfb', function() gitsigns.blame_line { full = true } end, { desc = 'git [f]ull [b]lame' })
				map('n', '<leader>hb', gitsigns.blame_line, { desc = 'git [b]lame line' })
				map('n', '<leader>hd', gitsigns.diffthis, { desc = 'git [d]iff against index' })
				map('n', '<leader>hdc', function()
					gitsigns.diffthis '@'
				end, { desc = 'git [D]iff against last [c]ommit' })
				-- Toggles
				map('n', '<leader>htb', gitsigns.toggle_current_line_blame, { desc = '[T]oggle git show [b]lame line' })
				map('n', '<leader>htD', gitsigns.preview_hunk_inline, { desc = '[T]oggle git show [D]eleted' })

				-- Text object
				map({'o', 'x'}, 'hs', ':<C-U>Gitsigns select_hunk<CR>', {desc = '[H]unk [S]elect'})
			end,
		},
	},
}
