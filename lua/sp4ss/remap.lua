vim.g.mapleader = " "

-- File explorer is Snacks (<leader>e in snacks.lua). Do not map Ex/netrw here.

local function current_dir()
    local file_dir = vim.fn.expand("%:p:h")

    if file_dir ~= "" and vim.fn.isdirectory(file_dir) == 1 then
        return file_dir
    end

    return vim.fn.getcwd()
end

local function copy_to_clipboard(text, label)
    vim.fn.setreg("+", text)
    vim.fn.setreg('"', text)
    vim.notify(label .. ": " .. text)
end

vim.api.nvim_create_user_command("CopyAbsPath", function()
    copy_to_clipboard(vim.fn.expand("%:p"), "Copied absolute path")
end, {})

vim.api.nvim_create_user_command("CopyRelPath", function()
    copy_to_clipboard(vim.fn.expand("%:."), "Copied relative path")
end, {})

vim.api.nvim_create_user_command("CopyCwd", function()
    copy_to_clipboard(vim.fn.getcwd(), "Copied working directory")
end, {})

vim.api.nvim_create_user_command("Cheat", function()
    local prev = vim.api.nvim_get_current_buf()
    vim.cmd.edit(vim.fn.fnameescape(vim.fn.stdpath("config") .. "/lua/sp4ss/cheats.txt"))
    vim.b.sp4ss_cheat_prev = prev
    vim.keymap.set("n", "q", function()
        local p = vim.b.sp4ss_cheat_prev
        if p and vim.api.nvim_buf_is_valid(p) and p ~= vim.api.nvim_get_current_buf() then
            vim.cmd.buffer(p)
        else
            local alt = vim.fn.bufnr("#")
            if alt > 0 and vim.api.nvim_buf_is_valid(alt) then
                vim.cmd.buffer(alt)
            else
                vim.cmd.bdelete()
            end
        end
    end, { buffer = true, desc = "Back from cheatsheet" })
end, {})

vim.api.nvim_create_user_command("Registers", function()
    require("telescope.builtin").registers()
end, {})

vim.api.nvim_create_user_command("SnippetEdit", function(opts)
    require("sp4ss.snippets").edit(opts.args)
end, { nargs = "?" })

vim.api.nvim_create_user_command("SnippetPackage", function()
    require("sp4ss.snippets").package()
end, {})

vim.api.nvim_create_user_command("SnippetCheck", function(opts)
    require("sp4ss.snippets").check(opts.args)
end, { nargs = "?" })

vim.cmd([[cnoreabbrev <expr> cheat getcmdtype() == ':' && getcmdline() ==# 'cheat' ? 'Cheat' : 'cheat']])
vim.cmd([[cnoreabbrev <expr> registers getcmdtype() == ':' && getcmdline() ==# 'registers' ? 'Registers' : 'registers']])

local function toggleterm_current_dir()
    vim.cmd("ToggleTerm dir=" .. vim.fn.fnameescape(current_dir()))
end

local function running_terminal_buffers()
    local terminals = {}

    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buftype == "terminal" then
            local job_id = vim.b[bufnr].terminal_job_id

            if job_id and vim.fn.jobwait({ job_id }, 0)[1] == -1 then
                local name = vim.api.nvim_buf_get_name(bufnr)

                table.insert(terminals, {
                    bufnr = bufnr,
                    name = name ~= "" and name or ("terminal buffer " .. bufnr),
                })
            end
        end
    end

    return terminals
end

local function safe_quit_all(write_first)
    local terminals = running_terminal_buffers()

    if #terminals > 0 then
        local lines = { "Quit cancelled: terminal jobs are still running." }

        for _, terminal in ipairs(terminals) do
            table.insert(lines, string.format("  #%d %s", terminal.bufnr, terminal.name))
        end

        table.insert(lines, "Exit those jobs first, then quit again.")
        vim.notify(table.concat(lines, "\n"), vim.log.levels.WARN)
        vim.cmd("buffer " .. terminals[1].bufnr)
        return
    end

    if write_first then
        vim.cmd.wqa()
    else
        vim.cmd.qa()
    end
end

vim.keymap.set("n", "<leader>w", vim.cmd.w)
vim.keymap.set("n", "w", vim.cmd.w)
vim.keymap.set("n", "<leader>wq", function() safe_quit_all(true) end)
vim.keymap.set("n", "wq", function() safe_quit_all(true) end)
vim.keymap.set("n", "<leader>uu", function() safe_quit_all(true) end)
vim.keymap.set("n", "uu", function() safe_quit_all(true) end)
vim.keymap.set("n", "<leader>rq", function() safe_quit_all(false) end)
vim.keymap.set("n", "<leader>qa", function() safe_quit_all(false) end)
vim.keymap.set("n", "<leader>we", function()
    vim.cmd.w()
    local explorer = Snacks.picker.get({ source = "explorer" })[1]
    if explorer then
        explorer:focus()
    else
        Snacks.explorer()
    end
end, { desc = "Write and open file explorer" })

-- Comment toggle: Ctrl+/ works in most Mac terminals (often sent as <C-_>).
-- Cmd+/ (<D-/>) only reaches Neovim in GUI clients (e.g. Neovide).
-- Uses built-in gc/gcc (commentstring / filetype-aware).
for _, key in ipairs({ "<C-/>", "<C-_>", "<D-/>" }) do
    vim.keymap.set("n", key, "gcc", { remap = true, desc = "Toggle comment line" })
    vim.keymap.set("x", key, "gc", { remap = true, desc = "Toggle comment selection" })
end

---------------------------------------------------------------------------
-- VSCode-like editing (Cmd maps need Ghostty super-key passthrough; see cheats)
---------------------------------------------------------------------------

--- Feed keys so we stay in insert with correct autoindent (o/O).
local function feed(keys)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
end

--- New line BELOW with autoindent; always end in insert mode.
--- Uses `o` so smartindent / indentexpr / cindent all apply.
local function open_line_below()
    if vim.fn.mode():find("i", 1, true) then
        -- One normal-mode `o` from insert: indent + remain insert.
        feed("<C-o>o")
    else
        vim.cmd("normal! o")
    end
end

--- New line ABOVE with autoindent; always end in insert mode.
local function open_line_above()
    if vim.fn.mode():find("i", 1, true) then
        feed("<C-o>O")
    else
        vim.cmd("normal! O")
    end
end

-- Cmd/Opt/Ctrl+Enter: next line with indent, stay insert.
-- Never accepts blink completion (blink maps these to hide+fallback).
vim.keymap.set({ "n", "i" }, "<D-CR>", open_line_below, { desc = "Open line below (indent, stay insert)" })
vim.keymap.set({ "n", "i" }, "<M-CR>", open_line_below, { desc = "Open line below (indent, stay insert)" })
vim.keymap.set({ "n", "i" }, "<C-CR>", open_line_below, { desc = "Open line below (indent, stay insert)" })

-- Cmd+Shift+Enter: line above with indent, stay insert.
vim.keymap.set({ "n", "i" }, "<D-S-CR>", open_line_above, { desc = "Open line above (indent, stay insert)" })
vim.keymap.set({ "n", "i" }, "<M-S-CR>", open_line_above, { desc = "Open line above (indent, stay insert)" })
vim.keymap.set({ "n", "i" }, "<C-S-CR>", open_line_above, { desc = "Open line above (indent, stay insert)" })

-- Cmd+Shift+K: delete line (or visual lines).
vim.keymap.set("n", "<D-S-k>", "dd", { desc = "VSCode: delete line" })
vim.keymap.set("x", "<D-S-k>", ":delete<CR>", { desc = "VSCode: delete lines" })
vim.keymap.set("i", "<D-S-k>", "<C-o>dd", { desc = "VSCode: delete line" })

--- Duplicate current line below/above; move cursor to the new line, same column.
local function duplicate_line(direction)
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    local max_col = #line
    local new_col = math.min(col, max_col)
    if direction == "below" then
        vim.api.nvim_buf_set_lines(0, row, row, false, { line })
        vim.api.nvim_win_set_cursor(0, { row + 1, new_col })
    else
        vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, { line })
        -- New line is inserted at `row`; original shifts down.
        vim.api.nvim_win_set_cursor(0, { row, new_col })
    end
end

-- Option+Shift+j/k: clone line below / above (also works in visual).
-- Cursor stays on the same column of the newly created line (not column 0).
vim.keymap.set({ "n", "i" }, "<M-S-j>", function()
    duplicate_line("below")
end, { desc = "VSCode: duplicate line below (keep column)" })
vim.keymap.set({ "n", "i" }, "<M-S-k>", function()
    duplicate_line("above")
end, { desc = "VSCode: duplicate line above (keep column)" })
vim.keymap.set("x", "<M-S-j>", ":t'><CR>gv", { desc = "VSCode: duplicate selection below" })
vim.keymap.set("x", "<M-S-k>", ":t'<-1<CR>gv", { desc = "VSCode: duplicate selection above" })

-- Cmd+] / Cmd+[: indent / outdent (keep visual selection).
vim.keymap.set("n", "<D-]>", ">>", { desc = "VSCode: indent" })
vim.keymap.set("n", "<D-[>", "<<", { desc = "VSCode: outdent" })
vim.keymap.set("x", "<D-]>", ">gv", { desc = "VSCode: indent" })
vim.keymap.set("x", "<D-[>", "<gv", { desc = "VSCode: outdent" })
vim.keymap.set("i", "<D-]>", "<C-t>", { desc = "VSCode: indent" })
vim.keymap.set("i", "<D-[>", "<C-d>", { desc = "VSCode: outdent" })

-- Terminal-friendly mirrors (Cmd often missing): Ctrl+] / Ctrl+[ for indent
-- (Ctrl+[ is Esc in raw terminals — skip). Use Option+] / Option+[ instead.
vim.keymap.set("n", "<M-]>", ">>", { desc = "Indent line" })
vim.keymap.set("n", "<M-[>", "<<", { desc = "Outdent line" })
vim.keymap.set("x", "<M-]>", ">gv", { desc = "Indent selection" })
vim.keymap.set("x", "<M-[>", "<gv", { desc = "Outdent selection" })

-- Move selected lines up and down in Visual Mode
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
-- Keep cursor in the middle when jumping half-pages
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
-- Keep search terms in the middle
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
-- Copy to system clipboard (requires +clipboard support)
vim.keymap.set({ "n", "v" }, "<leader>c", [["+y]])
vim.keymap.set("n", "<leader>c", [["+Y]])
-- Paste without losing the current register
vim.keymap.set("x", "p", [["_dP]])
vim.keymap.set("x", "<leader>p", [["_dP]])

vim.keymap.set("n", "<leader>yp", "<cmd>CopyAbsPath<CR>", { desc = "Copy absolute file path" })
vim.keymap.set("n", "<leader>yr", "<cmd>CopyRelPath<CR>", { desc = "Copy relative file path" })
vim.keymap.set("n", "<leader>yc", "<cmd>CopyCwd<CR>", { desc = "Copy cwd" })
vim.keymap.set("n", "<leader>?", "<cmd>Cheat<CR>", { desc = "Open cheatsheet" })
vim.keymap.set("n", "<leader>xe", "<cmd>SnippetEdit<CR>", { desc = "Edit snippets for filetype" })
vim.keymap.set("n", "<leader>xE", "<cmd>SnippetPackage<CR>", { desc = "Edit snippet package" })


-- Telescope Remaps
-- Cheatsheet Mappings (Space + f + ...)
vim.keymap.set('n', '<leader>ff', function() require('telescope.builtin').find_files() end)
vim.keymap.set('n', '<leader>fg', function() require('telescope.builtin').live_grep() end)
vim.keymap.set('n', '<leader>fb', function() require('telescope.builtin').buffers() end)
vim.keymap.set('n', '<leader>fh', function() require('telescope.builtin').help_tags() end)
vim.keymap.set('n', '<leader>sr', function() require('telescope.builtin').registers() end, { desc = "Registers" })

-- Project Remaps (Primeagen style)
vim.keymap.set('n', '<leader>pf', function() require('telescope.builtin').find_files() end)
vim.keymap.set('n', '<C-p>', function() require('telescope.builtin').git_files() end)
vim.keymap.set('n', '<leader>ps',
    function() require('telescope.builtin').grep_string({ search = vim.fn.input("Grep > ") }) end)



-- Harpoon (Safe & Compact)
vim.keymap.set("n", "<leader>ha", function() require("harpoon"):list():add() end)
vim.keymap.set("n", "<leader>he", function()
    local h = require("harpoon")
    h.ui:toggle_quick_menu(h:list())
end)

-- Toggle harpoon file selections using <leader>1, <leader>2, etc. (Conflict-free & Safe)
vim.keymap.set("n", "<leader>1", function() require("harpoon"):list():select(1) end)
vim.keymap.set("n", "<leader>2", function() require("harpoon"):list():select(2) end)
vim.keymap.set("n", "<leader>3", function() require("harpoon"):list():select(3) end)
vim.keymap.set("n", "<leader>4", function() require("harpoon"):list():select(4) end)

-- Optional Control-key maps (Note: <C-h> conflicts with split navigation, <C-s> can freeze terminals)
vim.keymap.set("n", "<C-y>", function() require("harpoon"):list():select(1) end) -- alternative to avoid <C-h> conflict
vim.keymap.set("n", "<C-t>", function() require("harpoon"):list():select(2) end)
vim.keymap.set("n", "<C-n>", function() require("harpoon"):list():select(3) end)



-- LSP
vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end)
vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end)
vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end)
vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end)
vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end)
vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end)
vim.keymap.set("n", "<leader>vrn", function() vim.lsp.buf.rename() end)
vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end)
vim.keymap.set("x", "<leader>f", function()
    -- Visual mode: conform formats the selection only (not the whole buffer).
    require("conform").format({ async = false, lsp_fallback = true, timeout_ms = 500 })
end, { desc = "Format selection" })







-- Others
vim.keymap.set({ "n", "o", "v" }, "0", "0", { desc = "Start of line" })
vim.keymap.set({ "n", "o", "v" }, "9", "$", { desc = "End of line" })
vim.keymap.set({ "n", "o", "v" }, "G", "G", { desc = "End of file" })

-- TreeSitter



-- UndoTree Toggle
vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)

-- Git Status (The main Fugitive command)
vim.keymap.set("n", "<leader>gs", vim.cmd.Git)


-- Window Navigation
vim.keymap.set('n', '<C-h>', '<C-w>h')
vim.keymap.set('n', '<C-j>', '<C-w>j')
vim.keymap.set('n', '<C-k>', '<C-w>k')
vim.keymap.set('n', '<C-l>', '<C-w>l')

-- Quickfix Navigation
vim.keymap.set("n", "<leader>cn", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<leader>cp", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>co", "<cmd>copen<CR>")

-- Terminal Escape
vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]])
vim.keymap.set("n", "<leader>tt", function()
    toggleterm_current_dir()
end, { desc = "Toggle terminal in current file directory" })
vim.keymap.set("n", "tt", function()
    toggleterm_current_dir()
end, { desc = "Toggle terminal in current file directory (no leader)" })

-- Run: pipeline (if steps set) else current file. Pane auto-hides on next editor action.
vim.keymap.set("n", "<leader>rr", function()
    require("sp4ss.runner").run()
end, { desc = "Run pipeline or current file" })
vim.keymap.set("n", "<leader>rl", function()
    require("sp4ss.runner").run_last()
end, { desc = "Re-run last command" })
vim.keymap.set("n", "<leader>rt", function()
    require("sp4ss.runner").toggle()
end, { desc = "Toggle run/output pane" })
vim.keymap.set("n", "<leader>re", function()
    require("sp4ss.runner").edit()
end, { desc = "Edit sequential run steps" })
vim.keymap.set("n", "<leader>ra", function()
    require("sp4ss.runner").add()
end, { desc = "Add a sequential run step" })

-- Mouse Menu
vim.opt.mouse = 'a'

---------------------------------------------------------------------------
-- VS Code-ish word motion: `vw` on last token after `.` stays on this line
-- Default Vim `w` jumps to the first word of the *next* line at EOL.
---------------------------------------------------------------------------
local function smart_word_motion(big)
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    -- Next word/WORD *start* after the cursor (W = no wrap around file).
    local pat = big and [[\(^\|\s\)\zs\S]] or [[\<\k]]
    local pos = vim.fn.searchpos(pat, "Wn")
    if pos[1] ~= 0 and pos[1] == row then
        return big and "W" or "w"
    end

    -- Last token on this line: move to its end, never the next line.
    -- If already on the last non-blank char, stay put (empty motion).
    local last_col = line:find("%S%s*$") -- 1-based index of last non-blank
    if not last_col then
        return ""
    end
    -- nvim col is 0-based; stay if cursor is already at/after last non-blank.
    if col + 1 >= last_col then
        return ""
    end
    return big and "E" or "e"
end

vim.keymap.set({ "x", "o" }, "w", function()
    return smart_word_motion(false)
end, { expr = true, desc = "word forward (no next-line jump)" })

vim.keymap.set({ "x", "o" }, "W", function()
    return smart_word_motion(true)
end, { expr = true, desc = "WORD forward (no next-line jump)" })

