return { -- FOr Markdown Files, espeically Obsidian Notes
  'obsidian-nvim/obsidian.nvim',
  version = '*', -- recommended, use latest release instead of latest commit
  -- ft = "markdown",
  -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
  event = {
    -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
    -- refer to `:h file-pattern` for more examples
    'BufReadPre ~/Documents/obsidian/*.md',
    'BufNewFile ~/Documents/obsidian/*.md',
  },
  ---@module 'obsidian'
  ---@type obsidian.config
  opts = {
    workspaces = {
      {
        name = 'work',
        path = '~/Documents/obsidian/sai',
      },
      -- {
      --   name = "work",
      --   path = "~/vaults/work",
      -- },
    },
    template = {
      subdir = '~/Documents/obsidian/ObsidianUtils/Templates/',
    },
  },
}
