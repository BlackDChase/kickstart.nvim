return {

  { -- Linting
    'mfussenegger/nvim-lint',
    event = 'User DeferredUiTools',
    config = function()
      local lint = require 'lint'
      lint.linters_by_ft = {
        markdown = { 'markdownlint-cli2' },
      }

      -- To allow other plugins to add linters to require('lint').linters_by_ft,
      -- instead set linters_by_ft like this:
      -- lint.linters_by_ft = lint.linters_by_ft or {}
      -- lint.linters_by_ft['markdown'] = { 'markdownlint' }
      --
      -- However, note that this will enable a set of default linters,
      -- which will cause errors unless these tools are available:
      -- {
      --   clojure = { "clj-kondo" },
      --   dockerfile = { "hadolint" },
      --   inko = { "inko" },
      --   janet = { "janet" },
      --   json = { "jsonlint" },
      --   markdown = { "vale" },
      --   rst = { "vale" },
      --   ruby = { "ruby" },
      --   terraform = { "tflint" },
      --   text = { "vale" }
      -- }
      --
      -- You can disable the default linters by setting their filetypes to nil:
      -- lint.linters_by_ft['clojure'] = nil
      -- lint.linters_by_ft['dockerfile'] = nil
      -- lint.linters_by_ft['inko'] = nil
      -- lint.linters_by_ft['janet'] = nil
      -- lint.linters_by_ft['json'] = nil
      -- lint.linters_by_ft['markdown'] = nil
      -- lint.linters_by_ft['rst'] = nil
      -- lint.linters_by_ft['ruby'] = nil
      -- lint.linters_by_ft['terraform'] = nil
      -- lint.linters_by_ft['text'] = nil

      local function lint_markdown(bufnr)
        if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
          return
        end

        if vim.bo[bufnr].filetype ~= 'markdown'
            or vim.bo[bufnr].buftype ~= ''
            or not vim.bo[bufnr].modifiable
            or vim.b[bufnr].large_file_mode
            or vim.fn.executable('markdownlint-cli2') ~= 1 then
          return
        end

        lint.try_lint('markdownlint-cli2')
      end

      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd('FileType', {
        group = lint_augroup,
        pattern = 'markdown',
        callback = function(ev)
          vim.schedule(function()
            lint_markdown(ev.buf)
          end)
        end,
      })
      vim.api.nvim_create_autocmd({ 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function(ev)
          lint_markdown(ev.buf)
        end,
      })

      local current_buf = vim.api.nvim_get_current_buf()
      vim.defer_fn(function()
        lint_markdown(current_buf)
      end, 100)
    end,
  },
}
