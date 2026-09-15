return { -- Highlight todo, notes, etc in comments
  'folke/todo-comments.nvim',
  event = 'User DeferredVisuals',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = { signs = false },
}
