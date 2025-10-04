return {
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    columns = {
      'icon',
      -- 'permissions',
      -- 'size',
      -- 'mtime',
    },
    keymaps = {
      ['<CR>'] = 'actions.select',
      ['<C-s>'] = 'actions.select_split',
      ['<C-v>'] = 'actions.select_vsplit',
      ['<C-t>'] = 'actions.select_tab',
      ['q'] = 'actions.close',
      ['₹'] = { 'actions.cd', opts = { scope = 'tab' }, mode = 'n' },
      ['<leader>fr'] = 'actions.refresh',
      ['_'] = { 'actions.open_cwd', mode = 'n' },
      -- ['gs'] = { 'actions.change_sort', mode = 'n' },
      -- ['g?'] = 'actions.show_help',
    },
    view_options = {
      show_hidden = true,
      natural_order = 'fast',
      sort = {
        { 'type', 'asc' },
        { 'name', 'asc' },
      },
    },
    float = {
      padding = 2,
      max_width = 60,
      max_height = 30,
      border = 'rounded',
      win_options = {
        winblend = 10,
      },
    },
    extra_scp_args = {},
    use_default_keymaps = true,
  },
  dependencies = { { 'echasnovski/mini.icons', opts = {} } },
  vim.keymap.set('n', '-', function()
    local dir = vim.fn.expand '%:p:h' -- get directory before splitting
    vim.cmd.vnew()
    require('oil').open(dir)
    vim.cmd.wincmd 'H'
    vim.api.nvim_win_set_width(0, 25)
  end, { desc = 'Oil file explorer' }),
}
