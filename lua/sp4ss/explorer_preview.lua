-- Explorer hover preview: float over the main editor (~90% of that window).
-- Not a split inside the nav panel.
local M = {}

local state = {
    win = nil,
    buf = nil,
    path = nil,
    token = 0,
    -- After Enter-open, don't resurrect preview for this path until cursor moves.
    opened = nil,
}

local function hide()
    -- Cancel any deferred show() still in flight.
    state.token = state.token + 1
    state.path = nil
    if state.win and vim.api.nvim_win_is_valid(state.win) then
        pcall(vim.api.nvim_win_close, state.win, true)
    end
    state.win = nil
    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
        pcall(vim.api.nvim_buf_delete, state.buf, { force = true })
    end
    state.buf = nil
end

M.hide = hide

function M.opened(path)
    if type(path) == "string" and path ~= "" then
        state.opened = vim.fn.fnamemodify(path, ":p")
    end
    hide()
end

local function main_win(picker)
    if picker and picker.main then
        local ok, win = pcall(function()
            return picker._main and picker._main:get() or picker.main
        end)
        if ok and type(win) == "number" and vim.api.nvim_win_is_valid(win) then
            local cfg = vim.api.nvim_win_get_config(win)
            if cfg.relative == "" then
                return win
            end
        end
    end
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local cfg = vim.api.nvim_win_get_config(win)
        if cfg.relative == "" then
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].buftype == "" then
                return win
            end
        end
    end
    return nil
end

local function ensure_buf()
    if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
        return state.buf
    end
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].buftype = "nofile"
    vim.bo[buf].swapfile = false
    vim.bo[buf].modifiable = true
    vim.b[buf].snacks_previewed = true
    state.buf = buf
    return buf
end

local function load_file(buf, path)
    local lines = vim.fn.readfile(path, "", 500)
    if type(lines) ~= "table" then
        lines = { "(unreadable)" }
    end
    for i, line in ipairs(lines) do
        if line:find("\0") then
            lines = { "[binary file]  " .. vim.fn.fnamemodify(path, ":t") }
            break
        end
        if #line > 400 then
            lines[i] = line:sub(1, 400) .. "…"
        end
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.bo[buf].readonly = true
    -- Do NOT set markdown filetype: image.nvim + treesitter injections crash
    -- (node:range nil) on scratch/float buffers. Syntax-only is enough for peek.
    pcall(vim.treesitter.stop, buf)
    local ft = vim.filetype.match({ filename = path, buf = buf }) or ""
    if ft ~= "" and ft ~= "markdown" and ft ~= "vimwiki" then
        pcall(function()
            vim.bo[buf].syntax = ft
        end)
    elseif ft == "markdown" or ft == "vimwiki" then
        pcall(function()
            vim.bo[buf].syntax = "markdown"
        end)
    end
end

--- True if a real editor split already shows this file (don't overlay it).
local function editor_shows(path)
    path = vim.fn.fnamemodify(path, ":p")
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local cfg = vim.api.nvim_win_get_config(win)
        if cfg.relative == "" then
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].buftype == "" and not vim.b[buf].snacks_previewed then
                local name = vim.api.nvim_buf_get_name(buf)
                if name ~= "" and vim.fn.fnamemodify(name, ":p") == path then
                    return true
                end
            end
        end
    end
    return false
end

local function place(picker)
    local parent = main_win(picker)
    if not parent then
        return nil
    end
    local width = vim.api.nvim_win_get_width(parent)
    local height = vim.api.nvim_win_get_height(parent)
    local w = math.max(24, math.floor(width * 0.90))
    local h = math.max(8, math.floor(height * 0.90))
    local row = math.floor((height - h) / 2)
    local col = math.floor((width - w) / 2)
    return {
        relative = "win",
        win = parent,
        width = w,
        height = h,
        row = row,
        col = col,
        style = "minimal",
        border = "rounded",
        zindex = 40,
        noautocmd = true,
        title = " preview ",
        title_pos = "center",
        focusable = false,
    }
end

function M.show(picker, item)
    state.token = state.token + 1
    local token = state.token
    vim.defer_fn(function()
        if token ~= state.token then
            return
        end
        if not item or item.dir or type(item.file) ~= "string" or item.file == "" then
            hide()
            return
        end
        local path = vim.fn.fnamemodify(item.file, ":p")
        if state.opened and path ~= state.opened then
            state.opened = nil
        end
        -- Opened this file, or editor already showing it → no overlay.
        if state.opened == path or editor_shows(path) then
            hide()
            return
        end
        if vim.fn.filereadable(path) ~= 1 then
            hide()
            return
        end
        local cfg = place(picker)
        if not cfg then
            hide()
            return
        end
        local buf = ensure_buf()
        if state.path ~= path then
            load_file(buf, path)
            state.path = path
            cfg.title = " " .. vim.fn.fnamemodify(path, ":t") .. " "
        end
        if state.win and vim.api.nvim_win_is_valid(state.win) then
            pcall(vim.api.nvim_win_set_config, state.win, cfg)
            if vim.api.nvim_win_get_buf(state.win) ~= buf then
                vim.api.nvim_win_set_buf(state.win, buf)
            end
            return
        end
        state.win = vim.api.nvim_open_win(buf, false, cfg)
        vim.wo[state.win].wrap = false
        vim.wo[state.win].cursorline = false
        vim.wo[state.win].number = false
        vim.wo[state.win].relativenumber = false
        vim.wo[state.win].signcolumn = "no"
        vim.wo[state.win].winhighlight = "Normal:Normal,FloatBorder:FloatBorder"
    end, 50)
end

-- Real file landed in an editor split. Mark it even if preview already hid
-- (WinLeave races BufEnter, then on_change would resurrect the float).
vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = vim.api.nvim_create_augroup("sp4ss_explorer_preview", { clear = true }),
    callback = function(ev)
        if not vim.api.nvim_buf_is_valid(ev.buf) then
            return
        end
        if vim.bo[ev.buf].buftype ~= "" or vim.b[ev.buf].snacks_previewed then
            return
        end
        local name = vim.api.nvim_buf_get_name(ev.buf)
        if name == "" then
            return
        end
        if not editor_shows(name) then
            return
        end
        M.opened(name)
    end,
})

return M
