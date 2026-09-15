local parsers = {
  'bash',
  'bibtex',
  'c',
  'cpp',
  'diff',
  'dockerfile',
  'go',
  'graphql',
  'html',
  'java',
  'javascript',
  'jsdoc',
  'json',
  'latex',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'python',
  'query',
  'vim',
  'vimdoc',
  'yaml',
}

local function eligible_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end
  if vim.b[bufnr].treesitter_force_enable then
    return true
  end
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == '' and vim.bo[bufnr].filetype == '' then
    return false
  end
  return not require('custom.large_file').is_expensive_buffer(bufnr)
end

local function start_treesitter(bufnr)
  if not eligible_buffer(bufnr) then
    return
  end
  local filetype = vim.bo[bufnr].filetype
  local language = filetype ~= '' and vim.treesitter.language.get_lang(filetype) or nil
  if not language then
    return
  end
  if pcall(vim.treesitter.start, bufnr, language) and filetype ~= 'ruby' then
    vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end
end

return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    init = function()
      vim.treesitter.language.register('json', 'jsonc')
      vim.api.nvim_create_autocmd('VimEnter', {
        once = true,
        callback = function()
          local bufnr = vim.api.nvim_get_current_buf()
          vim.schedule(function()
            start_treesitter(bufnr)
          end)
        end,
      })
      vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
          if vim.v.vim_did_enter == 1 then
            vim.schedule(function()
              start_treesitter(args.buf)
            end)
          end
        end,
      })
    end,
    config = function()
      vim.api.nvim_create_user_command('TreesitterForceEnable', function()
        local bufnr = vim.api.nvim_get_current_buf()
        vim.b[bufnr].treesitter_force_enable = true
        start_treesitter(bufnr)
      end, { desc = 'Force Treesitter highlighting for the current costly buffer' })

      vim.api.nvim_create_user_command('TreesitterInstallConfigured', function()
        require('nvim-treesitter').install(parsers)
      end, { desc = 'Install the configured Treesitter parsers asynchronously' })
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    keys = { ']f', ']F', '[f', '[F', ']a', '[a' },
    config = function()
      require('nvim-treesitter-textobjects').setup {
        move = { set_jumps = true },
      }

      local move = require 'nvim-treesitter-textobjects.move'
      local swap = require 'nvim-treesitter-textobjects.swap'
      local function map(lhs, callback, desc, modes)
        vim.keymap.set(modes or { 'n', 'x', 'o' }, lhs, callback, { desc = desc })
      end

      map(']f', function()
        move.goto_next_start('@function.outer', 'textobjects')
      end, 'Next function start')
      map(']F', function()
        move.goto_next_end('@function.outer', 'textobjects')
      end, 'Next function end')
      map('[f', function()
        move.goto_previous_start('@function.outer', 'textobjects')
      end, 'Previous function start')
      map('[F', function()
        move.goto_previous_end('@function.outer', 'textobjects')
      end, 'Previous function end')
      map(']a', function()
        swap.swap_next '@parameter.inner'
      end, 'Swap next parameter', 'n')
      map('[a', function()
        swap.swap_previous '@parameter.inner'
      end, 'Swap previous parameter', 'n')
    end,
  },
}
