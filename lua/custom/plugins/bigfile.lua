return {
    -- The plugin should be a table entry within the return table
    {
        'LunarVim/bigfile.nvim',
        -- Priority is usually unnecessary if lazy loading is used,
        -- but kept for compliance with your original intent (1001)
        priority = 1001,
        -- lazy = false is NOT recommended here. Let the plugin manager
        -- determine when to load it based on the file size detection,
        -- or use the 'ft' (filetype) or 'cmd' keys if needed.

        -- Encapsulate setup logic in the config function
        config = function()
            require("bigfile").setup {
                filesize = 10, -- Recommended: Increase threshold to 10 MiB for realistic use
                pattern = { "*" },
                features = {
                    "indent_blankline",
                    "illuminate",
                    "lsp",
                    "treesitter",
                    "syntax",
                    "matchparen",
                    "vimopts",
                    "filetype",
                },
            }
        end,
    },
}
