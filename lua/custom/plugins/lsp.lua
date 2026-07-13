-- LSP `L`
return {
  -- Main LSP Configuration
  'neovim/nvim-lspconfig',
  event = { 'BufReadPre', 'BufNewFile' },
  dependencies = {
    -- Automatically install LSPs and related tools to stdpath for Neovim
    -- Mason must be loaded before its dependents so we need to set it up here.
    -- NOTE: `opts = {}` is the same as calling `require('mason').setup({})`
    { 'mason-org/mason.nvim', opts = { log_level = vim.g.custom_log_levels.mason or vim.g.custom_log_level } },
    'mason-org/mason-lspconfig.nvim',
    'WhoIsSethDaniel/mason-tool-installer.nvim',

    -- Useful status updates for LSP.
    {
      'j-hui/fidget.nvim',
      opts = {
        logger = {
          level = vim.g.custom_log_levels.fidget or vim.g.custom_log_level,
          max_size = 1024, -- KB
        },
      },
    },

    -- Allows extra capabilities provided by blink.cmp
    'saghen/blink.cmp',
  },
  config = function()
    local lsp_attach_start_ns_by_buf = {} ---@type table<integer, integer>
    local lsp_attach_ms_by_buf = {} ---@type table<integer, number>
    local first_paint_ms_by_buf = {} ---@type table<integer, number>
    local lsp_attach_counts = vim.g.lsp_attach_counts or {}
    vim.g.lsp_attach_counts = lsp_attach_counts

    local format_disable = vim.g.lsp_format_disable or {}
    if vim.islist(format_disable) then
      local list = format_disable
      format_disable = {}
      for _, name in ipairs(list) do
        format_disable[name] = true
      end
    end
    format_disable.ts_ls = (format_disable.ts_ls ~= false)
    format_disable.lua_ls = (format_disable.lua_ls ~= false)

    local semantic_tokens_disable = vim.g.lsp_semantic_tokens_disable or {}
    local semantic_tokens_disable_ft = vim.g.lsp_semantic_tokens_disable_ft or {}
    local large_project_roots = vim.g.lsp_large_project_roots or {}
    local debounce_default = tonumber(vim.g.lsp_debounce_ms) or 150
    local debounce_by_server = vim.g.lsp_debounce_ms_by_server or {}
    local debounce_large = tonumber(vim.g.lsp_debounce_ms_large) or 400
    local disable_document_highlight_large = vim.g.lsp_disable_document_highlight_large
    if disable_document_highlight_large == nil then
      disable_document_highlight_large = true
    end

    local function is_large_project_root(root_dir)
      if not root_dir or root_dir == '' then
        return false
      end
      if vim.g.lsp_large_project == true then
        return true
      end
      for _, root in ipairs(large_project_roots) do
        if root_dir == root then
          return true
        end
      end
      return false
    end

    local function get_debounce_ms(server_name, root_dir)
      local override = debounce_by_server[server_name]
      if type(override) == 'number' then
        return override
      end
      if is_large_project_root(root_dir) then
        return debounce_large
      end
      return debounce_default
    end

    local function client_supports_method(client, method, bufnr)
      if vim.fn.has 'nvim-0.11' == 1 then
        return client:supports_method(method, bufnr)
      end
      return client.supports_method and client.supports_method(method, { bufnr = bufnr }) or false
    end

    local function refresh_diagnostics(bufnr)
      vim.diagnostic.enable(true, { bufnr = bufnr })
      local ok_methods, methods = pcall(function()
        return vim.lsp.protocol.Methods
      end)
      local td = ok_methods and methods.textDocument_diagnostic or nil
      local wd = ok_methods and methods.workspace_diagnostic or nil
      for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
        local params = vim.lsp.util.make_text_document_params(bufnr)
        if td and client_supports_method(client, td, bufnr) then
          client.request(td, { textDocument = params }, nil, bufnr)
        elseif wd and client_supports_method(client, wd, bufnr) then
          client.request(wd, { workDoneToken = 'diagnostic-refresh' }, nil, bufnr)
        end
      end
    end

    local function stop_semantic_tokens(bufnr)
      if not vim.lsp.semantic_tokens then
        return
      end
      for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
        pcall(vim.lsp.semantic_tokens.stop, bufnr, client.id)
      end
    end

    local function start_semantic_tokens(bufnr)
      if not vim.lsp.semantic_tokens then
        return
      end
      for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
        if client.server_capabilities.semanticTokensProvider then
          pcall(vim.lsp.semantic_tokens.start, bufnr, client.id)
        end
      end
    end

    local function set_lsp_paused(bufnr, paused)
      vim.b[bufnr].lsp_paused = paused
      if paused then
        vim.diagnostic.enable(false, { bufnr = bufnr })
        if vim.lsp.inlay_hint then
          pcall(vim.lsp.inlay_hint.enable, false, { bufnr = bufnr })
        end
        stop_semantic_tokens(bufnr)
      else
        if vim.lsp.inlay_hint then
          pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })
        end
        start_semantic_tokens(bufnr)
        refresh_diagnostics(bufnr)
      end
    end

    local function set_edit_mode(bufnr, enabled)
      vim.b[bufnr].lsp_edit_mode = enabled
      if enabled then
        vim.diagnostic.enable(false, { bufnr = bufnr })
      else
        refresh_diagnostics(bufnr)
      end
    end

    local function hard_pause(bufnr)
      vim.b[bufnr].lsp_hard_paused = true
      set_lsp_paused(bufnr, true)
      for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
        pcall(vim.lsp.stop_client, client.id)
      end
    end

    local function hard_resume(bufnr)
      vim.b[bufnr].lsp_hard_paused = false
      local ft = vim.bo[bufnr].filetype
      if ft == 'java' then
        vim.api.nvim_exec_autocmds('FileType', { buffer = bufnr })
      else
        pcall(vim.cmd, 'LspStart')
      end
      set_lsp_paused(bufnr, false)
    end

    vim.api.nvim_create_autocmd({ 'BufReadPre', 'BufNewFile' }, {
      group = vim.api.nvim_create_augroup('custom-lsp-timing', { clear = true }),
      callback = function(ev)
        lsp_attach_start_ns_by_buf[ev.buf] = (vim.uv or vim.loop).hrtime()
      end,
    })
    vim.api.nvim_create_autocmd('BufWinEnter', {
      group = vim.api.nvim_create_augroup('custom-buffer-paint-timing', { clear = true }),
      callback = function(ev)
        if first_paint_ms_by_buf[ev.buf] then
          return
        end
        local start_ns = lsp_attach_start_ns_by_buf[ev.buf]
        if not start_ns then
          return
        end
        local elapsed_ms = ((vim.uv or vim.loop).hrtime() - start_ns) / 1e6
        first_paint_ms_by_buf[ev.buf] = elapsed_ms
        vim.b[ev.buf].first_paint_ms = elapsed_ms
      end,
    })

    local uv = vim.uv or vim.loop
    local python_root_markers = {
      'pyproject.toml',
      'poetry.lock',
      'setup.py',
      'setup.cfg',
      'requirements.txt',
      'Pipfile',
      'pyrightconfig.json',
    }
    local python_fallback_markers = { '.git' }
    local poetry_env_cache = {} ---@type table<string, string|false>

    local function path_exists(path)
      return path and path ~= '' and uv.fs_stat(path) ~= nil
    end

    local function path_is_dir(path)
      local stat = path and uv.fs_stat(path) or nil
      return stat and stat.type == 'directory' or false
    end

    local function has_any_marker(dir, markers)
      for _, marker in ipairs(markers) do
        if path_exists(dir .. '/' .. marker) then
          return true
        end
      end
      return false
    end

    local function normalize_input_path(path_or_buf)
      if type(path_or_buf) == 'number' then
        if path_or_buf <= 0 or not vim.api.nvim_buf_is_valid(path_or_buf) then
          return nil
        end
        local resolved = vim.api.nvim_buf_get_name(path_or_buf)
        return resolved ~= '' and resolved or nil
      end
      if type(path_or_buf) == 'string' and path_or_buf ~= '' then
        if vim.startswith(path_or_buf, 'file://') then
          return vim.uri_to_fname(path_or_buf)
        end
        return path_or_buf
      end
      return nil
    end

    local function iter_ancestors(path_or_buf)
      local dirs = {}
      local path = normalize_input_path(path_or_buf)
      if not path then
        return dirs
      end
      local dir = path_is_dir(path) and vim.fs.normalize(path) or vim.fs.normalize(vim.fs.dirname(path))
      while dir and dir ~= '' do
        dirs[#dirs + 1] = dir
        local parent = vim.fs.dirname(dir)
        if not parent or parent == dir then
          break
        end
        dir = parent
      end
      return dirs
    end

    local function resolve_topmost_python_root(path_or_buf)
      local path = normalize_input_path(path_or_buf)
      if not path then
        return nil
      end
      local topmost_python_root
      local nearest_fallback_root
      for _, dir in ipairs(iter_ancestors(path)) do
        if has_any_marker(dir, python_root_markers) then
          topmost_python_root = dir
        elseif not nearest_fallback_root and has_any_marker(dir, python_fallback_markers) then
          nearest_fallback_root = dir
        end
      end
      return topmost_python_root or nearest_fallback_root
    end

    local function resolve_poetry_env(root_dir)
      if not root_dir or root_dir == '' then
        return nil
      end
      if poetry_env_cache[root_dir] ~= nil then
        local cached = poetry_env_cache[root_dir]
        return cached or nil
      end

      local resolved = nil
      if vim.fn.executable 'poetry' == 1 then
        local ok, out = pcall(vim.fn.system, { 'poetry', '-C', root_dir, 'env', 'info', '-p' })
        if ok then
          out = vim.fn.trim(out or '')
          if out ~= '' and path_is_dir(out) then
            resolved = out
          end
        end
      end

      if not resolved then
        local local_venv = root_dir .. '/.venv'
        if path_is_dir(local_venv) then
          resolved = local_venv
        end
      end

      if not resolved then
        local virtual_env = vim.env.VIRTUAL_ENV or os.getenv 'VIRTUAL_ENV'
        if virtual_env and virtual_env ~= '' and path_is_dir(virtual_env) then
          resolved = virtual_env
        end
      end

      poetry_env_cache[root_dir] = resolved or false
      return resolved
    end

    local function resolve_python_interpreter(venv)
      if not venv or venv == '' then
        return nil
      end
      local python_bin = venv .. '/bin/python'
      if vim.fn.executable(python_bin) == 1 then
        return python_bin
      end
      return nil
    end

    local python_ensure_inflight = {} ---@type table<integer, boolean>

    local function ensure_python_servers(bufnr)
      if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype ~= 'python' then
        return
      end
      if python_ensure_inflight[bufnr] then
        return
      end
      python_ensure_inflight[bufnr] = true

      local ok, err = pcall(function()
        local function has_client(name)
          for _, c in ipairs(vim.lsp.get_clients { bufnr = bufnr, name = name }) do
            if c then
              return true
            end
          end
          return false
        end

        if not has_client 'pyright' then
          pcall(vim.cmd, 'LspStart pyright')
        end

        if not has_client 'pyright' and vim.lsp.start then
          local root = resolve_topmost_python_root(bufnr)
          if root then
            local venv = resolve_poetry_env(root)
            local python = resolve_python_interpreter(venv)
            local settings = {
              python = {
                analysis = {
                  autoSearchPaths = true,
                  useLibraryCodeForTypes = true,
                  typeCheckingMode = vim.g.pyright_type_checking or 'basic',
                  diagnosticMode = vim.g.pyright_diagnostic_mode or 'openFilesOnly',
                },
              },
            }
            if venv then
              settings.python.venvPath = vim.fn.fnamemodify(venv, ':h')
              settings.python.venv = vim.fn.fnamemodify(venv, ':t')
              if python then
                settings.python.pythonPath = python
              end
            end

            local pyright_cmd = vim.fn.stdpath 'data' .. '/mason/bin/pyright-langserver'
            local cmd = vim.fn.executable(pyright_cmd) == 1 and { pyright_cmd, '--stdio' } or { 'pyright-langserver', '--stdio' }
            pcall(vim.lsp.start, {
              name = 'pyright',
              cmd = cmd,
              root_dir = root,
              settings = settings,
              flags = {
                debounce_text_changes = get_debounce_ms('pyright', root),
              },
              capabilities = require('blink.cmp').get_lsp_capabilities(),
            }, { bufnr = bufnr })
          end
        end

        if not has_client 'ruff' then
          pcall(vim.cmd, 'LspStart ruff')
        end
      end)

      python_ensure_inflight[bufnr] = nil
      if not ok then
        vim.notify(('ensure_python_servers failed: %s'):format(tostring(err)), vim.log.levels.WARN)
      end
    end

    local function python_root_dir(arg1, arg2)
      local root = resolve_topmost_python_root(arg1)
      if type(arg2) == 'function' then
        arg2(root)
        return
      end
      return root
    end

    -- Brief aside: **What is LSP?**
    --
    -- LSP is an initialism you've probably heard, but might not understand what it is.
    --
    -- LSP stands for Language Server Protocol. It's a protocol that helps editors
    -- and language tooling communicate in a standardized fashion.
    --
    -- In general, you have a "server" which is some tool built to understand a particular
    -- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
    -- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
    -- processes that communicate with some "client" - in this case, Neovim!
    --
    -- LSP provides Neovim with features like:
    --  - Go to definition
    --  - Find references
    --  - Autocompletion
    --  - Symbol Search
    --  - and more!
    --
    -- Thus, Language Servers are external tools that must be installed separately from
    -- Neovim. This is where `mason` and related plugins come into play.
    --
    -- If you're wondering about lsp vs treesitter, you can check out the wonderfully
    -- and elegantly composed help section, `:help lsp-vs-treesitter`

    --  This function gets run when an LSP attaches to a particular buffer.
    --    That is to say, every time a new file is opened that is associated with
    --    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
    --    function will be executed to configure the current buffer
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        -- NOTE: Remember that Lua is a real programming language, and as such it is possible
        -- to define small helper and utility functions so you don't have to repeat yourself.
        --
        -- In this case, we create a function that lets us more easily define mappings specific
        -- for LSP related items. It sets the mode, buffer and description for us each time.
        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        local function python_definition()
          local preferred = { 'pyright', 'basedpyright' }
          local target_client = nil
          for _, name in ipairs(preferred) do
            for _, c in ipairs(vim.lsp.get_clients { bufnr = event.buf, name = name }) do
              if client_supports_method(c, vim.lsp.protocol.Methods.textDocument_definition, event.buf) then
                target_client = c
                break
              end
            end
            if target_client then
              break
            end
          end
          if not target_client then
            local attached = vim.tbl_map(function(c)
              return c.name
            end, vim.lsp.get_clients { bufnr = event.buf })
            local msg = #attached > 0 and ('Python definition unavailable. Attached: ' .. table.concat(attached, ', ')) or 'Python definition unavailable. No LSP client attached yet.'
            vim.notify(msg, vim.log.levels.WARN)
            return
          end

          local params = vim.lsp.util.make_position_params(0, target_client.offset_encoding)
          target_client:request(vim.lsp.protocol.Methods.textDocument_definition, params, function(err, result)
            if err then
              vim.notify(('Python definition error: %s'):format(err.message or tostring(err)), vim.log.levels.WARN)
              return
            end
            if not result or vim.tbl_isempty(result) then
              vim.notify('No Python definitions found', vim.log.levels.WARN)
              return
            end
            local locations = vim.islist(result) and result or { result }
            local ok = pcall(vim.lsp.util.show_document, locations[1], target_client.offset_encoding, {
              focus = true,
              reuse_win = true,
            })
            if ok and #locations > 1 then
              vim.fn.setqflist(vim.lsp.util.locations_to_items(locations, target_client.offset_encoding), 'r')
            end
          end, event.buf)
        end

        do
          local threshold_ms = tonumber(vim.g.lsp_attach_slow_ms) or 400
          local start_ns = lsp_attach_start_ns_by_buf[event.buf]
          if start_ns then
            local elapsed_ms = ((vim.uv or vim.loop).hrtime() - start_ns) / 1e6
            if elapsed_ms >= threshold_ms then
              vim.notify(string.format('LSP attach: %.0fms', elapsed_ms), vim.log.levels.WARN)
            end
            lsp_attach_ms_by_buf[event.buf] = elapsed_ms
            vim.b[event.buf].lsp_attach_ms = elapsed_ms
          end
          lsp_attach_start_ns_by_buf[event.buf] = nil
        end

        local function prevDiadnosticAction(options)
          if vim.b[event.buf].lsp_edit_mode then
            return
          end
          options.count = -1
          options.float = true
          vim.diagnostic.jump(options)
          vim.lsp.buf.code_action(options)
        end
        local function nextDiadnosticAction(options)
          if vim.b[event.buf].lsp_edit_mode then
            return
          end
          options.count = 1
          options.float = true
          vim.diagnostic.jump(options)
          vim.lsp.buf.code_action(options)
        end

		vim.g.diagnostics_active = true
		local function toggle_diagnostics()
		  if vim.g.diagnostics_active then
			vim.g.diagnostics_active = false
			vim.diagnostic.enable(false) -- Disables diagnostics for the current buffer
			print("Diagnostics Off")
		  else
			vim.g.diagnostics_active = true
			vim.diagnostic.enable(true) -- Enables diagnostics for the current buffer
			print("Diagnostics On")
		  end
		end

        -- Rename the variable under your cursor.
        --  Most Language Servers support renaming across files, etc.
        map('<localleader>n', vim.lsp.buf.rename, 'Re[n]ame')

        -- Execute a code action, usually your cursor needs to be on top of an error
        -- or a suggestion from your LSP for this to activate.
        map('<localleader>a', vim.lsp.buf.code_action, 'Goto Code [A]ction', { 'n', 'x' })

        -- Find references for the word under your cursor.
        map('<localleader>r', require('telescope.builtin').lsp_references, 'Goto [R]e[f]erences')

        -- Show documentation for the word under your cursor.
        map('<localleader>h', vim.lsp.buf.hover, '[H]over Documentation')
        -- Show signature help for the function under your cursor.
        map('<localleader>s', vim.lsp.buf.signature_help, '[S]ignature Documentation', 'i')
        map('<localleader>g', vim.diagnostic.open_float, 'Open Dia[g]nostic')
        map('<localleader>[', prevDiadnosticAction, 'Prev Diagnostic + Code Action')
        map('<localleader>]', nextDiadnosticAction, 'Next Diagnostic + Code Action')
		map('<localleader>c', toggle_diagnostics, '[C]ode diagnostics toggle', 'n')

        -- Jump to the implementation of the word under your cursor.
        --  Useful when your language has ways of declaring types without an actual implementation.
        map('<localleader>i', require('telescope.builtin').lsp_implementations, 'Goto [I]mplementation')

        -- Jump to the definition of the word under your cursor.
        --  This is where a variable was first declared, or where a function is defined, etc.
        --  To jump back, press <C-t>.
        if vim.bo[event.buf].filetype == 'python' then
          map('<localleader>d', python_definition, 'Goto [D]efinition')
        else
          map('<localleader>d', require('telescope.builtin').lsp_definitions, 'Goto [D]efinition')
        end

        -- WARN: This is not Goto Definition, this is Goto Declaration.
        --  For example, in C this would take you to the header.
        map('<localleader>e', vim.lsp.buf.declaration, 'Goto D[e]claration')

        -- Fuzzy find all the symbols in your current document.
        --  Symbols are things like variables, functions, types, etc.
        map('<localleader>o', require('telescope.builtin').lsp_document_symbols, '[O]pen Document Symbols')

        -- Fuzzy find all the symbols in your current workspace.
        --  Similar to document symbols, except searches over your entire project.
        map('<localleader>w', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Open [W]orkspace Symbols')

        -- Jump to the type of the word under your cursor.
        --  Useful when you're not sure what type a variable is and you want to see
        --  the definition of its *type*, not where it was *defined*.
        map('<localleader>t', require('telescope.builtin').lsp_type_definitions, 'Goto [T]ype Definition')
        map('<localleader>Wa', vim.lsp.buf.add_workspace_folder, 'Add [W]orkspace Folder')
        map('<localleader>Wr', vim.lsp.buf.remove_workspace_folder, 'Remove [W]orkspace Folder')
        map('<localleader>Wl', function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, 'List [W]orkspace Folders')

        local client = vim.lsp.get_client_by_id(event.data.client_id)

        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_incomingCalls, event.buf) then
          map('<localleader>Ci', vim.lsp.buf.incoming_calls, '[C]alls [i]ncoming')
        end
        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_outgoingCalls, event.buf) then
          map('<localleader>Co', vim.lsp.buf.outgoing_calls, '[C]alls [o]utgoing')
        end

        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_codeLens, event.buf) then
          map('<localleader>lR', vim.lsp.codelens.refresh, 'Code[l]ens [R]efresh')
          map('<localleader>lr', vim.lsp.codelens.run, 'Code[l]ens [r]un')
        end

        -- The following two autocommands are used to highlight references of the
        -- word under your cursor when your cursor rests there for a little while.
        --    See `:help CursorHold` for information about when this is executed
        --
        -- When you move your cursor, the highlights will be cleared (the second autocommand).
        if not client then
          return
        end

        lsp_attach_counts[client.name] = (lsp_attach_counts[client.name] or 0) + 1

        if format_disable[client.name] then
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end

        local ft = vim.bo[event.buf].filetype
        local disable_semantic_tokens = semantic_tokens_disable[client.name]
          or semantic_tokens_disable_ft[ft]
          or vim.b[event.buf].lsp_semantic_tokens_disable
          or is_large_project_root(client.config and client.config.root_dir)
        if disable_semantic_tokens then
          stop_semantic_tokens(event.buf)
        end

        local disable_highlight = disable_document_highlight_large
          and is_large_project_root(client and client.config and client.config.root_dir or nil)
        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) and not disable_highlight then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = function()
              if vim.b[event.buf].lsp_paused or vim.b[event.buf].lsp_edit_mode then
                return
              end
              vim.lsp.buf.document_highlight()
            end,
          })

          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })

          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
            end,
          })
        end

        -- The following code creates a keymap to toggle inlay hints in your
        -- code, if the language server you are using supports them
        --
        -- This may be unwanted, since they displace some of your code
        if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
          map('<leader>th', function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
          end, '[T]oggle Inlay [H]ints')
        end

        map('<localleader>ld', function()
          refresh_diagnostics(event.buf)
        end, 'Refresh [D]iagnostics')

        map('<localleader>lp', function()
          set_lsp_paused(event.buf, not vim.b[event.buf].lsp_paused)
          local state = vim.b[event.buf].lsp_paused and 'paused' or 'resumed'
          vim.notify(('LSP: %s'):format(state), vim.log.levels.INFO)
        end, 'LSP [P]ause/Resume')

        map('<localleader>le', function()
          set_edit_mode(event.buf, not vim.b[event.buf].lsp_edit_mode)
          local state = vim.b[event.buf].lsp_edit_mode and 'edit mode on' or 'edit mode off'
          vim.notify(('LSP: %s'):format(state), vim.log.levels.INFO)
        end, 'LSP [E]dit Mode')
      end,
    })

    vim.api.nvim_create_user_command('LspDiagnosticsRefresh', function()
      refresh_diagnostics(vim.api.nvim_get_current_buf())
    end, { desc = 'Request LSP diagnostics refresh for current buffer' })

    vim.api.nvim_create_user_command('LspTogglePause', function()
      local bufnr = vim.api.nvim_get_current_buf()
      set_lsp_paused(bufnr, not vim.b[bufnr].lsp_paused)
    end, { desc = 'Toggle LSP features in current buffer' })

    vim.api.nvim_create_user_command('LspEditMode', function()
      local bufnr = vim.api.nvim_get_current_buf()
      set_edit_mode(bufnr, not vim.b[bufnr].lsp_edit_mode)
    end, { desc = 'Toggle LSP edit mode in current buffer' })

    vim.api.nvim_create_user_command('LspHardPause', function()
      hard_pause(vim.api.nvim_get_current_buf())
    end, { desc = 'Stop LSP clients for current buffer (hard pause)' })

    vim.api.nvim_create_user_command('LspHardResume', function()
      hard_resume(vim.api.nvim_get_current_buf())
    end, { desc = 'Restart LSP clients for current buffer (hard resume)' })

    vim.api.nvim_create_user_command('LspHealthSnapshot', function()
      local bufnr = vim.api.nvim_get_current_buf()
      local lines = {}
      for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
        local root = client.config and client.config.root_dir or ''
        local cmd = client.config and client.config.cmd and client.config.cmd[1] or 'n/a'
        table.insert(lines, string.format('%s | cmd=%s | root=%s | attaches=%d', client.name, cmd, root, lsp_attach_counts[client.name] or 0))
      end
      local attach_ms = lsp_attach_ms_by_buf[bufnr]
      local first_paint_ms = first_paint_ms_by_buf[bufnr]
      table.insert(lines, string.format('last attach: %s', attach_ms and string.format('%.0fms', attach_ms) or 'n/a'))
      table.insert(lines, string.format('first paint: %s', first_paint_ms and string.format('%.0fms', first_paint_ms) or 'n/a'))
      vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
    end, { desc = 'Show LSP clients + last attach timing' })

    pcall(vim.api.nvim_del_user_command, 'PyrightProjectInfo')
    vim.api.nvim_create_user_command('PyrightProjectInfo', function()
      local current_buf = vim.api.nvim_get_current_buf()
      local buf_path = vim.api.nvim_buf_get_name(current_buf)
      local resolved_root = resolve_topmost_python_root(buf_path)
      local resolved_venv = resolved_root and resolve_poetry_env(resolved_root) or nil
      local resolved_python = resolve_python_interpreter(resolved_venv)
      local attached_clients = vim.tbl_map(function(c)
        return c.name
      end, vim.lsp.get_clients { bufnr = current_buf })
      local lines = {
        ('buffer: %s'):format(buf_path ~= '' and buf_path or 'n/a'),
        ('root: %s'):format(resolved_root or 'n/a'),
        ('poetry env: %s'):format(resolved_venv or 'n/a'),
        ('python: %s'):format(resolved_python or 'n/a'),
        ('first paint: %s'):format(first_paint_ms_by_buf[current_buf] and string.format('%.1fms', first_paint_ms_by_buf[current_buf]) or 'n/a'),
        ('last attach: %s'):format(lsp_attach_ms_by_buf[current_buf] and string.format('%.1fms', lsp_attach_ms_by_buf[current_buf]) or 'n/a'),
        ('attached clients: %s'):format(#attached_clients > 0 and table.concat(attached_clients, ', ') or 'none'),
      }
      for _, client in ipairs(vim.lsp.get_clients { bufnr = current_buf }) do
        if client.name == 'pyright' or client.name == 'ruff' then
          lines[#lines + 1] = ('%s root: %s'):format(client.name, client.config and client.config.root_dir or 'n/a')
        end
      end
      vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
    end, { desc = 'Show Python project root/env/interpreter info' })

    pcall(vim.api.nvim_del_user_command, 'PyrightRestart')
    vim.api.nvim_create_user_command('PyrightRestart', function()
      local bufnr = vim.api.nvim_get_current_buf()
      for _, client in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
        if client.name == 'pyright' or client.name == 'ruff' then
          pcall(vim.lsp.stop_client, client.id)
        end
      end
      vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
          ensure_python_servers(bufnr)
        end
      end, 50)
    end, { desc = 'Restart pyright and ruff for current Python buffer' })

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('custom-python-lsp-ensure', { clear = true }),
      pattern = 'python',
      callback = function(ev)
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(ev.buf) then
            ensure_python_servers(ev.buf)
          end
        end)
      end,
    })

    -- Diagnostic Config
    -- See :help vim.diagnostic.Opts
    vim.diagnostic.config {
      severity_sort = true,
      float = { border = 'rounded', source = 'if_many' },
      underline = { severity = vim.diagnostic.severity.ERROR },
      signs = vim.g.have_nerd_font and {
        text = {
          [vim.diagnostic.severity.ERROR] = '󰅚 ',
          [vim.diagnostic.severity.WARN] = '󰀪 ',
          [vim.diagnostic.severity.INFO] = '󰋽 ',
          [vim.diagnostic.severity.HINT] = '󰌶 ',
        },
      } or {},
      virtual_text = {
        source = 'if_many',
        spacing = 2,
        format = function(diagnostic)
          local diagnostic_message = {
            [vim.diagnostic.severity.ERROR] = diagnostic.message,
            [vim.diagnostic.severity.WARN] = diagnostic.message,
            [vim.diagnostic.severity.INFO] = diagnostic.message,
            [vim.diagnostic.severity.HINT] = diagnostic.message,
          }
          return diagnostic_message[diagnostic.severity]
        end,
      },
    }

    -- LSP servers and clients are able to communicate to each other what features they support.
    --  By default, Neovim doesn't support everything that is in the LSP specification.
    --  When you add blink.cmp, luasnip, etc. Neovim now has *more* capabilities.
    --  So, we create new capabilities with blink.cmp, and then broadcast that to the servers.
    local capabilities = require('blink.cmp').get_lsp_capabilities()

    -- Enable the following language servers
    --  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
    --
    --  Add any additional override configuration in the following tables. Available keys are:
    --  - cmd (table): Override the default command used to start the server
    --  - filetypes (table): Override the default list of associated filetypes for the server
    --  - capabilities (table): Override fields in capabilities. Can be used to disable certain LSP features.
    --  - settings (table): Override the default settings passed when initializing the server.
    --        For example, to see the options for `lua_ls`, you could go to: https://luals.github.io/wiki/settings/
    local servers = {
      -- clangd = {},
      -- gopls = {},
      pyright = {
        root_dir = python_root_dir,
        before_init = function(_, config)
          local root = config.root_dir
          if not root or root == '' then
            root = resolve_topmost_python_root(vim.api.nvim_buf_get_name(0))
          end
          local venv = resolve_poetry_env(root)
          if not venv then
            return
          end
          local python = resolve_python_interpreter(venv)
          config.settings = config.settings or {}
          config.settings.python = config.settings.python or {}
          config.settings.python.venvPath = vim.fn.fnamemodify(venv, ':h')
          config.settings.python.venv = vim.fn.fnamemodify(venv, ':t')
          if python then
            config.settings.python.pythonPath = python
          end
        end,
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              typeCheckingMode = vim.g.pyright_type_checking or 'basic',
              diagnosticMode = vim.g.pyright_diagnostic_mode or 'openFilesOnly',
            },
          },
        },
      },
      ruff = {
        root_dir = python_root_dir,
      },
      -- rust_analyzer = {},
      -- ... etc. See `:help lspconfig-all` for a list of all the pre-configured LSPs
      --
      -- Some languages (like typescript) have entire language plugins that can be useful:
      --    https://github.com/pmizio/typescript-tools.nvim
      --
      -- But for many setups, the LSP (`ts_ls`) will work just fine
      ts_ls = {},
      --

      lua_ls = {
        -- cmd = { ... },
        -- filetypes = { ... },
        -- capabilities = {},
        settings = {
          Lua = {
            completion = {
              callSnippet = 'Replace',
            },
            -- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
            -- diagnostics = { disable = { 'missing-fields' } },
          },
        },
      },
    }

    -- Ensure the servers and tools above are installed
    --
    -- To check the current status of installed tools and/or manually install
    -- other tools, you can run
    --    :Mason
    --
    -- You can press `g?` for help in this menu.
    --
    -- `mason` had to be setup earlier: to configure its options see the
    -- `dependencies` table for `nvim-lspconfig` above.
    --
    -- You can add other tools here that you want Mason to install
    -- for you, so that they are available from within Neovim.
    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      'stylua', -- Used to format Lua code
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
    })
    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    for server_name, server in pairs(servers) do
      local name = server_name
      server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
      local existing_on_new_config = server.on_new_config
      server.on_new_config = function(new_config, new_root)
        if existing_on_new_config then
          existing_on_new_config(new_config, new_root)
        end
        new_config.flags = new_config.flags or {}
        new_config.flags.debounce_text_changes = get_debounce_ms(name, new_root)
      end

      if vim.lsp.config then
        vim.lsp.config(name, server)
      else
        require('lspconfig')[name].setup(server)
      end
    end

    require('mason-lspconfig').setup {
      ensure_installed = {}, -- installs are managed by mason-tool-installer above
      automatic_enable = {
        exclude = {
          -- jdtls needs the bespoke Java 21/runtime/workspace config in ftplugin/java.lua.
          'jdtls',
        },
      },
    }

    local current = vim.api.nvim_get_current_buf()
    if vim.bo[current].filetype == 'python' then
      vim.schedule(function()
        ensure_python_servers(current)
      end)
    end
  end,
}
