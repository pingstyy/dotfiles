-- Interactive REPL (ipython/python in the resolved env).
-- Pane auto-hides on any activity outside it, same idea as the file runner.

local close_armed = false
local close_grp = vim.api.nvim_create_augroup("sp4ss_iron_autoclose", { clear = true })

local function iron_win()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.b[buf].sp4ss_iron then
            return win
        end
    end
    return nil
end

local function mark_iron_bufs()
    local ok, ll = pcall(require, "iron.lowlevel")
    if not ok or not ll.get_repl_ft_for_bufnr then
        return
    end
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and ll.get_repl_ft_for_bufnr(buf) then
            vim.b[buf].sp4ss_iron = true
        end
    end
end

local function disarm()
    close_armed = false
    vim.api.nvim_clear_autocmds({ group = close_grp })
end

local function hide_iron()
    if not close_armed then
        return
    end
    local cur = vim.api.nvim_get_current_win()
    local win = iron_win()
    if win and cur == win then
        return
    end
    disarm()
    pcall(function()
        require("iron.core").hide_repl()
    end)
    win = iron_win()
    if win and vim.api.nvim_win_is_valid(win) then
        pcall(vim.api.nvim_win_hide, win)
    end
end

local function arm()
    disarm()
    vim.defer_fn(function()
        mark_iron_bufs()
        if not iron_win() then
            return
        end
        close_armed = true
        vim.api.nvim_create_autocmd({
            "InsertEnter",
            "CmdlineEnter",
            "CursorMoved",
            "TextChanged",
            "WinEnter",
            "ModeChanged",
        }, {
            group = close_grp,
            callback = function()
                vim.schedule(hide_iron)
            end,
        })
    end, 250)
end

local function python_cmd()
    local env = require("sp4ss.python_env")
    local py = env.resolve() or "python3"
    -- Re-apply so nvim PATH/tmux stay on this env even if shell was base.
    pcall(env.apply, py)
    -- Module form: THIS python's IPython, never a random ipython on PATH.
    local chk = vim.fn.system({ py, "-c", "import IPython" })
    if vim.v.shell_error == 0 then
        return { py, "-m", "IPython", "--no-autoindent" }
    end
    return { py }
end

return {
    "Vigemus/iron.nvim",
    main = "iron.core",
    event = "VeryLazy",
    config = function()
        local iron = require("iron.core")
        local view = require("iron.view")
        local common = require("iron.fts.common")

        iron.setup({
            config = {
                scratch_repl = true,
                close_window_on_exit = false,
                repl_definition = {
                    python = {
                        command = python_cmd,
                        format = common.bracketed_paste,
                        block_dividers = { "# %%", "#%%" },
                    },
                    sh = { command = { vim.o.shell } },
                },
                repl_open_cmd = view.split.vertical.botright(function()
                    return math.max(28, math.floor(vim.o.columns * 0.30))
                end),
            },
            keymaps = {
                send_motion = "<leader>ic",
                visual_send = "<leader>ic",
                send_file = "<leader>if",
                send_line = "<leader>il",
                send_paragraph = "<leader>ip",
                send_code_block = "<leader>ib",
                cr = "<leader>i<CR>",
                interrupt = "<leader>ix",
                exit = "<leader>iq",
                clear = "<leader>iC",
            },
            highlight = { italic = true },
            ignore_blank_lines = true,
        })

        vim.api.nvim_create_autocmd({ "TermOpen", "BufWinEnter" }, {
            group = vim.api.nvim_create_augroup("sp4ss_iron_mark", { clear = true }),
            callback = function(ev)
                vim.schedule(function()
                    local ok, ll = pcall(require, "iron.lowlevel")
                    if ok and ll.get_repl_ft_for_bufnr and ll.get_repl_ft_for_bufnr(ev.buf) then
                        vim.b[ev.buf].sp4ss_iron = true
                        arm()
                    elseif vim.b[ev.buf].sp4ss_iron then
                        arm()
                    end
                end)
            end,
        })

        local function repl_and_arm()
            vim.cmd("IronRepl")
            vim.schedule(arm)
        end

        vim.keymap.set("n", "<leader>ii", repl_and_arm, { desc = "Iron: toggle REPL (current env)" })
        vim.keymap.set("n", "<leader>iR", function()
            vim.cmd("IronRestart")
            vim.schedule(arm)
        end, { desc = "Iron: restart REPL (current env)" })
        vim.keymap.set("n", "<leader>ih", function()
            disarm()
            vim.cmd("IronHide")
        end, { desc = "Iron: hide REPL" })
        vim.keymap.set("n", "<leader>iF", function()
            vim.cmd("IronFocus")
        end, { desc = "Iron: focus REPL" })
    end,
}
