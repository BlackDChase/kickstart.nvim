return {
  {
    'pteroctopus/faster.nvim',
    lazy = false,
    priority = 1001,
    opts = function()
      local disabled = {
        'illuminate',
        'matchparen',
        'lsp',
        'treesitter',
        'indent_blankline',
        'vimopts',
        'syntax',
        'filetype',
        'large_file_rendering',
      }
      return {
        behaviours = {
          bigfile = {
            on = true,
            filesize = 2,
            pattern = '*',
            notify = false,
            features_disabled = disabled,
          },
          longline = {
            on = true,
            filesize = 0.01,
            avg_bytes_per_line = 250,
            pattern = '*',
            notify = false,
            features_disabled = disabled,
          },
          fastmacro = { on = false },
        },
        features = {
          large_file_rendering = require('custom.large_file').faster_rendering_feature(),
        },
      }
    end,
  },
}
