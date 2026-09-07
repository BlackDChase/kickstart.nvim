local M = {}

local uv = vim.uv or vim.loop
local mib = 1024 * 1024
local strip_threshold = 2 * mib
local extreme_threshold = 50 * mib
local longline_probe_minimum = 10 * 1024
local longline_average = 250
local window_backups = {}
local setup_done = false

local window_options = {
  'wrap',
  'linebreak',
  'number',
  'relativenumber',
  'colorcolumn',
  'signcolumn',
  'foldenable',
  'cursorline',
  'cursorcolumn',
  'conceallevel',
  'scrolloff',
  'sidescrolloff',
  'spell',
}

local stripped_window_options = {
  wrap = false,
  linebreak = false,
  number = false,
  relativenumber = false,
  colorcolumn = '',
  signcolumn = 'no',
  foldenable = false,
  cursorline = false,
  cursorcolumn = false,
  conceallevel = 0,
  scrolloff = 0,
  sidescrolloff = 0,
  spell = false,
}

local function resolve_bufnr(bufnr)
  if not bufnr or bufnr == 0 then
    return vim.api.nvim_get_current_buf()
  end
  return bufnr
end

local function normalize_path(path)
  if type(path) ~= 'string' or path == '' or path:match '^%w+://' then
    return nil
  end
  return vim.fs.normalize(vim.fn.fnamemodify(vim.fn.expand(path), ':p'))
end

local function regular_file(path)
  local normalized = normalize_path(path)
  local stat = normalized and uv.fs_stat(normalized) or nil
  if not stat or stat.type ~= 'file' then
    return nil, nil
  end
  return normalized, stat
end

local function windows_for_buffer(bufnr)
  local wins = {}
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == bufnr then
      wins[#wins + 1] = winid
    end
  end
  return wins
end

local function strip_window(winid, bufnr)
  window_backups[bufnr] = window_backups[bufnr] or {}
  if not window_backups[bufnr][winid] then
    local backup = {}
    for _, option in ipairs(window_options) do
      backup[option] = vim.api.nvim_get_option_value(option, { win = winid })
    end
    window_backups[bufnr][winid] = backup
  end
  for option, value in pairs(stripped_window_options) do
    vim.api.nvim_set_option_value(option, value, { win = winid })
  end
end

local function restore_windows(bufnr)
  for winid, backup in pairs(window_backups[bufnr] or {}) do
    if vim.api.nvim_win_is_valid(winid) and vim.api.nvim_win_get_buf(winid) == bufnr then
      for option, value in pairs(backup) do
        vim.api.nvim_set_option_value(option, value, { win = winid })
      end
    end
  end
  window_backups[bufnr] = nil
end

local function detach_gitsigns(bufnr)
  local gitsigns = package.loaded.gitsigns
  if gitsigns and type(gitsigns.detach) == 'function' then
    pcall(gitsigns.detach, bufnr)
  end
end

function M.apply_stripped_mode(bufnr, reason)
  bufnr = resolve_bufnr(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  vim.b[bufnr].large_file_mode = true
  vim.b[bufnr].large_file_reason = reason or vim.b[bufnr].large_file_reason or 'size'
  vim.b[bufnr].did_filetype = true
  vim.bo[bufnr].filetype = ''
  vim.bo[bufnr].syntax = ''
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].undofile = false
  vim.bo[bufnr].undolevels = -1
  for _, winid in ipairs(windows_for_buffer(bufnr)) do
    strip_window(winid, bufnr)
  end

  pcall(vim.diagnostic.enable, false, { bufnr = bufnr })
  detach_gitsigns(bufnr)
end

function M.restore_rendering(bufnr)
  bufnr = resolve_bufnr(bufnr)
  restore_windows(bufnr)
  pcall(vim.diagnostic.enable, true, { bufnr = bufnr })
  vim.b[bufnr].large_file_mode = nil
  vim.b[bufnr].large_file_reason = nil
end

local function looks_like_longline(path, size)
  if size < longline_probe_minimum then
    return false
  end

  local fd = uv.fs_open(path, 'r', 438)
  if not fd then
    return false
  end
  local sample = uv.fs_read(fd, math.min(size, 64 * 1024), 0)
  uv.fs_close(fd)
  if not sample or sample == '' then
    return false
  end

  local _, newlines = sample:gsub('\n', '')
  return (#sample / (newlines + 1)) > longline_average
end

local function should_strip(path, size)
  if size >= strip_threshold then
    return true, 'size'
  end
  if looks_like_longline(path, size) then
    return true, 'long-line'
  end
  return false, nil
end

local function open_file(path, mode, bang)
  local command = mode == 'vertical' and 'vsplit' or mode == 'horizontal' and 'split' or 'edit'
  vim.cmd {
    cmd = command,
    args = { path },
    bang = bang == true,
    magic = { file = false, bar = false },
  }
end

local function prepare_view_window(mode)
  if mode == 'vertical' then
    vim.cmd.vnew()
  elseif mode == 'horizontal' then
    vim.cmd.new()
  else
    vim.cmd.enew()
  end
end

function M.view_with_less(path, opts)
  opts = opts or {}
  local normalized, stat = regular_file(path)
  if not normalized then
    vim.notify(('Large file viewer: not a readable file: %s'):format(path), vim.log.levels.ERROR)
    return false
  end
  if vim.fn.executable 'less' ~= 1 then
    vim.notify('Large file viewer: `less` is not installed', vim.log.levels.ERROR)
    return false
  end

  prepare_view_window(opts.mode)
  local term_buf = vim.api.nvim_get_current_buf()
  vim.bo[term_buf].bufhidden = 'wipe'
  vim.bo[term_buf].swapfile = false
  local job = vim.fn.jobstart({ 'less', '-R', '--', normalized }, {
    term = true,
    on_exit = function()
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(term_buf) then
          pcall(vim.api.nvim_buf_delete, term_buf, { force = true })
        end
      end)
    end,
  })
  if job <= 0 then
    pcall(vim.api.nvim_buf_delete, term_buf, { force = true })
    vim.notify(('Large file viewer: failed to start `less` for %s'):format(normalized), vim.log.levels.ERROR)
    return false
  end
  vim.notify(('Streaming %.1f MiB with less'):format(stat.size / mib), vim.log.levels.INFO)
  vim.cmd.startinsert()
  return true
end

local function prompt_action(path, size)
  local message = ('%s is %.1f MiB. Neovim must load the complete file to edit it.'):format(
    vim.fn.fnamemodify(path, ':t'),
    size / mib
  )
  local choices = vim.fn.executable 'less' == 1
      and '&View with less\n&Force stripped edit\n&Cancel'
    or '&Force stripped edit\n&Cancel'
  local choice = vim.fn.confirm(message, choices, 1)
  if vim.fn.executable 'less' == 1 then
    return choice == 1 and 'view' or choice == 2 and 'force' or 'cancel'
  end
  return choice == 1 and 'force' or 'cancel'
end

function M.open(path, opts)
  opts = opts or {}
  local normalized, stat = regular_file(path)
  if not normalized then
    vim.notify(('LargeFileOpen: not a regular file: %s'):format(path), vim.log.levels.ERROR)
    return false
  end

  if stat.size <= extreme_threshold then
    open_file(normalized, opts.mode, opts.bang)
    return true
  end

  local action = opts.action or prompt_action(normalized, stat.size)
  if action == 'view' then
    return M.view_with_less(normalized, { mode = opts.mode })
  end
  if action == 'force' then
    open_file(normalized, opts.mode, opts.bang)
    return true
  end
  return true
end

local function placeholder(bufnr, path, size)
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
    'Large file deferred',
    '',
    ('Path: %s'):format(path),
    ('Size: %.1f MiB'):format(size / mib),
    '',
    'Waiting for: View with less / Force stripped edit / Cancel',
  })
  vim.bo[bufnr].modified = false
  vim.bo[bufnr].readonly = true
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].buftype = 'nofile'
  vim.bo[bufnr].bufhidden = 'wipe'
  vim.bo[bufnr].swapfile = false
  vim.b[bufnr].large_file_placeholder = true
end

local function reset_placeholder(bufnr)
  vim.bo[bufnr].buftype = ''
  vim.bo[bufnr].bufhidden = ''
  vim.bo[bufnr].readonly = false
  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { '' })
  vim.bo[bufnr].modified = false
  vim.b[bufnr].large_file_placeholder = nil
end

local function focus_buffer(bufnr)
  for _, winid in ipairs(windows_for_buffer(bufnr)) do
    vim.api.nvim_set_current_win(winid)
    return true
  end
  return false
end

local function prompt_startup_file(bufnr, path, size)
  if not vim.api.nvim_buf_is_valid(bufnr) or not focus_buffer(bufnr) then
    return
  end
  local action = prompt_action(path, size)
  if action == 'view' then
    M.view_with_less(path)
  elseif action == 'force' then
    reset_placeholder(bufnr)
    open_file(path, 'current')
  end
end

local function schedule_after_startup(callback)
  if vim.v.vim_did_enter == 1 then
    vim.schedule(callback)
    return
  end
  vim.api.nvim_create_autocmd('VimEnter', {
    once = true,
    callback = function()
      vim.schedule(callback)
    end,
  })
end

local function autocmd_pattern(path)
  return vim.fn.escape(path, [[\*?[{},]])
end

local function setup_startup_guards()
  local seen = {}
  for _, arg in ipairs(vim.fn.argv()) do
    local path, stat = regular_file(arg)
    if path and stat.size > extreme_threshold and not seen[path] then
      seen[path] = true
      vim.api.nvim_create_autocmd('BufReadCmd', {
        pattern = autocmd_pattern(path),
        once = true,
        callback = function(event)
          placeholder(event.buf, path, stat.size)
          schedule_after_startup(function()
            prompt_startup_file(event.buf, path, stat.size)
          end)
        end,
        desc = 'Guard extreme startup file before full-buffer loading',
      })
    end
  end
end

function M.enable_syntax(bufnr)
  bufnr = resolve_bufnr(bufnr)
  if not vim.b[bufnr].large_file_mode then
    vim.notify('LargeFileSyntax: current buffer is not in large-file mode', vim.log.levels.WARN)
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  local filetype = vim.filetype.match { filename = path, buf = bufnr }
  local language = filetype and vim.treesitter.language.get_lang(filetype) or nil
  if not language then
    vim.notify('LargeFileSyntax: could not determine a Treesitter language', vim.log.levels.ERROR)
    return
  end
  local ok, err = pcall(vim.treesitter.start, bufnr, language)
  if not ok then
    vim.notify(('LargeFileSyntax: %s'):format(err), vim.log.levels.ERROR)
    return
  end
  vim.notify(('LargeFileSyntax: enabled Treesitter (%s)'):format(language), vim.log.levels.WARN)
end

function M.faster_rendering_feature()
  return {
    on = true,
    defer = false,
    enable = function()
      M.restore_rendering(0)
    end,
    disable = function()
      M.apply_stripped_mode(0)
    end,
    is_active = function(bufnr)
      return not (vim.b[resolve_bufnr(bufnr)].large_file_mode == true)
    end,
  }
end

function M.setup()
  if setup_done then
    return
  end
  setup_done = true

  setup_startup_guards()

  vim.api.nvim_create_autocmd('BufReadPre', {
    group = vim.api.nvim_create_augroup('custom-large-file-early', { clear = true }),
    callback = function(event)
      local path, stat = regular_file(event.file)
      if not path then
        return
      end
      local strip, reason = should_strip(path, stat.size)
      if strip then
        M.apply_stripped_mode(event.buf, reason)
      end
    end,
    desc = 'Apply cheap large-file safeguards before reading',
  })

  vim.api.nvim_create_autocmd('BufWinEnter', {
    group = 'custom-large-file-early',
    callback = function(event)
      if vim.b[event.buf].large_file_mode then
        M.apply_stripped_mode(event.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd('FileType', {
    group = 'custom-large-file-early',
    callback = function(event)
      if vim.b[event.buf].large_file_mode then
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(event.buf) then
            pcall(vim.treesitter.stop, event.buf)
          end
        end)
      end
    end,
  })

  vim.api.nvim_create_autocmd('BufWipeout', {
    group = 'custom-large-file-early',
    callback = function(event)
      window_backups[event.buf] = nil
    end,
  })

  pcall(vim.api.nvim_del_user_command, 'LargeFileOpen')
  vim.api.nvim_create_user_command('LargeFileOpen', function(opts)
    M.open(opts.fargs[1])
  end, {
    nargs = 1,
    complete = 'file',
    desc = 'Open a file with extreme-file protection',
  })

  pcall(vim.api.nvim_del_user_command, 'LargeFileSyntax')
  vim.api.nvim_create_user_command('LargeFileSyntax', function()
    M.enable_syntax(0)
  end, {
    desc = 'Explicitly enable Treesitter for the current large file',
  })
end

return M
