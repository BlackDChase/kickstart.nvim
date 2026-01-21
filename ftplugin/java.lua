local ok, jdtls = pcall(require, 'jdtls')
if not ok then
  return
end

local root_markers = { 'mvnw', 'gradlew', 'pom.xml', 'build.gradle', '.project', '.settings', '.git' }
local root_dir = require('jdtls.setup').find_root(root_markers)
if not root_dir then
  vim.notify('jdtls: no project root found for current buffer', vim.log.levels.WARN)
  return
end

local workspace_dir = vim.fn.stdpath 'data' .. '/java-workspaces/' .. vim.fn.fnamemodify(root_dir, ':p:gs?/?_?')
vim.fn.mkdir(workspace_dir, 'p')

local registry = require 'mason-registry'
local install_location = require('mason-core.installer.InstallLocation').global()
local fs = require 'mason-core.fs'

local function get_package_path(name)
  local ok_pkg, package = pcall(registry.get_package, name)
  if not ok_pkg then
    vim.notify(('Failed to load Mason package "%s": %s'):format(name, package), vim.log.levels.ERROR)
    return nil
  end
  local package_path = install_location:package(package.name)
  if not fs.sync.dir_exists(package_path) then
    vim.notify(('Mason package "%s" is not installed. Run :MasonToolsInstall to fetch it.'):format(name), vim.log.levels.WARN)
    return nil
  end
  return package_path
end

local jdtls_path = get_package_path 'jdtls'
if not jdtls_path then
  return
end

local lombok_jar = jdtls_path .. '/lombok.jar'
local has_lombok = vim.fn.filereadable(lombok_jar) == 1
if not has_lombok then
  vim.notify_once(('jdtls: Lombok JAR not found at %s. Lombok annotations may not be recognized.'):format(lombok_jar), vim.log.levels.WARN)
end

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
    if has_java_bin(expanded) then
      return expanded
    end
    -- Homebrew openjdk@XX often points to a prefix like /opt/homebrew/opt/openjdk@21
    -- where the actual JAVA_HOME lives under libexec/openjdk.jdk/Contents/Home.
    local brew_java_home = expanded .. '/libexec/openjdk.jdk/Contents/Home'
    if vim.fn.isdirectory(brew_java_home) == 1 and has_java_bin(brew_java_home) then
      return vim.fn.fnamemodify(brew_java_home, ':p')
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
  for _, var in ipairs(env_vars) do
    local value = os.getenv(var)
    local normalized = normalize_jdk_path(value)
    if normalized then
      return normalized
    end
  end
end

local function detect_java21_home()
  local env_home = first_existing_dir { 'JDTLS_JAVA_HOME', 'JAVA_HOME_21', 'JAVA21_HOME' }
  if env_home then
    return env_home
  end
  if vim.fn.executable '/usr/libexec/java_home' == 1 then
    local output = vim.fn.system { '/usr/libexec/java_home', '-v', '21' }
    if vim.v.shell_error == 0 then
      local home = vim.fn.fnamemodify(vim.fn.trim(output), ':p')
      if home ~= '' and vim.fn.isdirectory(home) == 1 then
        return home
      end
    end
  end
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
  local out = vim.fn.system({ java_bin, '-version' })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  -- Example: openjdk version "21.0.2"  or  java version "21"
  local major = out:match('version%s+"(%d+)') or out:match('version%s+"(%d+)%.')
  return tonumber(major)
end

local java21_home = detect_java21_home()
local java21_major = java_major_version(java21_home)
if not java21_home or not java21_major or java21_major < 21 then
  vim.notify_once(
    'jdtls requires a Java 21 runtime.\n'
      .. '- Recommended: set $JDTLS_JAVA_HOME to a real JAVA_HOME (it must contain bin/java)\n'
      .. '  Example (Homebrew): export JDTLS_JAVA_HOME="$(brew --prefix openjdk@21)/libexec/openjdk.jdk/Contents/Home"\n'
      .. '- Current: '
      .. (java21_home and ('JDTLS_JAVA_HOME=' .. java21_home .. ' (major=' .. tostring(java21_major) .. ')') or 'not found'),
    vim.log.levels.ERROR
  )
  return
end

local bundles = {}
local function add_bundles(glob)
  for _, jar in ipairs(vim.split(vim.fn.glob(glob, 1), '\n', { plain = true })) do
    if jar ~= '' then
      table.insert(bundles, jar)
    end
  end
end

local java_debug_path = get_package_path 'java-debug-adapter'
if java_debug_path then
  add_bundles(java_debug_path .. '/extension/server/com.microsoft.java.debug.plugin-*.jar')
end

local java_test_path = get_package_path 'java-test'
if java_test_path then
  add_bundles(java_test_path .. '/extension/server/*.jar')
end

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
  table.insert(runtimes, runtime)
end

add_runtime({ 'JAVA_HOME_17', 'JAVA17_HOME', 'JAVA_HOME' }, 'JavaSE-17', true)
add_runtime({ 'JDTLS_JAVA_HOME', 'JAVA_HOME_21', 'JAVA21_HOME' }, 'JavaSE-21', false, java21_home)

local path_env = vim.env.PATH or os.getenv 'PATH' or ''
local cmd = {
  'env',
  ('JAVA_HOME=%s'):format(java21_home),
  ('PATH=%s/bin:%s'):format(java21_home, path_env),
  jdtls_path .. '/bin/jdtls',
}

local jvm_args = {
  '--jvm-arg=--add-modules=ALL-SYSTEM',
  '--jvm-arg=--add-opens=java.base/java.lang=ALL-UNNAMED',
  '--jvm-arg=--add-opens=java.base/java.util=ALL-UNNAMED',
  '--jvm-arg=--add-opens=java.base/java.io=ALL-UNNAMED',
}

if has_lombok then
  vim.list_extend(jvm_args, {
    ('--jvm-arg=-javaagent:%s'):format(lombok_jar),
    ('--jvm-arg=-Xbootclasspath/a:%s'):format(lombok_jar),
  })
end

vim.list_extend(cmd, jvm_args)

vim.list_extend(cmd, {
  '-data',
  workspace_dir,
})

local config = {
  cmd = cmd,
  root_dir = root_dir,
  settings = {
    java = {
      configuration = {
        updateBuildConfiguration = 'interactive',
        runtimes = runtimes,
      },
      maven = {
        downloadSources = true,
      },
      import = {
        maven = { enabled = true },
        gradle = { enabled = true },
      },
      references = {
        includeDecompiledSources = true,
      },
      project = {
        encoding = 'UTF-8',
      },
      signatureHelp = { enabled = true },
      completion = {
        favoriteStaticMembers = {
          'org.assertj.core.api.Assertions.*',
          'org.mockito.Mockito.*',
          'org.mockito.ArgumentMatchers.*',
          'org.mockito.Answers.*',
        },
        importOrder = {
          'java',
          'javax',
          'com',
          'org',
        },
      },
      format = { enabled = true },
    },
  },
  init_options = {
    bundles = bundles,
    extendedClientCapabilities = extended_capabilities,
  },
  capabilities = require('blink.cmp').get_lsp_capabilities(),
  on_attach = function(client, bufnr)
    -- Advertise implementation support so generic LSP helpers (Telescope, etc.)
    -- don't short-circuit when jdtls forgets to report it.
    client.server_capabilities.implementationProvider = client.server_capabilities.implementationProvider or true

    jdtls.setup_dap { hotcodereplace = 'auto' }
    require('jdtls.dap').setup_dap_main_class_configs()
    jdtls.setup.add_commands()

    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
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

    if client.server_capabilities.codeLensProvider then
      vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold' }, {
        buffer = bufnr,
        callback = vim.lsp.codelens.refresh,
      })
    end
  end,
}

-- local formatter = vim.fn.stdpath 'config' .. '/ftplugin/JavaCodeStyle.xml'
-- if vim.fn.filereadable(formatter) == 1 then
--   config.settings.java.format = {
--     enabled = true,
--     settings = {
--       url = ('file://%s'):format(formatter),
--       profile = 'JavaCodeStyle',
--     },
--   }
-- end

jdtls.start_or_attach(config)
