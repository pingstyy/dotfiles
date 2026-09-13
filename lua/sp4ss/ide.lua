local autosave_group = vim.api.nvim_create_augroup("Autosave", { clear = true })

vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
    group = autosave_group,
    callback = function()
        if vim.bo.modified and vim.bo.buftype == "" then
            vim.cmd("silent! write")
        end
    end,
})

---------------------------------------------------------------------------
-- VS Code-like: light-highlight every occurrence of the word under cursor
---------------------------------------------------------------------------
local cursorword_group = vim.api.nvim_create_augroup("Sp4ssCursorWord", { clear = true })
local cursorword = {
    match_id = nil,
    timer = (vim.uv or vim.loop).new_timer(),
    last_word = nil,
    debounce_ms = 80,
    min_len = 2,
    max_lines = 20000,
}

local function cursorword_hl()
    -- Soft background (not underline), readable on tokyonight transparent.
    vim.api.nvim_set_hl(0, "Sp4ssCursorWord", { bg = "#3b4261", default = false })
    -- Keep LSP reference highlights equally visible (Snacks.words).
    vim.api.nvim_set_hl(0, "LspReferenceText", { bg = "#3b4261", default = false })
    vim.api.nvim_set_hl(0, "LspReferenceRead", { bg = "#3b4261", default = false })
    vim.api.nvim_set_hl(0, "LspReferenceWrite", { bg = "#3d445c", default = false })
end

cursorword_hl()

local function cursorword_clear()
    if cursorword.match_id then
        pcall(vim.fn.matchdelete, cursorword.match_id)
        cursorword.match_id = nil
    end
    cursorword.last_word = nil
end

local function cursorword_update()
    local buf = vim.api.nvim_get_current_buf()
    if not vim.api.nvim_buf_is_valid(buf) then
        return
    end
    if vim.bo[buf].buftype ~= "" then
        cursorword_clear()
        return
    end
    if vim.api.nvim_buf_line_count(buf) > cursorword.max_lines then
        cursorword_clear()
        return
    end

    local word = vim.fn.expand("<cword>")
    if word == "" or #word < cursorword.min_len or not word:match("^[%w_]+$") then
        cursorword_clear()
        return
    end
    if word == cursorword.last_word and cursorword.match_id then
        return
    end

    cursorword_clear()
    -- Whole-file same-token highlight (word boundaries).
    local pat = "\\<" .. vim.fn.escape(word, "\\/.*$^~[]") .. "\\>"
    local ok, id = pcall(vim.fn.matchadd, "Sp4ssCursorWord", pat, -1)
    if ok then
        cursorword.match_id = id
        cursorword.last_word = word
    end
end

local function cursorword_schedule()
    cursorword.timer:stop()
    cursorword.timer:start(cursorword.debounce_ms, 0, vim.schedule_wrap(cursorword_update))
end

vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "WinEnter", "BufEnter" }, {
    group = cursorword_group,
    callback = cursorword_schedule,
})

vim.api.nvim_create_autocmd({ "WinLeave", "BufLeave" }, {
    group = cursorword_group,
    callback = function()
        cursorword.timer:stop()
        cursorword_clear()
    end,
})

-- Re-apply after colorscheme reloads (tokyonight / rose-pine).
vim.api.nvim_create_autocmd("ColorScheme", {
    group = cursorword_group,
    callback = cursorword_hl,
})
