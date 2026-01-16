-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  cmd = { 'Neotree' },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  keys = {
    { '_', ':Neotree reveal<CR>', desc = 'Neo[_]Tree reveal', silent = true },
  },
  opts = {
    log_level = vim.g.custom_log_levels.neotree or vim.g.custom_log_level,
    log_to_file = false,
    filesystem = {
      window = {
        mappings = {
          ['_'] = 'close_window',
        },
      },
    },
  },
}
