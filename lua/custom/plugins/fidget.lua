return {
  'j-hui/fidget.nvim',
  event = 'LspProgress',
  opts = function()
    return {
      logger = {
        level = vim.g.custom_log_levels.fidget or vim.g.custom_log_level,
        max_size = 1024,
      },
    }
  end,
}
