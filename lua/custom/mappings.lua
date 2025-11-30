-- Remaps `R`

-- Remaps are saved in a way: (vim mode, keystrokes mapping, action defination)
--  See `:help vim.keymap.set()`

-- [[ Saving remaps ]]
vim.keymap.set({ 'n', 'v' }, 'S', vim.cmd.update)
vim.keymap.set({ 'n', 'v' }, '|', vim.cmd.q)
-- Vertical changes exit save
-- vim.keymap.set('i', '<C-c>', '<ESC>')

-- No Operation when exidental Q
vim.keymap.set('n', 'Q', '<nop>')

-- [[ Basic Keymaps ]]

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- TIP: Disable arrow keys in normal mode
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- [[ Search Highlighting ]]
-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
-- vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set({'n'}, '<ESC>', vim.cmd.noh)

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
vim.keymap.set('n', '<A-[>', vim.cmd.bn)		-- Alt/Opt + [
vim.keymap.set('n', '<A-]>', vim.cmd.bp)		-- Alt/Opt + ]
vim.keymap.set('n', '<A-BS>', vim.cmd.bd)		-- Alt/Opt + Backspace

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
vim.keymap.set('x', '<leader>p', '"_dP', {desc='[P]aste without messing buffer'})
vim.keymap.set({ 'n', 'v' }, '<leader>p', '"_d', {desc='[P]aste without messing buffer'})
-- Yank para
vim.keymap.set({ 'n', 'v' }, '<leader>y', '"+y', {desc='[Y]ank para'})
vim.keymap.set({ 'n', 'v' }, '<leader>Y', '"+Y', {desc='[Y]and para'})

-- Quick fix navigation
vim.keymap.set('n', '<leader><s-tab>', vim.cmd.lprev, {desc='Previous Quick fix'})
vim.keymap.set('n', '<leader><tab>', vim.cmd.lnext, {desc='Next Quick fix'})
vim.keymap.set('n', '<localleader><s-tab>', vim.cmd.cprev, {desc='Previous quick fix'})
vim.keymap.set('n', '<localleader><tab>', vim.cmd.cnext, {desc='Next quick fix'})

-- File explorer
-- vim.keymap.set("n", "<leader>vs", function () vim.cmd("30 vs ./") end)
-- vim.keymap.set("n", "<leader>vt", function () vim.cmd("30 Tex ./") end)
-- vim.keymap.set("n", "<leader>vtl", function () vim.cmd("30 Tex") end)
-- vim.keymap.set("n", "<leader>vl", function () vim.cmd("30 Vex") end)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- [[ TABS ]]
vim.keymap.set('n', '<leader>tn', vim.cmd.tabnew, {desc='[T]ab [n]ew'})
vim.keymap.set('n', '<leader>tt', vim.cmd.tabs, {desc='[T]ab [n]ew'})
vim.keymap.set('n', '<tab>', vim.cmd.tabnext, {desc='Next [tab]'}) -- gt
vim.keymap.set('n', '<s-tab>', vim.cmd.tabprev, {desc='Previous [TAB]'}) -- gT

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
vim.keymap.set({ 'n', 't' }, 'zH', function() vim.cmd.winc { 'H' } end, { desc = 'Move window to the left' })
vim.keymap.set({ 'n', 't' }, 'zL', function() vim.cmd.winc { 'L' } end, { desc = 'Move window to the right' })
vim.keymap.set({ 'n', 't' }, 'zJ', function() vim.cmd.winc { 'J' } end, { desc = 'Move window to the lower' })
vim.keymap.set({ 'n', 't' }, 'zK', function() vim.cmd.winc { 'K' } end, { desc = 'Move window to the upper' })
-- Resizing
-- In ITerm profile Ask otpion to send Esc+key sequences
vim.keymap.set({ 'n', 't' }, '<A-h>', ':vertical resize -1<CR>')
vim.keymap.set({ 'n', 't' }, '<A-j>', ':horizontal resize -1<CR>')
vim.keymap.set({ 'n', 't' }, '<A-k>', ':horizontal resize +1<CR>')
vim.keymap.set({ 'n', 't' }, '<A-l>', ':vertical resize +1<CR>')

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
-- vim.keymap.set('n', '<leader>R', [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], {desc='Find [R]jgex of the line'})

-- Make current file exicutable
vim.keymap.set('n', '<leader>x', '<cmd>!chmod +x %<CR>', { silent = true, desc='Make file e[x]ecutibale' })

-- Reset lua
-- vim.api.nvim_set_keymap('n', '<leader><CR>', '<cmd>lua ReloadConfig()<CR>', { noremap = true, silent = false })

-- Convert current latex file to pdf
vim.keymap.set('n', '<leader>pdf', '<cmd>!pdflatex %<CR>', { silent = true, desc='Compile [PDF]' })

-- Json Linting
vim.keymap.set('n', '<leader>json', function()
  vim.cmd '%!jq .'
end, {desc='[JSON] formatting'})
