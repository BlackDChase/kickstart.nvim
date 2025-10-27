return {
  {
    'mfussenegger/nvim-jdtls',
    ft = { 'java' },
    dependencies = {
      'neovim/nvim-lspconfig',
      'mason-org/mason.nvim',
      'mason-org/mason-lspconfig.nvim',
      'mfussenegger/nvim-dap',
    },
  },
}
