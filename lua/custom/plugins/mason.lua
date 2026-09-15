local tools = {
  'stylua',
  'marksman',
  'texlab',
  'gopls',
  'lua_ls',
  'vimls',
  'dockerls',
  'pyright',
  'ruff',
  'black',
  'isort',
  'jdtls',
  'java-debug-adapter',
  'java-test',
}

return {
  {
    'mason-org/mason.nvim',
    cmd = { 'Mason', 'MasonInstall', 'MasonUninstall', 'MasonUpdate', 'MasonLog' },
    opts = function()
      return {
        log_level = vim.g.custom_log_levels.mason or vim.g.custom_log_level,
      }
    end,
  },
  {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    cmd = { 'MasonToolsInstall', 'MasonToolsUpdate', 'MasonToolsClean' },
    dependencies = { 'mason-org/mason.nvim' },
    opts = {
      ensure_installed = tools,
      run_on_start = false,
    },
  },
}
