return {
  -- Start GitHub Copilot by calling `Copilot setup`
  'github/copilot.vim',
  -- Disabled by default during LSP stabilization. Set this to true in a local config to re-enable.
  enabled = vim.g.enable_copilot_during_lsp_stabilization == true,
  event = 'InsertEnter',
  cmd = { 'Copilot' },
  config = function()
    -- Don't steal <Tab> (avoids conflicts with nvim-cmp, etc.)
    vim.g.copilot_no_tab_map = true
    vim.g.copilot_assume_mapped = true
    vim.g.copilot_tab_fallback = ''

    -- Filetype control (enable/disable as you like)
    -- ["*"]=true means enable for all, then override specific types
    vim.g.copilot_filetypes = {
      ['*'] = true,
      markdown = true,
      help = false,
      text = true,
      gitcommit = true,
      TelescopePrompt = false,
    }

    -- Keymaps (insert mode)
    -- Accept suggestion
    vim.api.nvim_set_keymap('i', '<C-l>', 'copilot#Accept("<CR>")', { silent = true, expr = true, noremap = true })
    -- Cycle suggestions
    vim.api.nvim_set_keymap('i', '<C-;>', 'copilot#Next()', { silent = true, expr = true, noremap = true })
    vim.api.nvim_set_keymap('i', "<C-'>", 'copilot#Previous()', { silent = true, expr = true, noremap = true })
    -- Dismiss
    vim.api.nvim_set_keymap('i', '<C-/>', 'copilot#Dismiss()', { silent = true, expr = true, noremap = true })
  end,
}
