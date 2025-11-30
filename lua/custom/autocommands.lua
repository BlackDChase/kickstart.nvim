-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`
local function defineMacro(fileType, group, key, macro, desc)
    vim.api.nvim_create_autocmd({'FileType'}, {
      pattern = fileType,
      group = group,
      callback = function()
        vim.cmd('let @' .. key .. '="' .. macro .. '"')
      end,
      desc = desc,
    })
end


-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('custom-ter-open', { clear = true }),
  callback = function()
    vim.opt.number = true
    vim.opt.relativenumber = true
    -- vim.opt.scrolloff = 1
  end,
})



-- Latex
local latex_macros = vim.api.nvim_create_augroup('latex', { clear = true })

defineMacro("tex", latex_macros, "b" , 'c\\\\textbf{}\\<ESC>P', "[B]old selected text")
defineMacro("tex", latex_macros, "s" , 'c\\\\secret{}\\<ESC>P', "[S]ecretize selected text")
defineMacro("tex", latex_macros, "i" , 'c\\\\textit{}\\<ESC>P', "[I]talic selected text")

