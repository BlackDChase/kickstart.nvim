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

    -- Optional, completion of wiki links, local markdown links, and tags using nvim-cmp.
    completion = {
      -- Set to false to disable completion.
      nvim_cmp = true,
      -- Trigger completion at 2 chars.
      min_chars = 2,
    },

    -- Optional, customize how wiki links are formatted. You can set this to one of:
    --  * "use_alias_only", e.g. '[[Foo Bar]]'
    --  * "prepend_note_id", e.g. '[[foo-bar|Foo Bar]]'
    --  * "prepend_note_path", e.g. '[[foo-bar.md|Foo Bar]]'
    --  * "use_path_only", e.g. '[[foo-bar.md]]'
    -- Or you can set it to a function that takes a table of options and returns a string, like this:
    wiki_link_func = function()
      return require('obsidian.util').wiki_link_id_prefix 'use_alias_only'
    end,
  },

  -- Optional, customize how markdown links are formatted.
  -- markdown_link_func = function(opts)
  --   return require("obsidian.util").markdown_link(opts)
  -- end,

  -- Either 'wiki' or 'markdown'.
  preferred_link_style = 'wiki',

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
  ui = {
    enable = true, -- set to false to disable all additional syntax features
    update_debounce = 200, -- update delay after a text change (in milliseconds)
    -- Define how various check-boxes are displayed
    checkboxes = {
      -- NOTE: the 'char' value has to be a single character, and the highlight groups are defined below.
      [' '] = { char = '󰄱', hl_group = 'ObsidianTodo' },
      ['x'] = { char = '', hl_group = 'ObsidianDone' },
      ['>'] = { char = '', hl_group = 'ObsidianRightArrow' },
      ['~'] = { char = '󰰱', hl_group = 'ObsidianTilde' },
      -- Replace the above with this if you don't have a patched font:
      -- [" "] = { char = "☐", hl_group = "ObsidianTodo" },
      -- ["x"] = { char = "✔", hl_group = "ObsidianDone" },

      -- You can also add more custom ones...
    },
    -- Use bullet marks for non-checkbox lists.
    bullets = { char = '•', hl_group = 'ObsidianBullet' },
    external_link_icon = { char = '', hl_group = 'ObsidianExtLinkIcon' },
    -- Replace the above with this if you don't have a patched font:
    -- external_link_icon = { char = "", hl_group = "ObsidianExtLinkIcon" },
    reference_text = { hl_group = 'ObsidianRefText' },
    highlight_text = { hl_group = 'ObsidianHighlightText' },
    tags = { hl_group = 'ObsidianTag' },
    block_ids = { hl_group = 'ObsidianBlockID' },
    hl_groups = {
      -- The options are passed directly to `vim.api.nvim_set_hl()`. See `:help nvim_set_hl`.
      ObsidianTodo = { bold = true, fg = '#f78c6c' },
      ObsidianDone = { bold = true, fg = '#89ddff' },
      ObsidianRightArrow = { bold = true, fg = '#f78c6c' },
      ObsidianTilde = { bold = true, fg = '#ff5370' },
      ObsidianBullet = { bold = true, fg = '#89ddff' },
      ObsidianRefText = { underline = true, fg = '#c792ea' },
      ObsidianExtLinkIcon = { fg = '#c792ea' },
      ObsidianTag = { italic = true, fg = '#89ddff' },
      ObsidianBlockID = { italic = true, fg = '#89ddff' },
      ObsidianHighlightText = { bg = '#75662e' },
    },
  },
}
