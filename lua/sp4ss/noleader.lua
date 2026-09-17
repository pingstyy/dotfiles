-- Space-leader maps still work. In NORMAL mode, some also work WITHOUT Space.
-- Rules (do not steal Vim):
--   * 2+ char Space maps are cloned leaderless (tt, rr, ff, ii, …).
--     First key waits timeoutlen, then Vim meaning (i=insert, t=till, …).
--   * `g` wait = top of file; `gg` = lazygit; `gd`/`gs`/`gf` still work (g-prefix).
--   * normal `e` = explorer (Space e still works). `de`/`ce`/`ye` unchanged.

local M = {}

local SKIP_EXACT = {
    gg = true, -- go to first line
    gd = true,
    gD = true,
    gr = true,
    gI = true,
    gy = true,
    gv = true,
    gi = true,
    gf = true,
    gt = true,
    gT = true,
    gn = true,
    gN = true,
    gw = true,
    gq = true,
    ga = true,
    gu = true,
    gU = true,
    gp = true, -- paste, cursor after
    gP = true,
}

-- Only block prefixes we intercept ourselves, or keys that cannot start a
-- 2-key sequence. `t`/`i`/`r`/`f`/`h`/`s`/`u` ARE cloned (tt, ii, rr, …).
local SKIP_PREFIX = {
    g = true, -- g-prefix dispatcher
    ["."] = true,
    ["/"] = true,
    [":"] = true,
    ["?"] = true,
    [","] = true,
    [";"] = true,
    ['"'] = true,
    ["'"] = true,
    ["["] = true,
    ["]"] = true,
    ["{"] = true,
    ["}"] = true,
    ["0"] = true,
    ["1"] = true,
    ["2"] = true,
    ["3"] = true,
    ["4"] = true,
    ["5"] = true,
    ["6"] = true,
    ["7"] = true,
    ["8"] = true,
    ["9"] = true,
}

local function strip_leader(lhs)
    if type(lhs) ~= "string" or lhs == "" then
        return nil
    end
    if lhs:sub(1, 8) == "<Leader>" or lhs:sub(1, 8) == "<leader>" then
        return lhs:sub(9)
    end
    if lhs:sub(1, 7) == "<Space>" then
        return lhs:sub(8)
    end
    if lhs:sub(1, 7) == "<space>" then
        return lhs:sub(8)
    end
    local l = vim.g.mapleader
    if l == " " and lhs:sub(1, 1) == " " then
        return lhs:sub(2)
    end
    if type(l) == "string" and l ~= " " and lhs:sub(1, #l) == l then
        return lhs:sub(#l + 1)
    end
    return nil
end

local function already_mapped(lhs)
    local arg = vim.fn.maparg(lhs, "n")
    return type(arg) == "string" and arg ~= ""
end

local function allowed(rest)
    if rest == nil or rest == "" then
        return false
    end
    if rest:sub(1, 1) == "<" then
        return false
    end
    if SKIP_EXACT[rest] then
        return false
    end
    if #rest < 2 then
        return false
    end
    local first = rest:sub(1, 1)
    if SKIP_PREFIX[first] then
        return false
    end
    if already_mapped(rest) then
        return false
    end
    return true
end

local function explorer_toggle()
    local ok, Snacks = pcall(require, "snacks")
    if not ok then
        return
    end
    local explorer = Snacks.picker.get({ source = "explorer" })[1]
    if not explorer then
        Snacks.explorer()
        return
    end
    if explorer:is_focused() then
        explorer:close()
    else
        explorer:focus()
    end
end

local function wait_key(ms)
    local key
    vim.wait(ms, function()
        local n = vim.fn.getchar(0)
        if n == 0 then
            return false
        end
        if type(n) == "number" then
            key = vim.fn.nr2char(n)
        else
            key = n
        end
        return true
    end, 10)
    return key
end

local function run_n_map(seq, count)
    local map = vim.fn.maparg(seq, "n", false, true)
    if type(map) ~= "table" or (not map.callback and (not map.rhs or map.rhs == "")) then
        local leader = vim.g.mapleader == " " and "<Space>" or (vim.g.mapleader or "")
        map = vim.fn.maparg(leader .. seq, "n", false, true)
    end
    if type(map) == "table" and map.callback then
        return map.callback()
    end
    if type(map) == "table" and map.rhs and map.rhs ~= "" then
        local keys = vim.api.nvim_replace_termcodes(map.rhs, true, false, true)
        vim.api.nvim_feedkeys(keys, map.noremap == 1 and "n" or "m", false)
        return
    end
    local cmd = (count and count > 0) and ("normal! " .. count .. seq) or ("normal! " .. seq)
    pcall(vim.cmd, cmd)
end

local function lhs_has_longer(prefix)
    for _, m in ipairs(vim.api.nvim_get_keymap("n")) do
        local lhs = m.lhs or ""
        local rest = strip_leader(lhs) or lhs
        if #rest > #prefix and rest:sub(1, #prefix) == prefix then
            return true
        end
    end
    return false
end

local function map_g_prefix()
    vim.keymap.set("n", "g", function()
        local count = vim.v.count
        local seq = "g"
        local c = wait_key(vim.o.timeoutlen)
        if not c or c == "\27" then
            pcall(vim.cmd, count > 0 and ("normal! " .. count .. "gg") or "normal! gg")
            return
        end
        seq = seq .. c
        if seq == "gg" then
            local ok, Snacks = pcall(require, "snacks")
            if ok then
                Snacks.lazygit()
            end
            return
        end
        while lhs_has_longer(seq) do
            local more = wait_key(vim.o.timeoutlen)
            if not more or more == "\27" then
                break
            end
            seq = seq .. more
        end
        run_n_map(seq, count)
    end, { desc = "g wait=top  gg=lazygit  gd/gs/gf=same" })
end

local function map_e_explorer()
    -- Normal `e` = explorer. Do NOT map operator-pending/visual, so de/ce/ye/ve still work.
    vim.keymap.set("n", "e", explorer_toggle, { desc = "Explorer (Space e also)" })
end

function M.apply()
    map_e_explorer()
    map_g_prefix()

    local maps = vim.api.nvim_get_keymap("n")
    for _, m in ipairs(maps) do
        local rest = strip_leader(m.lhs)
        if rest and allowed(rest) then
            local rhs = m.callback or m.rhs
            if rhs then
                local ok = pcall(vim.keymap.set, "n", rest, rhs, {
                    desc = (m.desc or rest) .. " (no leader)",
                    silent = m.silent == 1,
                    noremap = (m.noremap ~= 0),
                    expr = m.expr == 1,
                })
                if not ok then
                    -- skip broken clone; leader map still works
                end
            end
        end
    end
end

function M.setup()
    -- Distinguish ff vs fx, rr vs rX, ee vs e. Keep which-key usable.
    if vim.o.timeoutlen > 500 then
        vim.o.timeoutlen = 400
    end
    vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
            vim.schedule(M.apply)
        end,
    })
end

return M
