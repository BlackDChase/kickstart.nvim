return {
  'stevearc/oil.nvim',
  cmd = { 'Oil' },
  keys = {
    {
      '-',
      function()
        require('custom.oil.drawer').toggle()
      end,
      desc = 'Toggle Oil drawer',
    },
  },
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {
    default_file_explorer = false,
    columns = {
      'icon',
      -- 'permissions',
      -- 'size',
      -- 'mtime',
    },
    win_options = {
      winbar = '%!v:lua.require("custom.oil.drawer").winbar()',
    },
    keymaps = {
      ['<BS>'] = { 'actions.parent', mode = 'n' },
      ['<CR>'] = {
        function()
          require('custom.oil.drawer').select()
        end,
        mode = 'n',
        desc = 'Open (file in main)',
      },
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
}
