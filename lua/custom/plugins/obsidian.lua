local function filter_workspaces(potential_workspaces)
    local validated_workspaces = {} -- Initialize as a sequentially indexed table (array/list)

    if type(potential_workspaces) ~= 'table' then
        return validated_workspaces
    end

    for _, ws in ipairs(potential_workspaces) do
        -- Ensure required keys exist and are strings
        if ws.name and ws.path and type(ws.name) == 'string' and type(ws.path) == 'string' then
            
            local expanded_path = vim.fn.expand(ws.path)
            
            -- Check if the directory exists (vim.fn.isdirectory returns 1 for success)
            if vim.fn.isdirectory(expanded_path) == 1 then
                
                -- Use table.insert to append to the list, maintaining the array format
                table.insert(validated_workspaces, { 
                    name = ws.name, 
                    path = expanded_path 
                })
            end
        end
    end

    return validated_workspaces
end

return { -- FOr Markdown Files, espeically Obsidian Notes
	'obsidian-nvim/obsidian.nvim',
	version = '*', -- recommended, use latest release instead of latest commit
	ft = "markdown",
	event = {
		'BufReadPre ' .. vim.fn.expand '~' .. '/Documents/obsidian/*.md',
		'BufNewFile ' .. vim.fn.expand '~' .. '/Documents/obsidian/*.md',
	},
	---@module 'obsidian'
	---@type obsidian.config
	opts = {
		workspaces = filter_workspaces({
			{
				name = 'work',
				path = vim.fn.expand '~' .. '/Documents/obsidian/sai',
			},
			{
				name = 'secret',
				path = vim.fn.expand '~' .. '/Documents/obsidian/sai/jazzx/secret/',
			},
			{
				name = "personal",
				path = vim.fn.expand '~' .. '/Documents/obsidian/MainVault',
			},
			{
				name = "home",
				path = vim.fn.expand '~' .. '/Documents/obsidian/HomePlan',
			}
		}),

		---@class obsidian.config.TemplateOpts
		---
		---@field folder string|obsidian.Path|?
		---@field date_format string|?
		---@field time_format string|?
		--- A map for custom variables, the key should be the variable and the value a function.
		--- Functions are called with obsidian.TemplateContext objects as their sole parameter.
		--- See: https://github.com/obsidian-nvim/obsidian.nvim/wiki/Template#substitutions
		---@field substitutions table<string, (fun(ctx: obsidian.TemplateContext):string)|(fun(): string)|string>|?
		---@field customizations table<string, obsidian.config.CustomTemplateOpts>|?
		template = {
			folder =  vim.fn.expand '~' .. '/Documents/obsidian/ObsidianUtils/Templates/',

			---@class obsidian.config.CustomTemplateOpts
			---
			---@field notes_subdir? string
			---@field note_id_func? (fun(title: string|?, path: obsidian.Path|?): string)
			customizations = {},
		},

		legacy_commands = false,
		-- Optional, completion of wiki links, local markdown links, and tags using nvim-cmp.
		completion = {
			-- Set to false to disable completion.
			blink = true,
			nvim_cmp = false,
			-- Trigger completion at 2 chars.
			min_chars = 2,
			match_case = true,
			create_new = true,
		},

		-- Optional, configure key mappings. These are the defaults. If you don't want to set any keymappings this
		-- way then set 'mappings = {}'.
		mappings = {
			-- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
			[";d"] = {
				action = function()
					return require("obsidian").util.gf_passthrough()
				end,
				opts = { noremap = false, expr = true, buffer = true },
			},
			-- Toggle check-boxes.
			["<leader>ch"] = {
				action = function()
					return require("obsidian").util.toggle_checkbox()
				end,
				opts = { buffer = true },
			},
		},

		log_level = vim.log.levels.INFO,
		-- Optional, customize how markdown links are formatted.
		-- markdown_link_func = function(opts)
		--   return require("obsidian.util").markdown_link(opts)
		-- end,
		-- Optional, customize how wiki links are formatted. You can set this to one of:
		--  * "use_alias_only", e.g. '[[Foo Bar]]'
		--  * "prepend_note_id", e.g. '[[foo-bar|Foo Bar]]'
		--  * "prepend_note_path", e.g. '[[foo-bar.md|Foo Bar]]'
		--  * "use_path_only", e.g. '[[foo-bar.md]]'
		-- Or you can set it to a function that takes a table of options and returns a string, like this:
		-- wiki_link_func = require('obsidian.util').wiki_link_id_prefix 'use_alias_only',
		-- Either 'wiki' or 'markdown'.

		-- note_id_func = require("obsidian.util").zettel_id,
		-- markdown_link_func = require("obsidian.util").markdown_link,
		wiki_link_func = function()
			return require('obsidian.util').wiki_link_id_prefix("use_alias_only")
		end,

		-- Either 'wiki' or 'markdown'.
		preferred_link_style = 'wiki',

		---@class obsidian.config.FrontmatterOpts
		---
		--- Whether to enable frontmatter, boolean for global on/off, or a function that takes filename and returns boolean.
		---@field enabled? (fun(fname: string?): boolean)|boolean
		---
		--- Function to turn Note attributes into frontmatter.
		---@field func? fun(note: obsidian.Note): table<string, any>
		--- Function that is passed to table.sort to sort the properties, or a fixed order of properties.
		---
		--- List of string that sorts frontmatter properties, or a function that compares two values, set to vim.NIL/false to do no sorting
		---@field sort? string[] | (fun(a: any, b: any): boolean) | vim.NIL | boolean
		frontmatter = {
			enabled = true,
			sort = { 'id', 'aliases', 'tags' },
		},

		picker = {
			-- Set your preferred picker. Can be one of 'telescope.nvim', 'fzf-lua', or 'mini.pick'.
			name = 'telescope.nvim',
			-- Optional, configure key mappings for the picker. These are the defaults.
			-- Not all pickers support all mappings.
			mappings = {
				-- Create a new note from your query.
				new = '<C-x>',
				-- Insert a link to the selected note.
				insert_link = '<leader>l',
			},
		},

		-- Optional, configure additional syntax highlighting / extmarks.
		-- This requires you have `conceallevel` set to 1 or 2. See `:help conceallevel` for more details.
		-- ui = {
		--   enable = true, -- set to false to disable all additional syntax features
		--   update_debounce = 200, -- update delay after a text change (in milliseconds)
		--   -- Define how various check-boxes are displayed
		--   checkboxes = {
		--     -- NOTE: the 'char' value has to be a single character, and the highlight groups are defined below.
		-- 	 --
		--     [' '] = { char = '󰄱', hl_group = 'ObsidianTodo' },
		--     ['x'] = { char = '', hl_group = 'ObsidianDone' },
		--     ['>'] = { char = '', hl_group = 'ObsidianRightArrow' },
		--     ['~'] = { char = '󰰱', hl_group = 'ObsidianTilde' },
		--     -- Replace the above with this if you don't have a patched font:
		--     -- [" "] = { char = "☐", hl_group = "ObsidianTodo" },
		--     -- ["x"] = { char = "✔", hl_group = "ObsidianDone" },
		--
		--     -- You can also add more custom ones...
		--   },
		--   -- Use bullet marks for non-checkbox lists.
		--   bullets = { char = '•', hl_group = 'ObsidianBullet' },
		--   external_link_icon = { char = '', hl_group = 'ObsidianExtLinkIcon' },
		--   -- Replace the above with this if you don't have a patched font:
		--   -- external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
		--   reference_text = { hl_group = 'ObsidianRefText' },
		--   highlight_text = { hl_group = 'ObsidianHighlightText' },
		--   tags = { hl_group = 'ObsidianTag' },
		--   block_ids = { hl_group = 'ObsidianBlockID' },
		--   hl_groups = {
		--     -- The options are passed directly to `vim.api.nvim_set_hl()`. See `:help nvim_set_hl`.
		--     ObsidianTodo = { bold = true, fg = '#f78c6c' },
		--     ObsidianDone = { bold = true, fg = '#89ddff' },
		--     ObsidianRightArrow = { bold = true, fg = '#f78c6c' },
		--     ObsidianTilde = { bold = true, fg = '#ff5370' },
		--     ObsidianBullet = { bold = true, fg = '#89ddff' },
		--     ObsidianRefText = { underline = true, fg = '#c792ea' },
		--     ObsidianExtLinkIcon = { fg = '#c792ea' },
		--     ObsidianTag = { italic = true, fg = '#89ddff' },
		--     ObsidianBlockID = { italic = true, fg = '#89ddff' },
		--     ObsidianHighlightText = { bg = '#75662e' },
		--   },
		-- },
	},
}
