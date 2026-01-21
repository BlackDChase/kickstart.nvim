local M = {}

function M.diff_current_file_against_branch()
  local bufnr = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == '' then
    vim.notify('No file in current buffer', vim.log.levels.WARN)
    return
  end

  local ok, builtin = pcall(require, 'telescope.builtin')
  if not ok then
    vim.notify('telescope.nvim not available', vim.log.levels.ERROR)
    return
  end

  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  builtin.git_branches({
    attach_mappings = function(prompt_bufnr, map)
      local function open_diff()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        local branch = selection and (selection.value or selection.name or selection.branch)
        if not branch or branch == '' then
          vim.notify('No branch selected', vim.log.levels.WARN)
          return
        end

        if vim.fn.exists(':Gdiffsplit') ~= 2 then
          vim.notify('vim-fugitive not available (:Gdiffsplit missing)', vim.log.levels.ERROR)
          return
        end

        vim.cmd('Gdiffsplit ' .. vim.fn.escape(branch, ' \\'))
      end

      map('n', '<CR>', open_diff)
      map('i', '<CR>', open_diff)
      return true
    end,
  })
end

return M
