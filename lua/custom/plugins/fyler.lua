return {
  'A7Lavinraj/fyler.nvim',
  cmd = { 'Fyler' },
  keys = {
    { '_', '<cmd>Fyler<CR>', desc = 'Toggle Fyler' },
  },
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function(_, opts)
    local ok, fyler = pcall(require, 'fyler')
    if ok then
      fyler.setup(opts or {})
    end
  end,
}

