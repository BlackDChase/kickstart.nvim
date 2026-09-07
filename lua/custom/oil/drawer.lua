local M = {}

local state = {
    oil_win = nil, ---@type integer|nil
    source_win = nil, ---@type integer|nil
    marked_files = {}, ---@type table<string, boolean>
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

local function get_target_win()
    local target = state.source_win
    if not is_valid_win(target) or is_oil_win(target) then
        target = find_any_non_oil_win(state.oil_win)
    end
    return target
end

local function file_path_for_entry(dir, entry)
    if not dir or not entry or entry.type ~= 'file' then
        return nil
    end
    return dir .. entry.name
end

local function open_path_in_target(path, open_mode)
    local target = get_target_win()
    if not is_valid_win(target) then
        return false
    end

    vim.api.nvim_set_current_win(target)
    return require('custom.large_file').open(path, { mode = open_mode })
end

local function pick_open_mode(default_mode)
    if default_mode == 'vertical' or default_mode == 'horizontal' or default_mode == 'current' then
        return default_mode
    end
    local choice = vim.fn.confirm('Open file in', '&Current\n&Horizontal split\n&Vertical split\n&Cancel', 1)
    if choice == 1 then
        return 'current'
    elseif choice == 2 then
        return 'horizontal'
    elseif choice == 3 then
        return 'vertical'
    end
    return nil
end

local function get_selected_file_paths()
    local oil = require 'oil'
    local util = require 'oil.util'
    local dir = oil.get_current_dir()
    if not dir then
        return {}
    end

    local range = util.get_visual_range()
    if not range then
        local entry = oil.get_cursor_entry()
        local path = file_path_for_entry(dir, entry)
        return path and { path } or {}
    end

    local paths = {}
    local seen = {}
    for line = range.start_lnum, range.end_lnum do
        local entry = oil.get_entry_on_line(0, line)
        local path = file_path_for_entry(dir, entry)
        if path and not seen[path] then
            seen[path] = true
            paths[#paths + 1] = path
        end
    end
    return paths
end

local function get_marked_file_paths()
    local paths = {}
    for path, marked in pairs(state.marked_files) do
        if marked then
            paths[#paths + 1] = path
        end
    end
    table.sort(paths)
    return paths
end

local function add_paths_to_buffer_list(paths)
    local added = 0
    for _, path in ipairs(paths) do
        if vim.fn.filereadable(path) == 1 then
            vim.cmd('badd ' .. vim.fn.fnameescape(path))
            added = added + 1
        end
    end
    return added
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

    local path = file_path_for_entry(dir, entry)
    if not path then
        return oil.select()
    end

    if not open_path_in_target(path, 'current') then
        return oil.select()
    end
end

function M.select_split(mode)
    local oil = require 'oil'
    local entry = oil.get_cursor_entry()
    if not entry then
        return
    end
    if entry.type ~= 'file' then
        return oil.select()
    end

    local dir = oil.get_current_dir()
    local path = file_path_for_entry(dir, entry)
    local open_mode = pick_open_mode(mode)
    if not path or not open_mode then
        return
    end

    if not open_path_in_target(path, open_mode) then
        if open_mode == 'vertical' then
            return oil.select { vertical = true }
        elseif open_mode == 'horizontal' then
            return oil.select { horizontal = true }
        end
        return oil.select()
    end
end

function M.toggle_mark()
    local oil = require 'oil'
    local entry = oil.get_cursor_entry()
    if not entry or entry.type ~= 'file' then
        vim.notify('Oil mark: cursor is not on a file', vim.log.levels.WARN)
        return
    end
    local path = file_path_for_entry(oil.get_current_dir(), entry)
    if not path then
        return
    end
    state.marked_files[path] = not state.marked_files[path]
    local action = state.marked_files[path] and 'marked' or 'unmarked'
    vim.notify(('Oil mark %s: %s'):format(action, vim.fn.fnamemodify(path, ':~')), vim.log.levels.INFO)
end

function M.clear_marks()
    state.marked_files = {}
    vim.notify('Oil marks cleared', vim.log.levels.INFO)
end

function M.add_to_buffer_list()
    local paths = get_marked_file_paths()
    if #paths == 0 then
        paths = get_selected_file_paths()
    end
    if #paths == 0 then
        vim.notify('Oil buffer add: no files selected/marked', vim.log.levels.WARN)
        return
    end

    local added = add_paths_to_buffer_list(paths)
    if added == 0 then
        vim.notify('Oil buffer add: no readable files added', vim.log.levels.WARN)
        return
    end
    vim.notify(('Oil buffer add: added %d file(s)'):format(added), vim.log.levels.INFO)
end

function M.setup_commands()
    pcall(vim.api.nvim_del_user_command, 'OilDrawerOpenSplit')
    vim.api.nvim_create_user_command('OilDrawerOpenSplit', function(opts)
        local arg = (opts.args or ''):lower()
        local mode = nil
        if arg == 'v' or arg == 'vertical' then
            mode = 'vertical'
        elseif arg == 'h' or arg == 'horizontal' then
            mode = 'horizontal'
        elseif arg == 'c' or arg == 'current' then
            mode = 'current'
        end
        M.select_split(mode)
    end, {
        nargs = '?',
        complete = function()
            return { 'current', 'horizontal', 'vertical' }
        end,
        desc = 'Oil drawer: open current file in current/horizontal/vertical split',
    })

    pcall(vim.api.nvim_del_user_command, 'OilDrawerBufferAdd')
    vim.api.nvim_create_user_command('OilDrawerBufferAdd', function()
        M.add_to_buffer_list()
    end, {
        desc = 'Oil drawer: add marked or visual-selected files to buffer list',
    })

    pcall(vim.api.nvim_del_user_command, 'OilDrawerMarkToggle')
    vim.api.nvim_create_user_command('OilDrawerMarkToggle', function()
        M.toggle_mark()
    end, {
        desc = 'Oil drawer: toggle mark on current file',
    })

    pcall(vim.api.nvim_del_user_command, 'OilDrawerMarkClear')
    vim.api.nvim_create_user_command('OilDrawerMarkClear', function()
        M.clear_marks()
    end, {
        desc = 'Oil drawer: clear all marked files',
    })
end

return M
