local M = {}

local branch_cache = {} ---@type table<string, string|false>

local function get_git_branch(path)
  if branch_cache[path] ~= nil then
    return branch_cache[path]
  end

  if vim.fn.executable 'git' ~= 1 then
    branch_cache[path] = false
    return branch_cache[path]
  end

  local obj = vim.system({ 'git', '-C', path, 'rev-parse', '--abbrev-ref', 'HEAD' }, { text = true })
  local res = obj:wait()
  if res.code ~= 0 then
    branch_cache[path] = false
    return branch_cache[path]
  end

  local branch = vim.trim(res.stdout or '')
  if branch == '' or branch == 'HEAD' then
    branch_cache[path] = false
    return branch_cache[path]
  end

  branch_cache[path] = branch
  return branch_cache[path]
end

local function guess_project_root_from_buffer()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  if name == '' then
    return vim.uv.cwd()
  end

  local dir = vim.fs.dirname(name)
  if not dir or dir == '' then
    return vim.uv.cwd()
  end

  if vim.fn.executable 'git' == 1 then
    local obj = vim.system({ 'git', '-C', dir, 'rev-parse', '--show-toplevel' }, { text = true })
    local res = obj:wait()
    if res.code == 0 then
      local root = vim.trim(res.stdout or '')
      if root ~= '' then
        return root
      end
    end
  end

  return dir
end

function M.add_project_from_current_buffer()
  local project_actions = require 'telescope._extensions.project.actions'
  project_actions.add_project_path(guess_project_root_from_buffer())
end

function M.setup()
  local finders = require 'telescope._extensions.project.finders'

  if finders.__custom_branch_patched then
    return
  end
  finders.__custom_branch_patched = true

  local original_project_finder = finders.project_finder
  finders.project_finder = function(opts, projects)
    for _, project in pairs(projects) do
      local branch = get_git_branch(project.path)
      project.branch = branch or ''
    end

    local ok, finder = pcall(original_project_finder, opts, projects)
    if not ok then
      error(finder)
    end

    local old_entry_maker = finder.entry_maker
    finder.entry_maker = function(project)
      local entry = old_entry_maker(project)
      if entry.ordinal and project.branch and project.branch ~= '' then
        entry.ordinal = entry.ordinal .. ' ' .. project.branch
      end
      local original_display = entry.display
      entry.display = function(it)
        local base, hl = original_display(it)
        if it.branch and it.branch ~= '' then
          return string.format('%s [%s]', base, it.branch), hl
        end
        return base, hl
      end
      return entry
    end

    return finder
  end
end

return M
