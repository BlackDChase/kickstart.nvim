-- Remaps `R`

-- Remaps are saved in a way: (vim mode, keystrokes mapping, action defination)
--  See `:help vim.keymap.set()`

-- [[ Saving remaps ]]
vim.keymap.set({ 'n', 'v' }, 'S', vim.cmd.update)
vim.keymap.set({ 'n', 'v' }, '|', vim.cmd.q)
-- Vertical changes exit save
vim.keymap.set('i', '<C-c', '<ESC>')

-- No Operation when exidental Q
vim.keymap.set('n', 'Q', '<nop>')

-- [[ Basic Keymaps ]]

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- [[ Search Highlighting ]]
-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
-- vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<ESC>', vim.cmd.noh)

-- UP DOWN without moving cursor
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', '<C-d>', '<C-d>zz')

-- Same thing as above but with search
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')
-- zz to center the screen
-- zv to open folds

-- if wrap is set to true
-- Then uncomment the below lines: j/k will travers virtual lines
-- vim.keymap.set("n","j","gj")
-- vim.keymap.set("n","k","gk")
-- vim.keymap.set("v","j","gj")
-- vim.keymap.set("v","k","gk")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Buffer
vim.keymap.set('n', '<tab>', vim.cmd.bn)
vim.keymap.set('n', '<s-tab>', vim.cmd.bp)
vim.keymap.set('n', '<leader><tab>', vim.cmd.bd)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- [[ Fast writing remaps ]]
-- Insert blank line after current line
vim.keymap.set('n', 'J', 'i<CR><ESC>')
-- Append this line to the line above
vim.keymap.set('n', 'K', 'mzJ`z')
-- Highlited Move
vim.keymap.set('v', 'J', '>+1<CR>gv=gv')
vim.keymap.set('v', 'K', '<-2<CR>gv=gv')

-- Paste without messing up the buffer
vim.keymap.set('x', '<leader>p', '"_dP')
vim.keymap.set({ 'n', 'v' }, '<leader>p', '"_d')
-- Yank para
vim.keymap.set({ 'n', 'v' }, '<leader>y', '"+y')
vim.keymap.set({ 'n', 'v' }, '<leader>Y', '"+Y')

-- Quick fix navigation
-- vim.keymap.set('n', '<C-l>', vim.cmd.lprev)
-- vim.keymap.set('n', '<C-h>', vim.cmd.lnext)
-- vim.keymap.set('n', '(', vim.cmd.cprev)
-- vim.keymap.set('n', ')', vim.cmd.cnext)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- [[ TABS ]]
vim.keymap.set('n', '<C-t>', vim.cmd.tabnew)
vim.keymap.set('n', '<leader>tt', vim.cmd.tabs)
-- vim.keymap.set('n', '<C-K>', vim.cmd.tabnext) -- gt
-- vim.keymap.set('n', '<C-J>', vim.cmd.tabprev) -- gT

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- [[ Window Tiling ]]

--  See `:help wincmd` for a list of all window commands
--
-- Moving b/w splits
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the [h] left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the [l] right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the [j] lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the [k] upper window' })
-- Moving Split
vim.keymap.set({ 'n', 't' }, 'zH', function()
  vim.cmd.winc { 'H' }
end, { desc = 'Move window to the left' })
vim.keymap.set({ 'n', 't' }, 'zL', function()
  vim.cmd.winc { 'L' }
end, { desc = 'Move window to the right' })
vim.keymap.set({ 'n', 't' }, 'zJ', function()
  vim.cmd.winc { 'J' }
end, { desc = 'Move window to the lower' })
vim.keymap.set({ 'n', 't' }, 'zK', function()
  vim.cmd.winc { 'K' }
end, { desc = 'Move window to the upper' })
-- Resizing
vim.keymap.set({ 'n', 't' }, 'zh', ':horizontal resize +5<CR>')
vim.keymap.set({ 'n', 't' }, 'zl', ':vertical resize -5<CR>')
vim.keymap.set({ 'n', 't' }, 'zj', ':vertical resize +5<CR>')
vim.keymap.set({ 'n', 't' }, 'zk', ':horizontal resize -5<CR>')

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- [[ Terminal mode keymaps ]]

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TODO: Make this floating terminal
local term_job_id = 0
vim.keymap.set('n', '<leader>ct', function()
  vim.cmd.new()
  vim.cmd.term()
  vim.cmd.wincmd 'J'
  vim.api.nvim_win_set_height(0, 5)
  term_job_id = vim.bo.channel
end, { desc = '[C]hannel small [T]erminal below' })

vim.keymap.set('n', '<leader>cs', function()
  local command = vim.fn.input 'Command: '
  vim.fn.chansend(term_job_id, { command .. '\r\n' })
end, { desc = '[C]hannel [S]end command' })

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- [[ Lifestyle changes ]]

-- Find Regex of the line
vim.keymap.set('n', '<leader>R', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- Make current file exicutable
vim.keymap.set('n', '<leader>x', '<cmd>!chmod +x %<CR>', { silent = true })

-- Reset lua
vim.api.nvim_set_keymap('n', '<leader><CR>', '<cmd>lua ReloadConfig()<CR>', { noremap = true, silent = false })

-- Convert current latex file to pdf
vim.keymap.set('n', '<leader>pdf', '<cmd>!pdflatex %<CR>', { silent = true })

-- Json Linting
vim.keymap.set('n', '<leader>json', function()
  vim.cmd '%!jq .'
end)
