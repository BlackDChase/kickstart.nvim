local M = {}

local state = {
  oil_win = nil, ---@type integer|nil
  source_win = nil, ---@type integer|nil
}

local function is_valid_win(win)
  return type(win) == 'number' and win ~= 0 and vim.api.nvim_win_is_valid(win)
end

local function is_oil_win(win)
  if not is_valid_win(win) then
    return false
  end
  local buf = vim.api.nvim_win_get_buf(win)
  return vim.bo[buf].filetype == 'oil'
end

local function find_any_non_oil_win(except_win)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= except_win and not is_oil_win(win) then
      return win
    end
  end
  return nil
end

function M.winbar()
  local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
  local ok, dir = pcall(require('oil').get_current_dir, bufnr)
  if ok and dir then
    return vim.fn.fnamemodify(dir, ':~')
  end
  return vim.api.nvim_buf_get_name(bufnr)
end

function M.toggle()
  if is_valid_win(state.oil_win) then
    local oil_win = state.oil_win
    state.oil_win = nil
    pcall(vim.api.nvim_set_current_win, oil_win)
    pcall(require('oil').close)
    pcall(vim.api.nvim_win_close, oil_win, true)
    return
  end

  state.source_win = vim.api.nvim_get_current_win()
  local width = math.floor(vim.o.columns * 0.33)
  width = math.max(26, math.min(width, 48))

  vim.cmd('topleft ' .. width .. 'vsplit')
  state.oil_win = vim.api.nvim_get_current_win()
  vim.wo.winfixwidth = true

  require('oil').open()
end

function M.select()
  local oil = require 'oil'
  local entry = oil.get_cursor_entry()
  if not entry then
    return
  end

  if entry.type ~= 'file' then
    return oil.select()
  end

  local dir = oil.get_current_dir()
  if not dir then
    return oil.select()
  end

  local target = state.source_win
  if not is_valid_win(target) or is_oil_win(target) then
    target = find_any_non_oil_win(state.oil_win)
  end

  if not is_valid_win(target) then
    return oil.select()
  end

  vim.api.nvim_set_current_win(target)
  vim.cmd('edit ' .. vim.fn.fnameescape(dir .. entry.name))
end

return M

