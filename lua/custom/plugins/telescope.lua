return { -- Fuzzy Finder (files, lsp, etc)
	'nvim-telescope/telescope.nvim',
	event = 'VimEnter',
	dependencies = {
		'nvim-lua/plenary.nvim',
		{ -- If encountering errors, see telescope-fzf-native README for installation instructions
			'nvim-telescope/telescope-fzf-native.nvim',
			build = 'make',
			cond = function()
				return vim.fn.executable 'make' == 1
			end,
		},
		{ 'nvim-telescope/telescope-ui-select.nvim' },
		{ 'nvim-telescope/telescope-project.nvim' },
		{ 'agoodshort/telescope-git-submodules.nvim' },
		{ 'nvim-telescope/telescope-symbols.nvim' },
		{ 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
	},
	config = function()
		-- See `:help telescope` and `:help telescope.setup()`
		require('telescope').setup {
			defaults = {
				file_ignore_patterns = {
					'%.git/',
					'node_modules/',
					'%.venv/',
					'venv/',
					'__pycache__/',
					'%.mypy_cache/',
					'%.pytest_cache/',
					'build/',
					'dist/',
				},
				mappings = {
					i = {
						['<c-enter>'] = 'to_fuzzy_refine',
						['<c-h>'] = 'which_key',
					},
				},
			},
			pickers = {
				find_files = {
					find_command = { 'rg', '--files', '--hidden', '--glob', '!.git/*' },
				},
			},
			extensions = {
				['ui-select'] = {
					require('telescope.themes').get_dropdown(),
				},
				project = {
					theme = 'dropdown',
					order_by = 'recent',
					cd_scope = { 'tab', 'window', 'global' },
					on_project_selected = function(prompt_bufnr)
						local actions = require 'telescope.actions'
						local project_actions = require 'telescope._extensions.project.actions'
						local utils = require 'telescope._extensions.project.utils'

						local scope = project_actions.get_cd_scope()
						local cmd = ({ tab = 'tcd', window = 'lcd', global = 'cd' })[scope] or 'tcd'
						local project_path = project_actions.get_selected_path(prompt_bufnr)
						actions.close(prompt_bufnr)
						utils.change_project_dir(project_path, cmd)
					end,
				},
			},
		}

		-- Enable Telescope extensions if they are installed
		pcall(require('telescope').load_extension, 'fzf')
		pcall(require('telescope').load_extension, 'ui-select')
		pcall(require('telescope').load_extension, 'git_submodules')
		pcall(require('telescope').load_extension, 'project')
		pcall(require('telescope').load_extension, 'symbols')

		local builtin = require 'telescope.builtin'
		local project_actions = require 'telescope._extensions.project.actions'
		require('custom.telescope.projects').setup()

		vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
		vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
		vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
		vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
		vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
		vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
		vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
		vim.keymap.set('n', '<leader>sD', function()
			builtin.diagnostics { bufnr = 0 }
		end, { desc = '[S]earch [D]iagnostics (buffer)' })
		vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
		vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
		vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })
		vim.keymap.set('n', '<c-o>', builtin.git_files, { desc = 'Search [O]pened Git Files' })
		vim.keymap.set('n', '<leader>sws', builtin.lsp_workspace_symbols, { desc = '[S]earch [W]orkspace [S]ymbols' })
		vim.keymap.set('n', '<leader>sj', builtin.jumplist, { desc = '[S]earch [J]ump list' })

		vim.keymap.set('n', '<leader>sp', function()
			require('telescope').extensions.project.project { display_type = 'minimal' }
		end, { desc = '[S]earch [P]rojects' })

		vim.keymap.set('n', '<leader>sP', function()
			require('telescope').extensions.project.project { display_type = 'full' }
		end, { desc = '[S]earch [P]rojects (full)' })

		vim.keymap.set('n', '<leader>spa', function()
			project_actions.add_project_cwd()
		end, { desc = '[S]earch [P]rojects: [A]dd cwd' })

		vim.keymap.set('n', '<leader>spg', function()
			require('custom.telescope.projects').add_project_from_current_buffer()
		end, { desc = '[S]earch [P]rojects: add from current buffer' })

		vim.keymap.set('n', '<leader>gdb', function()
			require('custom.telescope.git').diff_current_file_against_branch()
		end, { desc = '[G]it [D]iff current file vs [B]ranch' })

		vim.keymap.set('n', '<leader>gm', function()
			require('telescope').extensions.git_submodules.git_submodules()
		end, { desc = '[G]it Sub[M]odules' })

		vim.keymap.set('n', '<leader>/', function()
			builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
				winblend = 10,
				previewer = false,
			})
		end, { desc = '[/] Fuzzily search in current buffer' })


		vim.keymap.set('n', '<leader>se', function()
			builtin.symbols {
				sources = {'emoji', 'kaomoji', 'gitmoji', 'math', 'latxl' }
			}
		end, { desc = '[S]earch [E]mojis' })

		vim.keymap.set('n', '<leader>s/', function()
			builtin.live_grep {
				grep_open_files = true,
				prompt_title = 'Live Grep in Open Files',
			}
		end, { desc = '[S]earch [/] in Open Files' })

		vim.keymap.set('n', '<leader>sn', function()
			builtin.find_files { cwd = vim.fn.stdpath 'config' }
		end, { desc = '[S]earch [N]eovim files' })

		vim.keymap.set('n', '<c-f>', function()
			builtin.grep_string {
				search = vim.fn.input 'grep string > ',
				use_regex = true,
			}
		end)

		vim.keymap.set('n', '<leader>gco', builtin.git_branches, { desc = '[G]it [c]heckout [b]ranches' })
	end,
}
