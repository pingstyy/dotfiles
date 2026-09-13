-- Tiny top file banner. Cmd+1-9/0 jump, Cmd+Ctrl cycle, Cmd+w close.
-- List = files you open this session + last-used files (vim oldfiles), max 10.
-- Order stays stable so Cmd+N does not shuffle.
local M = {}

local MAX = 10
--- Ordered absolute paths shown as tabs.
local files = {}

local function norm(path)
    if type(path) ~= "string" or path == "" then
        return nil
    end
    if path:match("^%w+://") then
        return nil
    end
    local p = vim.fn.fnamemodify(path, ":p")
    if p == "" or p == "/" then
        return nil
    end
    return p
end

local function skip_path(path)
    if not path then
        return true
    end
    if path:match("COMMIT_EDITMSG") or path:match("git%-rebase%-todo") then
        return true
    end
    if path:match("[/\\]lazy[/\\]") then
        return true
    end
    if vim.fn.isdirectory(path) == 1 then
        return true
    end
    return false
end

local function index_of(path)
    for i, p in ipairs(files) do
        if p == path then
            return i
        end
    end
    return nil
end

local function current_path()
    local name = vim.api.nvim_buf_get_name(0)
    return norm(name)
end

function M.add(path, pos)
    path = norm(path)
    if skip_path(path) then
        return
    end
    local i = index_of(path)
    if i then
        return
    end
    if pos and pos >= 1 and pos <= #files + 1 then
        table.insert(files, pos, path)
    else
        table.insert(files, path)
    end
    while #files > MAX do
        local cur = current_path()
        local drop = nil
        for n, p in ipairs(files) do
            if p ~= cur then
                drop = n
                break
            end
        end
        if not drop then
            break
        end
        table.remove(files, drop)
    end
    pcall(vim.cmd.redrawtabline)
end

function M.remove(path)
    path = norm(path) or current_path()
    local i = index_of(path)
    if i then
        table.remove(files, i)
    end
    pcall(vim.cmd.redrawtabline)
end

local function seed_recent()
    for _, old in ipairs(vim.v.oldfiles or {}) do
        if #files >= MAX then
            break
        end
        local p = norm(old)
        if p and not skip_path(p) and vim.fn.filereadable(p) == 1 then
            M.add(p)
        end
    end
end

local function label(path)
    local tail = vim.fn.fnamemodify(path, ":t")
    if tail == "" then
        tail = "[No Name]"
    end
    if #tail > 14 then
        tail = tail:sub(1, 13) .. "…"
    end
    local buf = vim.fn.bufnr(path)
    if buf > 0 and vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modified then
        tail = tail .. "+"
    end
    return tail:gsub("%%", "%%%%")
end

function M.render()
    if #files == 0 then
        return "%#TabLine# open a file → tab  %#TabLineFill#"
    end
    local cur = current_path()
    local parts = {}
    for i, path in ipairs(files) do
        local hl = path == cur and "%#TabLineSel#" or "%#TabLine#"
        local n = i <= 9 and tostring(i) or (i == 10 and "0" or " ")
        table.insert(parts, string.format("%s%%%d@v:lua.Sp4ssTabClick@ %s:%s %%X", hl, i, n, label(path)))
    end
    table.insert(parts, "%#TabLineFill#")
    return table.concat(parts)
end

function M.go(idx)
    local path = files[idx]
    if not path then
        return
    end
    vim.cmd.edit(vim.fn.fnameescape(path))
end

function M.cycle(delta)
    if #files == 0 then
        return
    end
    local cur = current_path()
    local here = index_of(cur) or 1
    local nxt = ((here - 1 + delta) % #files) + 1
    M.go(nxt)
end

function M.close(idx)
    local path = idx and files[idx] or current_path()
    if not path then
        return
    end
    local buf = vim.fn.bufnr(path)
    M.remove(path)
    if buf > 0 and vim.api.nvim_buf_is_valid(buf) then
        local ok = pcall(function()
            Snacks.bufdelete(buf)
        end)
        if not ok then
            pcall(vim.cmd.bdelete, buf)
        end
    end
end

function M.click(idx, _, button)
    if button == "m" then
        M.close(idx)
        return
    end
    M.go(idx)
end

function M.setup()
    -- Keep opened files around so they stay jumpable.
    vim.opt.hidden = true
    _G.Sp4ssTabline = M.render
    _G.Sp4ssTabClick = M.click

    local function force_tabline()
        vim.o.showtabline = 2
        vim.o.tabline = "%!v:lua.Sp4ssTabline()"
    end
    force_tabline()

    local modes = { "n", "i", "v", "t" }
    for i = 1, 9 do
        vim.keymap.set(modes, "<D-" .. i .. ">", function()
            M.go(i)
        end, { desc = "Tab " .. i, silent = true })
    end
    vim.keymap.set(modes, "<D-0>", function()
        M.go(10)
    end, { desc = "Tab 10", silent = true })

    local function cycle_next()
        M.cycle(1)
    end
    local function cycle_prev()
        M.cycle(-1)
    end
    for _, lhs in ipairs({ "<D-C-l>", "<D-C-Right>", "<D-C-n>" }) do
        vim.keymap.set(modes, lhs, cycle_next, { desc = "Next tab", silent = true })
    end
    for _, lhs in ipairs({ "<D-C-h>", "<D-C-Left>", "<D-C-p>" }) do
        vim.keymap.set(modes, lhs, cycle_prev, { desc = "Prev tab", silent = true })
    end

    vim.keymap.set(modes, "<D-w>", function()
        M.close()
    end, { desc = "Close tab", silent = true })

    local grp = vim.api.nvim_create_augroup("sp4ss_tabs", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost", "BufNewFile" }, {
        group = grp,
        callback = function(ev)
            if not vim.api.nvim_buf_is_valid(ev.buf) then
                return
            end
            if vim.bo[ev.buf].buftype ~= "" then
                return
            end
            -- Explorer live-preview must not pin a tab.
            if vim.b[ev.buf].snacks_previewed or vim.bo[ev.buf].filetype == "snacks_picker_preview" then
                return
            end
            M.add(vim.api.nvim_buf_get_name(ev.buf))
            force_tabline()
        end,
    })
    vim.api.nvim_create_autocmd({ "VimEnter", "UIEnter" }, {
        group = grp,
        callback = function()
            vim.schedule(function()
                M.add(vim.api.nvim_buf_get_name(0))
                seed_recent()
                force_tabline()
                pcall(vim.cmd.redrawtabline)
            end)
        end,
    })
    -- Snacks dashboard sets showtabline=0; put the bar back.
    vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "ColorScheme" }, {
        group = grp,
        callback = function()
            if vim.o.showtabline ~= 2 then
                force_tabline()
            end
        end,
    })
    vim.api.nvim_create_autocmd({ "BufDelete", "BufFilePost", "BufModifiedSet" }, {
        group = grp,
        callback = function()
            vim.schedule(function()
                pcall(vim.cmd.redrawtabline)
            end)
        end,
    })
end

return M
