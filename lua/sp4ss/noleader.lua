-- Space-leader maps still work. In NORMAL mode, the same pairs work WITHOUT Space.
-- `lazy.setup` fires User VeryLazy before this module's setup() runs, so apply()
-- is also scheduled immediately. The autocmd covers a setup that runs earlier.
--
-- `g` + timeout = top of file. `gg` = lazygit. Other g-keys (`gd`, `gs`, …) stay
-- real maps when they exist; otherwise the pending key is forwarded once.
-- Normal `e` = explorer. Operator-pending `e` stays free so `de`/`ce`/`ye` work.

local M = {}

local SKIP_EXACT = {
    gg = true,
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
    gp = true,
    gP = true,
}

-- Prefixes we dispatch ourselves, or keys that must not start a leaderless pair.
-- `t`/`i`/`r`/`f`/`h`/`s`/`u` ARE cloned (tt, ii, rr, …).
local SKIP_PREFIX = {
    g = true,
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

local function lazygit()
    local ok, Snacks = pcall(require, "snacks")
    if ok and Snacks.lazygit then
        Snacks.lazygit()
    end
end

local function git_log()
    local ok, Snacks = pcall(require, "snacks")
    if ok and Snacks.picker and Snacks.picker.git_log then
        Snacks.picker.git_log()
    end
end

local function git_status()
    local ok, Snacks = pcall(require, "snacks")
    if ok and Snacks.picker and Snacks.picker.git_status then
        Snacks.picker.git_status()
    end
end

-- Real two-key maps. Neovim's own timeoutlen picks `g` vs `gg` vs `gd`.
-- No getchar/vim.wait: that path drops the second key (gg never reached lazygit).
local G_BUILTIN = {
    "e", "E", "j", "k", "0", "^", "$", "m", "M", "_", "+", "-",
    "F", "f", "i", "v", "n", "N", "q", "w", "u", "U", "~", "x",
    "*", "#", "%", "J", "t", "T", "p", "P", "&", ",", ";", "'", "`",
}

local function map_builtin_g(suffix)
    local lhs = "g" .. suffix
    -- noremap rhs = builtin. Operators (gu/gU/gq/…) still take the next motion.
    vim.keymap.set("n", lhs, lhs, { noremap = true, desc = "builtin " .. lhs })
end

local function map_diff_hunk(lhs, action)
    local m = vim.fn.maparg(lhs, "n", false, true)
    if type(m) == "table" and m.desc and m.desc:lower():find("hunk", 1, true) then
        return
    end
    vim.keymap.set("n", lhs, function()
        require("lazy").load({ plugins = { "mini.diff" } })
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(lhs, true, false, true), "m", false)
    end, { desc = "Diff " .. action .. " hunk" })
end

local function map_g_prefix()
    for _, suffix in ipairs(G_BUILTIN) do
        if not already_mapped("g" .. suffix) then
            map_builtin_g(suffix)
        end
    end
    vim.keymap.set("n", "gg", lazygit, { desc = "Lazygit" })
    vim.keymap.set("n", "<leader>gg", lazygit, { desc = "Lazygit" })
    vim.keymap.set("n", "<leader>gl", git_log, { desc = "Git Log" })
    vim.keymap.set("n", "gs", git_status, { desc = "Git Status" })
    vim.keymap.set("n", "<leader>gs", git_status, { desc = "Git Status" })
    map_diff_hunk("gh", "apply")
    map_diff_hunk("gH", "reset")
    -- snacks and mini.diff both bind <leader>gd. Cheats: overlay.
    vim.keymap.set("n", "<leader>gd", function()
        require("mini.diff").toggle_overlay(0)
    end, { desc = "Diff overlay toggle" })
    vim.keymap.set("n", "g", function()
        local c = vim.v.count
        vim.cmd((c > 0) and ("normal! " .. c .. "gg") or "normal! gg")
    end, { desc = "g wait=top of file" })
end

local function map_e_explorer()
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
                pcall(vim.keymap.set, "n", rest, rhs, {
                    desc = (m.desc or rest) .. " (no leader)",
                    silent = m.silent == 1,
                    noremap = (m.noremap ~= 0),
                    expr = m.expr == 1,
                })
            end
        end
    end

    -- After the clone pass so Space ss / ss stay scope select
    -- (snacks document symbols are Space sy).
    local function scope_select()
        require("sp4ss.scope_select").select()
    end
    vim.keymap.set("n", "ss", scope_select, { desc = "Select scope" })
    vim.keymap.set("n", "<leader>ss", scope_select, { desc = "Select scope" })

    vim.keymap.set("n", "gk", function()
        local ok, Snacks = pcall(require, "snacks")
        if not ok then
            return
        end
        Snacks.picker.lsp_definitions({
            auto_confirm = false,
            jump = { tagstack = true, reuse_win = true },
        })
    end, { desc = "Preview definition" })
end

function M.setup()
    if vim.o.timeoutlen > 500 then
        vim.o.timeoutlen = 400
    end
    -- lazy.setup() can fire VeryLazy before this setup() call. A later
    -- VimEnter pass catches leader maps. The VeryLazy pass catches iron,
    -- which maps <leader>ii only when that event loads the plugin.
    local function safe_apply()
        local ok, err = pcall(M.apply)
        if not ok then
            vim.schedule(function()
                vim.notify("noleader: " .. tostring(err), vim.log.levels.ERROR)
            end)
        end
    end
    vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
            vim.schedule(safe_apply)
        end,
    })
    vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
            vim.schedule(safe_apply)
        end,
    })
    vim.defer_fn(safe_apply, 300)
end

return M
