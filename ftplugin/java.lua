local uv = vim.uv or vim.loop
local api = vim.api
local protocol = vim.lsp.protocol

local cache = rawget(vim, '_jdtls_ftplugin_cache')
if not cache then
  cache = {
    root_states = {},
    workspace_dirs = {},
    package_paths = {},
    java21 = nil,
    commands_created = false,
  }
  rawset(vim, '_jdtls_ftplugin_cache', cache)
end

local bufnr = api.nvim_get_current_buf()
local bufname = api.nvim_buf_get_name(bufnr)
if bufname == '' then
  return
end

local trace_path = vim.fn.stdpath 'state' .. '/jdtls-ftplugin.log'
local build_markers = {
  'pom.xml',
  'mvnw',
  'build.gradle',
  'build.gradle.kts',
  'settings.gradle',
  'settings.gradle.kts',
  'gradlew',
}
local fallback_markers = { '.project', '.settings', '.git' }
local excluded_test_bundles = {
  ['com.microsoft.java.test.runner-jar-with-dependencies.jar'] = true,
  ['jacocoagent.jar'] = true,
}
local root_policy_name = 'topmost-build-root'

local function hrtime_ms(start_ns)
  return (uv.hrtime() - start_ns) / 1e6
end

local function timed(bucket, key, fn)
  local start_ns = uv.hrtime()
  local ok, result_a, result_b, result_c = pcall(fn)
  bucket[key] = hrtime_ms(start_ns)
  if not ok then
    error(result_a)
  end
  return result_a, result_b, result_c
end

local function log_trace(message)
  local line = ('%s %s'):format(os.date '%Y-%m-%d %H:%M:%S', message)
  pcall(vim.fn.writefile, { line }, trace_path, 'a')
end

local function stat(path)
  if not path or path == '' then
    return nil
  end
  return uv.fs_stat(path)
end

local function is_dir(path)
  local info = stat(path)
  return info and info.type == 'directory' or false
end

local function file_exists(path)
  return stat(path) ~= nil
end

local function dirname(path)
  return vim.fs.dirname(path)
end

local function ancestors(path)
  local list = {}
  local dir = is_dir(path) and vim.fs.normalize(path) or vim.fs.normalize(dirname(path))
  while dir and dir ~= '' do
    list[#list + 1] = dir
    local parent = dirname(dir)
    if not parent or parent == dir then
      break
    end
    dir = parent
  end
  return list
end

local function dir_has_any_marker(dir, markers)
  for _, marker in ipairs(markers) do
    if file_exists(dir .. '/' .. marker) then
      return true, marker
    end
  end
  return false, nil
end

local function resolve_root(path)
  local nearest_fallback
  local nearest_fallback_marker
  local topmost_build
  local topmost_build_marker

  for _, dir in ipairs(ancestors(path)) do
    local has_build, build_marker = dir_has_any_marker(dir, build_markers)
    if has_build then
      topmost_build = dir
      topmost_build_marker = build_marker
    end

    if not nearest_fallback then
      local has_fallback, fallback_marker = dir_has_any_marker(dir, fallback_markers)
      if has_fallback then
        nearest_fallback = dir
        nearest_fallback_marker = fallback_marker
      end
    end
  end

  if topmost_build then
    return topmost_build, root_policy_name, topmost_build_marker
  end
  if nearest_fallback then
    return nearest_fallback, 'fallback-nearest-marker', nearest_fallback_marker
  end
  return nil, 'none', nil
end

local function workspace_dir_for(root_dir)
  local cached = cache.workspace_dirs[root_dir]
  if cached then
    return cached
  end
  local dir = vim.fn.stdpath 'data' .. '/java-workspaces/' .. vim.fn.fnamemodify(root_dir, ':p:gs?/?_?')
  cache.workspace_dirs[root_dir] = dir
  return dir
end

local sync_breakdown = {}
local sync_start_ns = uv.hrtime()
local root_dir, root_policy, root_marker = timed(sync_breakdown, 'resolve_root', function()
  return resolve_root(bufname)
end)

if not root_dir then
  vim.notify('jdtls: no project root found for current buffer', vim.log.levels.WARN)
  log_trace(('sync_no_root file=%s total=%.1fms'):format(bufname, hrtime_ms(sync_start_ns)))
  return
end

local workspace_dir = timed(sync_breakdown, 'workspace_dir', function()
  return workspace_dir_for(root_dir)
end)

vim.b[bufnr].jdtls_root_dir = root_dir
vim.b[bufnr].jdtls_workspace_dir = workspace_dir
vim.b[bufnr].jdtls_root_policy = root_policy

local root_state = cache.root_states[root_dir]
if not root_state then
  root_state = {
    root_dir = root_dir,
    root_policy = root_policy,
    root_marker = root_marker,
    workspace_dir = workspace_dir,
    pending_bufs = {},
    bootstrap_ready = false,
    bootstrap_inflight = false,
    bootstrap_scheduled = false,
    bootstrap_ms = nil,
    bootstrap_breakdown = {},
    last_start_or_attach_ms = nil,
    last_attach_ms = nil,
    extras_initialized = false,
    config = nil,
    module_count = nil,
    runtime_classpaths = nil,
    source_cache = {},
    last_error = nil,
  }
  cache.root_states[root_dir] = root_state
else
  root_state.root_policy = root_policy
  root_state.root_marker = root_marker
  root_state.workspace_dir = workspace_dir
end

local function get_current_root_state()
  local current_root = vim.b.jdtls_root_dir
  return current_root and cache.root_states[current_root] or nil
end

local function count_project_modules(state)
  if state.module_count then
    return state.module_count
  end
  local total = 0
  local patterns = {
    '**/pom.xml',
    '**/build.gradle',
    '**/build.gradle.kts',
    '**/settings.gradle',
    '**/settings.gradle.kts',
  }
  for _, pattern in ipairs(patterns) do
    total = total + #vim.fn.globpath(state.root_dir, pattern, false, true)
  end
  state.module_count = total
  return total
end

local function format_timings(bucket)
  local keys = {}
  for key in pairs(bucket or {}) do
    keys[#keys + 1] = key
  end
  table.sort(keys)
  local parts = {}
  for _, key in ipairs(keys) do
    parts[#parts + 1] = ('%s=%.1fms'):format(key, bucket[key])
  end
  return #parts > 0 and table.concat(parts, ', ') or 'n/a'
end

local function request_sync(client, method, params, timeout_ms, target_bufnr)
  if vim.fn.has 'nvim-0.11' == 1 then
    return client:request_sync(method, params, timeout_ms, target_bufnr)
  end
  return client.request_sync(client, method, params, timeout_ms, target_bufnr)
end

local function get_jdtls_client(target_bufnr)
  local clients = vim.lsp.get_clients { bufnr = target_bufnr, name = 'jdtls' }
  return clients[1]
end

local function show_location(client, location)
  if not location then
    return false
  end

  local normalized
  if location.targetUri then
    normalized = {
      uri = location.targetUri,
      range = location.targetSelectionRange or location.targetRange,
    }
  else
    normalized = location
  end

  local uri = normalized.uri or normalized.targetUri
  if not uri then
    return false
  end

  if uri:match '^jdt://' then
    vim.cmd('edit ' .. vim.fn.fnameescape(uri))
    local range = normalized.range
    if range and range.start then
      pcall(api.nvim_win_set_cursor, 0, { range.start.line + 1, range.start.character or 0 })
    end
    return true
  end

  local ok = pcall(vim.lsp.util.show_document, normalized, client.offset_encoding, {
    focus = true,
    reuse_win = true,
  })
  return ok
end

local function to_locations(result)
  if not result then
    return {}
  end
  if result.uri or result.targetUri then
    return { result }
  end
  if vim.islist(result) then
    return result
  end
  return {}
end

local function open_locations(client, locations)
  if #locations == 0 then
    return false
  end
  if #locations == 1 then
    return show_location(client, locations[1])
  end

  local quickfixable = {}
  for _, location in ipairs(locations) do
    local uri = location.uri or location.targetUri
    if uri and not uri:match '^jdt://' then
      quickfixable[#quickfixable + 1] = location.targetUri and {
        uri = location.targetUri,
        range = location.targetSelectionRange or location.targetRange,
      } or location
    end
  end

  if #quickfixable > 1 then
    vim.fn.setqflist(vim.lsp.util.locations_to_items(quickfixable, client.offset_encoding), 'r')
    vim.cmd.copen()
    return true
  end

  return show_location(client, locations[1])
end

local function buffer_import_context(target_bufnr)
  local lines = api.nvim_buf_get_lines(target_bufnr, 0, -1, false)
  local package_name
  local imports = {}
  for _, line in ipairs(lines) do
    if not package_name then
      package_name = line:match '^%s*package%s+([%w_%.]+)%s*;'
    end
    local import = line:match '^%s*import%s+([%w_%.%*]+)%s*;'
    if import then
      imports[#imports + 1] = import
    end
  end
  return package_name, imports
end

local function build_symbol_queries(target_bufnr, symbol)
  local package_name, imports = buffer_import_context(target_bufnr)
  local seen = {}
  local queries = {}
  local function add(query)
    if type(query) ~= 'string' or query == '' or seen[query] then
      return
    end
    seen[query] = true
    queries[#queries + 1] = query
  end

  for _, import in ipairs(imports) do
    if import:sub(-#symbol) == symbol then
      add(import)
    elseif import:sub(-2) == '.*' then
      add(import:sub(1, -3) .. '.' .. symbol)
    end
  end
  if package_name then
    add(package_name .. '.' .. symbol)
  end
  add(symbol)
  return queries
end

local function resolve_fqcn_from_imports(target_bufnr, symbol)
  local package_name, imports = buffer_import_context(target_bufnr)
  for _, import in ipairs(imports) do
    if import:sub(-#symbol) == symbol then
      return import
    end
  end
  if package_name then
    return package_name .. '.' .. symbol
  end
  return nil
end

local function execute_command_sync(client, target_bufnr, command, arguments, timeout_ms)
  local method = protocol.Methods.workspace_executeCommand or 'workspace/executeCommand'
  local response, wait_error = request_sync(client, method, {
    command = command,
    arguments = arguments,
  }, timeout_ms or 2000, target_bufnr)
  local error_obj = (response and response.err) or wait_error
  if error_obj then
    return nil, error_obj
  end
  local result = response and response.result
  if result and result.body then
    result = result.body
  end
  return result, nil
end

local function resolve_runtime_classpaths(client, target_bufnr)
  local state = get_current_root_state()
  if state and state.runtime_classpaths then
    return state.runtime_classpaths
  end
  local uri = vim.uri_from_bufnr(target_bufnr)
  local options = vim.fn.json_encode { scope = 'runtime' }
  local result, err = execute_command_sync(client, target_bufnr, 'java.project.getClasspaths', { uri, options }, 3000)
  if err or not result or type(result.classpaths) ~= 'table' then
    return {}
  end
  if state then
    state.runtime_classpaths = result.classpaths
  end
  return result.classpaths
end

local function read_source_from_jar(jar_path, rel_path)
  if vim.fn.executable 'unzip' ~= 1 then
    return nil
  end
  local content = vim.fn.system({ 'unzip', '-p', jar_path, rel_path })
  if vim.v.shell_error ~= 0 or not content or content == '' then
    return nil
  end
  return content
end

local function open_java_source_text(fqcn, source_text, source_hint)
  local source_root = vim.fn.stdpath 'state' .. '/jdtls-sources'
  local relative = fqcn:gsub('%.', '/') .. '.java'
  local target = source_root .. '/' .. relative
  vim.fn.mkdir(vim.fs.dirname(target), 'p')
  local lines = vim.split(source_text, '\n', { plain = true })
  pcall(vim.fn.writefile, lines, target)
  vim.cmd('edit ' .. vim.fn.fnameescape(target))
  if source_hint and source_hint ~= '' then
    vim.b.jdtls_source_hint = source_hint
  end
  return true
end

local function open_from_classpaths(client, target_bufnr, symbol)
  local fqcn = resolve_fqcn_from_imports(target_bufnr, symbol)
  if not fqcn or fqcn == '' then
    return false
  end

  local state = get_current_root_state()
  if state and state.source_cache and state.source_cache[fqcn] and vim.fn.filereadable(state.source_cache[fqcn]) == 1 then
    vim.cmd('edit ' .. vim.fn.fnameescape(state.source_cache[fqcn]))
    return true
  end

  local rel_path = fqcn:gsub('%.', '/') .. '.java'
  local classpaths = resolve_runtime_classpaths(client, target_bufnr)
  for _, classpath in ipairs(classpaths) do
    if vim.fn.isdirectory(classpath) == 1 then
      local candidate = classpath .. '/' .. rel_path
      if vim.fn.filereadable(candidate) == 1 then
        vim.cmd('edit ' .. vim.fn.fnameescape(candidate))
        if state then
          state.source_cache[fqcn] = candidate
        end
        return true
      end
    elseif classpath:sub(-12) == '-sources.jar' and vim.fn.filereadable(classpath) == 1 then
      local source_text = read_source_from_jar(classpath, rel_path)
      if source_text and open_java_source_text(fqcn, source_text, classpath) then
        if state then
          state.source_cache[fqcn] = vim.api.nvim_buf_get_name(0)
        end
        return true
      end
    end
  end

  return false
end

local function symbol_candidates(client, target_bufnr, symbol)
  local queries = build_symbol_queries(target_bufnr, symbol)
  local dedupe = {}
  local candidates = {}

  for _, query in ipairs(queries) do
    local response = request_sync(client, protocol.Methods.workspace_symbol, { query = query }, 1500, target_bufnr)
    local items = response and response.result or {}
    for _, item in ipairs(items) do
      local location = item.location
      if location and (location.uri or location.targetUri) then
        local uri = location.uri or location.targetUri
        local line = location.range and location.range.start and location.range.start.line or -1
        local key = table.concat({ item.name or '', uri, tostring(line) }, '::')
        if not dedupe[key] then
          dedupe[key] = true
          local container = item.containerName or ''
          local fqcn = container ~= '' and (container .. '.' .. (item.name or '')) or item.name or ''
          local score = 0
          if fqcn == query then
            score = score + 100
          end
          if item.name == symbol then
            score = score + 50
          end
          if uri:match '^jdt://' then
            score = score + 5
          end
          candidates[#candidates + 1] = {
            score = score,
            location = location,
            query = query,
            name = item.name,
            uri = uri,
          }
        end
      end
    end
  end

  table.sort(candidates, function(a, b)
    if a.score == b.score then
      return (a.name or '') < (b.name or '')
    end
    return a.score > b.score
  end)

  return candidates
end

local function java_definition_fallback(target_bufnr)
  local client = get_jdtls_client(target_bufnr)
  if not client then
    vim.notify('jdtls: not attached yet', vim.log.levels.WARN)
    return
  end

  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
  local response, wait_error = request_sync(client, protocol.Methods.textDocument_definition, params, 1500, target_bufnr)
  local lsp_error = (response and response.err) or wait_error
  local locations = to_locations(response and response.result)
  if #locations > 0 and open_locations(client, locations) then
    log_trace(
      ('definition_native root=%s symbol=%s count=%d'):format(
        root_dir,
        vim.fn.expand '<cword>',
        #locations
      )
    )
    return
  end

  local symbol = vim.fn.expand '<cword>'
  local candidates = symbol_candidates(client, target_bufnr, symbol)
  if #candidates == 0 then
    if open_from_classpaths(client, target_bufnr, symbol) then
      log_trace(('definition_classpath_fallback root=%s symbol=%s'):format(root_dir, symbol))
      return
    end
    local reason = lsp_error and (lsp_error.message or tostring(lsp_error)) or 'no-result'
    log_trace(('definition_fallback_empty root=%s symbol=%s reason=%s'):format(root_dir, symbol, reason))
    vim.notify('No Java definitions found', vim.log.levels.WARN)
    return
  end

  local best_score = candidates[1].score
  local best = {}
  for _, candidate in ipairs(candidates) do
    if candidate.score ~= best_score then
      break
    end
    best[#best + 1] = candidate.location
  end

  log_trace(
    ('definition_fallback root=%s symbol=%s native_error=%s candidates=%d'):format(
      root_dir,
      symbol,
      lsp_error and (lsp_error.message or tostring(lsp_error)) or 'none',
      #candidates
    )
  )

  if not open_locations(client, best) then
    vim.notify('Java definition fallback failed', vim.log.levels.WARN)
  end
end

local function create_commands()
  if cache.commands_created then
    return
  end

  api.nvim_create_user_command('JdtlsProjectInfo', function()
    local state = get_current_root_state()
    if not state then
      vim.notify('jdtls: no root state for current buffer', vim.log.levels.WARN)
      return
    end

    local lines = {
      ('root: %s'):format(state.root_dir),
      ('root policy: %s'):format(state.root_policy),
      ('root marker: %s'):format(state.root_marker or 'n/a'),
      ('workspace: %s'):format(state.workspace_dir),
      ('modules/build files: %d'):format(count_project_modules(state)),
      ('first paint: %s'):format(vim.b.first_paint_ms and ('%.1fms'):format(vim.b.first_paint_ms) or 'n/a'),
      ('last attach: %s'):format(vim.b.lsp_attach_ms and ('%.1fms'):format(vim.b.lsp_attach_ms) or 'n/a'),
      ('sync ftplugin: %s'):format(vim.b.jdtls_sync_ftplugin_ms and ('%.1fms'):format(vim.b.jdtls_sync_ftplugin_ms) or 'n/a'),
      ('jdtls bootstrap: %s'):format(state.bootstrap_ms and ('%.1fms'):format(state.bootstrap_ms) or 'pending'),
      ('start_or_attach: %s'):format(state.last_start_or_attach_ms and ('%.1fms'):format(state.last_start_or_attach_ms) or 'n/a'),
      ('autobuild: %s'):format(tostring(state.jdtls_auto_build)),
      ('downloadSources: %s'):format(tostring(state.jdtls_maven_download_sources)),
      ('includeDecompiledSources: %s'):format(tostring(state.jdtls_include_decompiled_sources)),
      ('sync timings: %s'):format(format_timings(vim.b.jdtls_sync_breakdown or {})),
      ('bootstrap timings: %s'):format(format_timings(state.bootstrap_breakdown)),
    }
    if state.last_error then
      lines[#lines + 1] = ('last error: %s'):format(state.last_error)
    end
    vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
  end, { desc = 'Show jdtls project info + timing breakdown' })

  api.nvim_create_user_command('JdtlsWipeWorkspace', function()
    local state = get_current_root_state()
    if not state then
      vim.notify('jdtls: no root state for current buffer', vim.log.levels.WARN)
      return
    end

    for _, client in ipairs(vim.lsp.get_clients { name = 'jdtls' }) do
      if client.config and client.config.root_dir == state.root_dir then
        client.stop(true)
      end
    end

    local ok_delete = pcall(vim.fn.delete, state.workspace_dir, 'rf')
    if not ok_delete then
      vim.notify(('jdtls: failed to delete workspace %s'):format(state.workspace_dir), vim.log.levels.ERROR)
      return
    end

    cache.workspace_dirs[state.root_dir] = nil
    cache.root_states[state.root_dir] = nil
    vim.notify(('jdtls: wiped workspace %s (reopen project to reimport)'):format(state.workspace_dir), vim.log.levels.WARN)
    log_trace(('wipe_workspace root=%s workspace=%s'):format(state.root_dir, state.workspace_dir))
  end, { desc = 'Delete jdtls workspace for current Java root' })

  cache.commands_created = true
end

create_commands()

local function normalize_jdk_path(path)
  if not path or path == '' then
    return nil
  end
  local expanded = vim.fn.fnamemodify(vim.fn.expand(path), ':p')
  local function has_java_bin(home)
    local java_bin = home .. '/bin/java'
    return vim.fn.filereadable(java_bin) == 1 or vim.fn.executable(java_bin) == 1
  end
  if vim.fn.isdirectory(expanded) == 1 then
    expanded = vim.fn.fnamemodify(expanded, ':p')
    -- Homebrew's `openjdk@*` prefix exposes a convenient `bin/java` symlink,
    -- but Eclipse/JDTLS needs the actual macOS JDK bundle root. Prefer it
    -- whenever it exists, before accepting a generic Java-home-shaped path.
    local brew_java_home = expanded .. '/libexec/openjdk.jdk/Contents/Home'
    if vim.fn.isdirectory(brew_java_home) == 1 and has_java_bin(brew_java_home) then
      return vim.fn.fnamemodify(brew_java_home, ':p')
    end
    if has_java_bin(expanded) then
      return expanded
    end
  end
  if vim.fn.filereadable(expanded) == 1 then
    local parent = vim.fn.fnamemodify(expanded, ':h')
    if vim.fn.fnamemodify(parent, ':t') == 'bin' then
      parent = vim.fn.fnamemodify(parent, ':h')
    end
    if vim.fn.isdirectory(parent) == 1 then
      parent = vim.fn.fnamemodify(parent, ':p')
      if has_java_bin(parent) then
        return parent
      end
    end
  end
  return nil
end

local function first_existing_dir(env_vars)
  for _, var_name in ipairs(env_vars) do
    local normalized = normalize_jdk_path(os.getenv(var_name))
    if normalized then
      return normalized
    end
  end
end

local function detect_java21_home()
  if cache.java21 ~= nil then
    return cache.java21
  end

  local env_home = first_existing_dir { 'JDTLS_JAVA_HOME', 'JAVA_HOME_21', 'JAVA21_HOME' }
  if env_home then
    cache.java21 = env_home
    return env_home
  end

  if vim.fn.executable '/usr/libexec/java_home' == 1 then
    local output = vim.fn.system { '/usr/libexec/java_home', '-v', '21' }
    if vim.v.shell_error == 0 then
      local home = vim.fn.fnamemodify(vim.fn.trim(output), ':p')
      if home ~= '' and vim.fn.isdirectory(home) == 1 then
        cache.java21 = home
        return home
      end
    end
  end

  cache.java21 = false
  return nil
end

local function java_major_version(java_home)
  if not java_home then
    return nil
  end
  local java_bin = java_home .. '/bin/java'
  if vim.fn.executable(java_bin) ~= 1 then
    return nil
  end
  local out = vim.fn.system { java_bin, '-version' }
  if vim.v.shell_error ~= 0 then
    return nil
  end
  local major = out:match('version%s+"(%d+)') or out:match('version%s+"(%d+)%.')
  return tonumber(major)
end

local function get_package_path(name)
  local cached = cache.package_paths[name]
  if cached ~= nil then
    return cached or nil
  end

  local ok_registry, registry = pcall(require, 'mason-registry')
  local ok_install, install_location = pcall(function()
    return require('mason-core.installer.InstallLocation').global()
  end)
  local ok_fs, fs = pcall(require, 'mason-core.fs')
  if not ok_registry or not ok_install or not ok_fs then
    cache.package_paths[name] = false
    return nil
  end

  local ok_pkg, package = pcall(registry.get_package, name)
  if not ok_pkg then
    cache.package_paths[name] = false
    return nil
  end

  local package_path = install_location:package(package.name)
  if not fs.sync.dir_exists(package_path) then
    cache.package_paths[name] = false
    return nil
  end

  cache.package_paths[name] = package_path
  return package_path
end

local function add_bundles(bundles, glob_pattern)
  for _, jar in ipairs(vim.fn.glob(glob_pattern, false, true)) do
    if jar ~= '' and not excluded_test_bundles[vim.fn.fnamemodify(jar, ':t')] then
      bundles[#bundles + 1] = jar
    end
  end
end

local function deferred_extras(jdtls, state)
  if state.extras_initialized then
    return
  end
  state.extras_initialized = true
  vim.schedule(function()
    pcall(jdtls.setup_dap, { hotcodereplace = 'auto' })
    pcall(function()
      require('jdtls.dap').setup_dap_main_class_configs()
    end)
    pcall(jdtls.setup.add_commands)
  end)
end

local function maybe_enable_codelens(client, attached_bufnr, jdtls_codelens_auto_refresh, is_large_project)
  if not client.server_capabilities.codeLensProvider or not jdtls_codelens_auto_refresh or is_large_project then
    return
  end

  local group = api.nvim_create_augroup(('jdtls-codelens-%d'):format(attached_bufnr), { clear = true })
  api.nvim_create_autocmd({ 'BufEnter', 'CursorHold' }, {
    group = group,
    buffer = attached_bufnr,
    callback = function()
      if vim.b[attached_bufnr].lsp_paused or vim.b[attached_bufnr].lsp_edit_mode then
        return
      end
      vim.lsp.codelens.refresh()
    end,
  })
end

local function attach_pending_buffers(state, jdtls)
  if not state.config then
    return
  end

  for target_bufnr in pairs(state.pending_bufs) do
    state.pending_bufs[target_bufnr] = nil
    if api.nvim_buf_is_valid(target_bufnr) then
      local start_ns = uv.hrtime()
      jdtls.start_or_attach(state.config, nil, { bufnr = target_bufnr })
      state.last_start_or_attach_ms = hrtime_ms(start_ns)
      vim.b[target_bufnr].jdtls_start_or_attach_ms = state.last_start_or_attach_ms
      log_trace(
        ('start_or_attach root=%s buf=%d took=%.1fms'):format(
          state.root_dir,
          target_bufnr,
          state.last_start_or_attach_ms
        )
      )
    end
  end
end

local function bootstrap_root_state(state)
  if state.bootstrap_ready then
    local ok_jdtls, jdtls = pcall(require, 'jdtls')
    if ok_jdtls then
      attach_pending_buffers(state, jdtls)
    end
    return
  end
  if state.bootstrap_inflight then
    return
  end

  state.bootstrap_inflight = true
  state.bootstrap_scheduled = false

  local bootstrap_breakdown = {}
  local bootstrap_start_ns = uv.hrtime()

  local ok, error_message = pcall(function()
    local ok_jdtls, jdtls = timed(bootstrap_breakdown, 'require_jdtls', function()
      return pcall(require, 'jdtls')
    end)
    if not ok_jdtls then
      error(jdtls)
    end

    local jdtls_auto_build = vim.g.jdtls_auto_build
    if jdtls_auto_build == nil then
      jdtls_auto_build = false
    end

    local jdtls_maven_download_sources = vim.g.jdtls_maven_download_sources
    if jdtls_maven_download_sources == nil then
      jdtls_maven_download_sources = true
    end

    local jdtls_include_decompiled_sources = vim.g.jdtls_include_decompiled_sources
    if jdtls_include_decompiled_sources == nil then
      jdtls_include_decompiled_sources = true
    end

    local jdtls_import_on_first_start = vim.g.jdtls_import_on_first_start or 'interactive'
    local jdtls_import_exclusions = vim.g.jdtls_import_exclusions or {
      '**/node_modules/**',
      '**/target/**',
      '**/build/**',
      '**/out/**',
      '**/.gradle/**',
      '**/.idea/**',
    }
    local jdtls_codelens_auto_refresh = vim.g.jdtls_codelens_auto_refresh
    if jdtls_codelens_auto_refresh == nil then
      jdtls_codelens_auto_refresh = false
    end
    local jdtls_reduce_heap = vim.g.jdtls_reduce_heap or false
    local jdtls_jvm_args_extra = vim.g.jdtls_jvm_args or {}

    state.jdtls_auto_build = jdtls_auto_build
    state.jdtls_maven_download_sources = jdtls_maven_download_sources
    state.jdtls_include_decompiled_sources = jdtls_include_decompiled_sources

    local jdtls_path = timed(bootstrap_breakdown, 'resolve_jdtls_pkg', function()
      return get_package_path 'jdtls'
    end)
    if not jdtls_path then
      error('Mason package "jdtls" is not installed. Run :MasonToolsInstall.')
    end

    local java21_home = timed(bootstrap_breakdown, 'detect_java21', function()
      return detect_java21_home()
    end)
    local java21_major = java_major_version(java21_home)
    if not java21_home or not java21_major or java21_major < 21 then
      error(
        'jdtls requires a Java 21 runtime. Set $JDTLS_JAVA_HOME to a valid JAVA_HOME with bin/java.'
      )
    end

    local java_debug_path = get_package_path 'java-debug-adapter'
    local java_test_path = get_package_path 'java-test'
    local bundles = timed(bootstrap_breakdown, 'resolve_bundles', function()
      local resolved = {}
      vim.fn.mkdir(state.workspace_dir, 'p')
      if java_debug_path then
        add_bundles(resolved, java_debug_path .. '/extension/server/com.microsoft.java.debug.plugin-*.jar')
      end
      if java_test_path then
        add_bundles(resolved, java_test_path .. '/extension/server/*.jar')
      end
      return resolved
    end)

    local extended_capabilities = jdtls.extendedClientCapabilities
    extended_capabilities.resolveAdditionalTextEditsSupport = true

    local runtimes = {}
    local default_runtime_set = false
    local function add_runtime(env_vars, name, prefer_default, explicit_path)
      local runtime_home = explicit_path or first_existing_dir(env_vars)
      if not runtime_home then
        return
      end
      local runtime = { name = name, path = runtime_home }
      if prefer_default and not default_runtime_set then
        runtime.default = true
        default_runtime_set = true
      end
      runtimes[#runtimes + 1] = runtime
    end

    add_runtime({ 'JAVA_HOME_17', 'JAVA17_HOME', 'JAVA_HOME' }, 'JavaSE-17', true)
    add_runtime({ 'JDTLS_JAVA_HOME', 'JAVA_HOME_21', 'JAVA21_HOME' }, 'JavaSE-21', false, java21_home)

    local path_env = vim.env.PATH or os.getenv 'PATH' or ''
    local java21_bin = java21_home .. '/bin/java'
    local cmd = {
      'env',
      ('JAVA_HOME=%s'):format(java21_home),
      ('PATH=%s/bin:%s'):format(java21_home, path_env),
      jdtls_path .. '/bin/jdtls',
      '--java-executable',
      java21_bin,
    }

    local lombok_jar = jdtls_path .. '/lombok.jar'
    local has_lombok = vim.fn.filereadable(lombok_jar) == 1
    local jvm_args = {
      '--jvm-arg=--add-modules=ALL-SYSTEM,java.compiler,jdk.compiler',
      '--jvm-arg=--add-opens=java.base/java.lang=ALL-UNNAMED',
      '--jvm-arg=--add-opens=java.base/java.util=ALL-UNNAMED',
      '--jvm-arg=--add-opens=java.base/java.io=ALL-UNNAMED',
    }
    if has_lombok then
      jvm_args[#jvm_args + 1] = ('--jvm-arg=-javaagent:%s'):format(lombok_jar)
    end

    local function add_jvm_arg(arg)
      if type(arg) ~= 'string' or arg == '' then
        return
      end
      if arg:match '^%-%-jvm%-arg=' then
        jvm_args[#jvm_args + 1] = arg
      else
        jvm_args[#jvm_args + 1] = '--jvm-arg=' .. arg
      end
    end

    if jdtls_reduce_heap then
      add_jvm_arg '-Xms256m'
      add_jvm_arg '-Xmx1024m'
    end

    if vim.islist(jdtls_jvm_args_extra) then
      for _, arg in ipairs(jdtls_jvm_args_extra) do
        add_jvm_arg(arg)
      end
    elseif type(jdtls_jvm_args_extra) == 'string' then
      add_jvm_arg(jdtls_jvm_args_extra)
    end

    vim.list_extend(cmd, jvm_args)
    vim.list_extend(cmd, { '-data', state.workspace_dir })

    local capabilities = {}
    local ok_blink, blink = pcall(require, 'blink.cmp')
    if ok_blink then
      capabilities = blink.get_lsp_capabilities()
    end

    local large_project_roots = vim.g.lsp_large_project_roots or {}
    local debounce_default = tonumber(vim.g.lsp_debounce_ms) or 150
    local debounce_by_server = vim.g.lsp_debounce_ms_by_server or {}
    local debounce_large = tonumber(vim.g.lsp_debounce_ms_large) or 400

    local function is_large_project_root(dir)
      if not dir or dir == '' then
        return false
      end
      if vim.g.lsp_large_project == true then
        return true
      end
      for _, large_root in ipairs(large_project_roots) do
        if dir == large_root then
          return true
        end
      end
      return false
    end

    local function get_debounce_ms(dir)
      local override = debounce_by_server.jdtls
      if type(override) == 'number' then
        return override
      end
      if is_large_project_root(dir) then
        return debounce_large
      end
      return debounce_default
    end

    local is_large_project = is_large_project_root(state.root_dir)

    state.config = {
      cmd = cmd,
      root_dir = state.root_dir,
      flags = {
        debounce_text_changes = get_debounce_ms(state.root_dir),
      },
      settings = {
        java = {
          autobuild = {
            enabled = jdtls_auto_build,
          },
          configuration = {
            updateBuildConfiguration = 'interactive',
            runtimes = runtimes,
          },
          project = {
            importOnFirstTimeStartup = jdtls_import_on_first_start,
            encoding = 'UTF-8',
          },
          maven = {
            downloadSources = jdtls_maven_download_sources,
          },
          import = {
            maven = { enabled = true },
            gradle = {
              enabled = true,
              annotationProcessing = { enabled = true },
            },
            exclusions = jdtls_import_exclusions,
          },
          references = {
            includeDecompiledSources = jdtls_include_decompiled_sources,
          },
          signatureHelp = { enabled = true },
          completion = {
            favoriteStaticMembers = {
              'org.assertj.core.api.Assertions.*',
              'org.mockito.Mockito.*',
              'org.mockito.ArgumentMatchers.*',
              'org.mockito.Answers.*',
            },
            importOrder = { 'java', 'javax', 'com', 'org' },
          },
          format = { enabled = true },
        },
      },
      init_options = {
        bundles = bundles,
        extendedClientCapabilities = extended_capabilities,
      },
      capabilities = capabilities,
      on_attach = function(client, attached_bufnr)
        client.server_capabilities.implementationProvider = client.server_capabilities.implementationProvider or true
        state.last_attach_ms = vim.b[attached_bufnr].lsp_attach_ms
        deferred_extras(jdtls, state)
        maybe_enable_codelens(client, attached_bufnr, jdtls_codelens_auto_refresh, is_large_project)

        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = attached_bufnr, desc = desc })
        end

        map('n', '<leader>jo', jdtls.organize_imports, 'Java: Organize Imports')
        map('n', '<leader>jT', jdtls.test_class, 'Java: Test Class')
        map('n', '<leader>jt', jdtls.test_nearest_method, 'Java: Test Method')
        map({ 'n', 'v' }, '<leader>je', function()
          jdtls.extract_variable(true)
        end, 'Java: Extract Variable')
        map({ 'n', 'v' }, '<leader>jc', function()
          jdtls.extract_constant(true)
        end, 'Java: Extract Constant')
        map('v', '<leader>jm', function()
          jdtls.extract_method(true)
        end, 'Java: Extract Method')

        vim.schedule(function()
          if api.nvim_buf_is_valid(attached_bufnr) then
            vim.keymap.set('n', '<localleader>d', function()
              java_definition_fallback(attached_bufnr)
            end, { buffer = attached_bufnr, desc = 'Java: Goto Definition' })
          end
        end)
      end,
    }
  end)

  state.bootstrap_breakdown = bootstrap_breakdown
  state.bootstrap_ms = hrtime_ms(bootstrap_start_ns)
  state.bootstrap_inflight = false
  state.bootstrap_ready = ok
  state.last_error = ok and nil or error_message

  if not ok then
    log_trace(('bootstrap_error root=%s total=%.1fms error=%s'):format(state.root_dir, state.bootstrap_ms, error_message))
    vim.notify(('jdtls bootstrap failed: %s'):format(error_message), vim.log.levels.ERROR)
    return
  end

  log_trace(
    ('bootstrap root=%s total=%.1fms [%s]'):format(
      state.root_dir,
      state.bootstrap_ms,
      format_timings(bootstrap_breakdown)
    )
  )

  local ok_jdtls, jdtls = pcall(require, 'jdtls')
  if ok_jdtls then
    attach_pending_buffers(state, jdtls)
  end
end

root_state.pending_bufs[bufnr] = true

local function bootstrap_after_first_paint(state)
  local function defer_bootstrap()
    vim.defer_fn(function()
      if next(state.pending_bufs) ~= nil then
        bootstrap_root_state(state)
      else
        state.bootstrap_scheduled = false
      end
    end, tonumber(vim.g.jdtls_start_delay_ms) or 500)
  end

  if vim.v.vim_did_enter == 1 then
    defer_bootstrap()
    return
  end

  api.nvim_create_autocmd('VimEnter', {
    once = true,
    callback = defer_bootstrap,
  })
end

if not root_state.bootstrap_ready and not root_state.bootstrap_inflight and not root_state.bootstrap_scheduled then
  root_state.bootstrap_scheduled = true
  timed(sync_breakdown, 'schedule_attach', function()
    bootstrap_after_first_paint(root_state)
  end)
elseif root_state.bootstrap_ready then
  timed(sync_breakdown, 'schedule_attach', function()
    vim.schedule(function()
      local ok_jdtls, jdtls = pcall(require, 'jdtls')
      if ok_jdtls then
        attach_pending_buffers(root_state, jdtls)
      end
    end)
  end)
end

vim.b[bufnr].jdtls_sync_breakdown = sync_breakdown
vim.b[bufnr].jdtls_sync_ftplugin_ms = hrtime_ms(sync_start_ns)

log_trace(
  ('sync_start root=%s policy=%s marker=%s total=%.1fms [%s]'):format(
    root_dir,
    root_policy,
    root_marker or 'n/a',
    vim.b[bufnr].jdtls_sync_ftplugin_ms,
    format_timings(sync_breakdown)
  )
)
