return { -- Highlight, edit, and navigate code
	'nvim-treesitter/nvim-treesitter',
	build = ':TSUpdate',
	main = 'nvim-treesitter.configs', -- Sets main module to use for opts
	event = { 'BufReadPre', 'BufNewFile' },
	dependencies = {
		'nvim-treesitter/nvim-treesitter-textobjects',
	},
	-- [[ Configure Treesitter ]] See `:help nvim-treesitter`
	opts = {
		ensure_installed = {
			'bash',
			'bibtex',
			'c',
			'cpp',
			'diff',
			'dockerfile',
			'go',
			'graphql',
			'html',
			"java",
			"javascript",
			"jsdoc",
			"json",
			"jsonc",
			-- "jsonb",
			-- "jsonl",
			"latex",
			'lua',
			'luadoc',
			'markdown',
			'markdown_inline',
			'python',
			'query',
			'vim',
			'vimdoc',
			'yaml',
		},
		-- Autoinstall languages that are not installed
		-- (disabled for faster/offline-friendly startup; use :TSInstall/:TSUpdate)
		auto_install = false,
		highlight = {
			enable = true,
			-- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
			--  If you are experiencing weird indenting issues, add the language to
			--  the list of additional_vim_regex_highlighting and disabled languages for indent.
			additional_vim_regex_highlighting = { 'ruby' },
		},
		indent = { enable = true, disable = { 'ruby' } },
		incremental_selection = {
			enable = true,
			keymaps = {
				init_selection = 'gnn',
				node_incremental = 'grn',
				scope_incremental = 'grc',
				node_decremental = 'grm',
			},
		},
		textobjects = {
			move = {
				enable = true,
				set_jumps = true,
				goto_next_start = {
					[']f'] = '@function.outer',
				},
				goto_next_end = {
					[']F'] = '@function.outer',
				},
				goto_previous_start = {
					['[f'] = '@function.outer',
				},
				goto_previous_end = {
					['[F'] = '@function.outer',
				},
			},
			swap = {
				enable = true,
				swap_next = {
					[']a'] = '@parameter.inner',
				},
				swap_previous = {
					['[a'] = '@parameter.inner',
				},
			},
		},
	},
	config = function(_, opts)
		local function first_capture_node(capture)
			if type(capture) == 'table' then
				return capture[1]
			end
			return capture
		end

		local function patch_query_directives_for_nvim_012()
			local ok_query, ts_query = pcall(require, 'vim.treesitter.query')
			if not ok_query then
				return
			end

			local alias_map = {
				ex = 'elixir',
				pl = 'perl',
				sh = 'bash',
				uxn = 'uxntal',
				ts = 'typescript',
			}

			local function parser_from_info_string(injection_alias)
				local match = vim.filetype.match { filename = 'a.' .. injection_alias }
				return match or alias_map[injection_alias] or injection_alias
			end

			local directive_opts = vim.fn.has 'nvim-0.10' == 1 and { force = true, all = false } or true

			ts_query.add_directive('set-lang-from-info-string!', function(match, _, bufnr, pred, metadata)
				local capture_id = pred[2]
				local node = first_capture_node(match[capture_id])
				if not node then
					return
				end
				local ok_text, raw_text = pcall(vim.treesitter.get_node_text, node, bufnr, { metadata = metadata[capture_id] })
				if not ok_text or type(raw_text) ~= 'string' or raw_text == '' then
					return
				end
				metadata['injection.language'] = parser_from_info_string(raw_text:lower())
			end, directive_opts)
		end

		patch_query_directives_for_nvim_012()
		require('nvim-treesitter.configs').setup(opts)
	end,
	-- There are additional nvim-treesitter modules that you can use to interact
	-- with nvim-treesitter. You should go explore a few and see what interests you:
	--
	--    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
	--    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
	--    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
}
