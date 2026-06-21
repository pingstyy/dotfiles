vim.g.mapleader = " "

vim.keymap.set("n", "<leader>e", vim.cmd.Ex)

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
    vim.cmd.edit(vim.fn.fnameescape(vim.fn.stdpath("config") .. "/lua/sp4ss/cheats.txt"))
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
vim.keymap.set("n", "<leader>wq", function() safe_quit_all(true) end)
vim.keymap.set("n", "<leader>uu", function() safe_quit_all(true) end)
vim.keymap.set("n", "<leader>rq", function() safe_quit_all(false) end)
vim.keymap.set("n", "<leader>qa", function() safe_quit_all(false) end)
vim.keymap.set("n", "<leader>we", ":w | Ex<CR> ")

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
vim.keymap.set("v", "<leader>f", function()
    vim.lsp.buf.format({ range = true })
end, { desc = "Format selection" })


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

-- Mouse Menu
vim.opt.mouse = 'a'
