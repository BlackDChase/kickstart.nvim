return { -- You can easily change to a different colorscheme.
	-- Change the name of the colorscheme plugin below, and then
	-- change the command in the config to whatever the name of that colorscheme is.

	-- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
	-- {
	-- 	priority = 1000, -- Make sure to load this before all the other start plugins.
	-- 	'folke/tokyonight.nvim',
	-- 	config = function()
	-- 		---@diagnostic disable-next-line: missing-fields
	-- 		require('tokyonight').setup {
	-- 			styles = {
	-- 				comments = { italic = false }, -- Disable italics in comments
	-- 			},
	-- 		}
	--
	-- 		-- Load the colorscheme here.
	-- 		-- Like many other themes, this one has different styles, and you could load
	-- 		-- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
	-- 		vim.cmd.colorscheme 'tokyonight-night'
	--
	-- 	end,
	--
	-- },
	-- {
	-- 	priority = 1000, -- Make sure to load this before all the other start plugins.
	-- 	'ellisonleao/gruvbox.nvim', -- Use the dedicated Lua port
	-- 	config = function()
	-- 		-- Optional: configure contrast, italics, etc.
	-- 		-- This function allows for comprehensive, native Lua setup.
	-- 		require('gruvbox').setup({
	-- 			terminal_colors = true, -- Use Gruvbox colors for the terminal
	-- 			contrast = 'medium',    -- or 'hard', 'soft'
	-- 			italic = {
	-- 				comments = true,
	-- 				keywords = true,
	-- 				functions = false,
	-- 				statements = false
	-- 			},
	-- 		})
	-- 		-- This executes the colorscheme load command.
	-- 		vim.cmd.colorscheme 'gruvbox'
	--
	-- 	end,
	-- 	-- OR
	-- },
	-- {
	-- 	'flazz/vim-colorschemes',
        -- priority = 1000,
	-- 	-- Your existing custom highlight groups are preserved
	-- 	vim.api.nvim_set_hl(0, "Normal", { bg = "none"}),
	-- 	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none"})
	-- }
	{
        'catppuccin/nvim',
        lazy = false, -- Mandatory for colorscheme loading
        priority = 1000,
        name = "catppuccin", -- Specify the plugin name explicitly
        config = function()
            -- Setup function for full configuration control
            require('catppuccin').setup {
                flavour = "mocha", -- Select the darkest theme variant (mocha, macchiato, frappe, latte)
                background = {
                    light = "latte",
                    dark = "mocha",
                },
                transparent_background = true, -- Set to false if you prefer a solid background
                integrations = {
                    -- Automatically integrate with common plugins (Treesitter, LSP, etc.)
                    treesitter = true,
                    lsp_trouble = true,
                    cmp = true,
                    gitsigns = true,
                },
                -- Optional: Customize the style of specific groups
                styles = {
                    comments = { "italic" },
                    conditionals = { "bold" },
                    keywords = { "bold" },
                },
            }

            -- Load the colorscheme
            vim.cmd.colorscheme "catppuccin"

            -- Set Normal and NormalFloat background to none for transparency (if enabled above)
            -- vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
            -- vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
        end,
    },
}
