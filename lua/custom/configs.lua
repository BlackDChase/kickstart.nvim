-- Configurations `C`

-- leader, used as <leader>
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
--
--  Notice listchars is set using `vim.opt` instead of `vim.o`.
--  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
--   See `:help lua-options`
--   and `:help lua-options-guide`
-- vim.opt.list = true
-- vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
-- Diff b/w vim.opt and vim.o (I prefer opt)

-- Unable local nvim config
vim.opt.exrc = true

-- [[ Visuals ]]

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false
-- vim.opt.autoread = true
-- vim.opt.syntax = "on"
-- vim.opt.cmdheight = 2
--
-- As you scroll down load extra 8 lines
-- Minimal number of screen lines to keep above and below the cursor.
vim.opt.scrolloff = 10
vim.opt.isfname:append '@-@'
vim.opt.updatetime = 50
-- Good colors
-- vim.opt.termguicolors = true

-- To show column 80 is max column which should be have been written
vim.opt.signcolumn = 'yes'
vim.opt.colorcolumn = '80,120'
vim.opt.wrap = true
-- vim.opt.wrapmargin = 130
-- Wrap line in convenient places instead of breaking words
vim.opt.linebreak = true

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true -- false

-- Numbering
-- Make line numbers default
vim.opt.nu = true
-- You can also add relative line numbers, to help with jumping.
vim.opt.relativenumber = true

-- Search Highlighting
-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- [[ Saving ]]
--
-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.opt.confirm = true
-- Swap file
vim.opt.swapfile = false
vim.opt.backup = false

-- Undo
vim.opt.undofile = true
vim.opt.undodir = os.getenv 'HOME' .. '/.vim/undodir'

-- [[ Behavior ]]

-- Cursor
-- vim.opt.guicursor = ""
-- To enable mouse mode, can be useful for resizing splits for example!
vim.opt.mouse = 'a'

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function()
  -- NOTE: Mac uses unnamedplus, Linux may use unnamed if issues arise
  vim.opt.clipboard = 'unnamedplus'
end)

-- Rip grep
vim.g.rg_derive_root = true

-- Indentation
-- vim.opt.autoindent = true
-- vim.opt.smartindent = true
-- vim.opt.smarttab = true
-- vim.opt.expandtab = true
-- Enable break indent
vim.opt.breakindent = true
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.tabstop = 4

-- Lifestyle changes
-- Command histoy
-- vim.opt.hidden = false

-- Tabline
-- vim.opt.tabline = true

-- Decrease mapped sequence wait time
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Preview substitutions live, as you type!
vim.opt.inccommand = 'split'

-- Show which line your cursor is on
vim.opt.cursorline = true
