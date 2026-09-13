-- Run current file in a side toggleterm pane; keep focus in the editor.
-- DIR: "vertical" = right split (~30% cols). "horizontal" = full-width bottom bar.
local M = {}

local DIR = "vertical"
local function runner_size()
    if DIR == "horizontal" then
        return 12
    end
    return math.max(28, math.floor(vim.o.columns * 0.30))
end

local last_cmd = nil
local last_dir = nil
local runner_term = nil

-- Auto-close: armed after a run, then first editor activity hides the pane.
local close_armed = false
local close_grp = vim.api.nvim_create_augroup("sp4ss_runner_autoclose", { clear = true })
local setup_done = false

local function shellescape(s)
    return vim.fn.shellescape(s)
end

local function find_up(start_dir, names)
    local found = vim.fs.find(names, {
        path = start_dir,
        upward = true,
        type = "file",
        limit = 1,
    })
    if found[1] then
        return vim.fs.dirname(found[1]), found[1]
    end
    return nil, nil
end

--- Build a shell command for the buffer. Returns cmd, cwd or nil, err.
function M.resolve_cmd(bufnr)
    bufnr = bufnr or 0
    local file = vim.api.nvim_buf_get_name(bufnr)
    if file == "" then
        return nil, nil, "Buffer has no file on disk"
    end
    if vim.bo[bufnr].buftype ~= "" then
        return nil, nil, "Not a normal file buffer"
    end

    local path = vim.fn.fnamemodify(file, ":p")
    local dir = vim.fn.fnamemodify(file, ":p:h")
    local name = vim.fn.fnamemodify(file, ":t")
    local ft = vim.bo[bufnr].filetype

    if ft == "python" then
        local py = require("sp4ss.python_env").resolve() or "python3"
        return string.format("cd %s && %s %s", shellescape(dir), shellescape(py), shellescape(path)), dir
    end

    if ft == "go" then
        local root = find_up(dir, { "go.mod" })
        if root then
            return string.format("cd %s && go run .", shellescape(root)), root
        end
        return string.format("cd %s && go run %s", shellescape(dir), shellescape(name)), dir
    end

    if ft == "rust" then
        local root = find_up(dir, { "Cargo.toml" })
        if root then
            return string.format("cd %s && cargo run", shellescape(root)), root
        end
        local bin = vim.fn.fnamemodify(name, ":r")
        return string.format(
            "cd %s && rustc %s -o %s && ./%s",
            shellescape(dir),
            shellescape(name),
            shellescape(bin),
            shellescape(bin)
        ), dir
    end

    if ft == "javascript" or ft == "typescript" or ft == "javascriptreact" or ft == "typescriptreact" then
        local root = find_up(dir, { "package.json" })
        if root and ft:match("typescript") then
            -- Prefer tsx/ts-node if present; else node on .js transpile is user land.
            if vim.fn.executable("tsx") == 1 then
                return string.format("cd %s && tsx %s", shellescape(dir), shellescape(path)), dir
            end
            if vim.fn.executable("ts-node") == 1 then
                return string.format("cd %s && ts-node %s", shellescape(dir), shellescape(path)), dir
            end
        end
        return string.format("cd %s && node %s", shellescape(dir), shellescape(path)), dir
    end

    if ft == "lua" then
        return string.format("cd %s && nvim -l %s", shellescape(dir), shellescape(path)), dir
    end

    if ft == "sh" or ft == "bash" or ft == "zsh" then
        local shell = (ft == "zsh" and "zsh") or (ft == "bash" and "bash") or "bash"
        return string.format("cd %s && %s %s", shellescape(dir), shell, shellescape(path)), dir
    end

    if ft == "c" then
        local bin = vim.fn.fnamemodify(name, ":r")
        return string.format(
            "cd %s && cc %s -o %s && ./%s",
            shellescape(dir),
            shellescape(name),
            shellescape(bin),
            shellescape(bin)
        ), dir
    end

    if ft == "cpp" or ft == "cxx" then
        local bin = vim.fn.fnamemodify(name, ":r")
        return string.format(
            "cd %s && c++ %s -o %s && ./%s",
            shellescape(dir),
            shellescape(name),
            shellescape(bin),
            shellescape(bin)
        ), dir
    end

    if ft == "java" then
        local bin = vim.fn.fnamemodify(name, ":r")
        return string.format(
            "cd %s && javac %s && java %s",
            shellescape(dir),
            shellescape(name),
            shellescape(bin)
        ), dir
    end

    if ft == "julia" then
        return string.format("cd %s && julia %s", shellescape(dir), shellescape(path)), dir
    end

    if ft == "zig" then
        local root = find_up(dir, { "build.zig" })
        if root then
            return string.format("cd %s && zig build run", shellescape(root)), root
        end
        return string.format("cd %s && zig run %s", shellescape(dir), shellescape(path)), dir
    end

    if ft == "haskell" then
        return string.format("cd %s && runhaskell %s", shellescape(dir), shellescape(path)), dir
    end

    if ft == "elixir" then
        return string.format("cd %s && elixir %s", shellescape(dir), shellescape(path)), dir
    end

    return nil, nil, "No run command for filetype: " .. (ft ~= "" and ft or "(none)")
end

--- Project root (git) or cwd. Pipeline is per-root.
local function project_root(bufnr)
    bufnr = bufnr or 0
    local file = vim.api.nvim_buf_get_name(bufnr)
    local start = file ~= "" and vim.fn.fnamemodify(file, ":p:h") or vim.fn.getcwd()
    local git = vim.fs.find(".git", { path = start, upward = true, limit = 1 })
    if git[1] then
        return vim.fs.dirname(git[1])
    end
    return start
end

local function pipeline_path(bufnr)
    local root = project_root(bufnr)
    local dir = vim.fn.stdpath("data") .. "/sp4ss/run"
    vim.fn.mkdir(dir, "p")
    return dir .. "/" .. vim.fn.sha256(root):sub(1, 16) .. ".sh", root
end

local function parse_steps(path)
    if vim.fn.filereadable(path) == 0 then
        return {}
    end
    local steps = {}
    for _, line in ipairs(vim.fn.readfile(path)) do
        local s = vim.trim(line)
        if s ~= "" and not s:match("^#") then
            table.insert(steps, s)
        end
    end
    return steps
end

function M.steps(bufnr)
    local path, root = pipeline_path(bufnr)
    return parse_steps(path), path, root
end

local function runner_win()
    if runner_term and runner_term.window and vim.api.nvim_win_is_valid(runner_term.window) then
        return runner_term.window
    end
    return nil
end

local function disarm_autoclose()
    close_armed = false
    vim.api.nvim_clear_autocmds({ group = close_grp })
end

local function close_output_pane()
    if not close_armed then
        return
    end
    local term = runner_term
    if not term or not term:is_open() then
        disarm_autoclose()
        return
    end
    local cur = vim.api.nvim_get_current_win()
    if runner_win() and cur == runner_win() then
        return
    end
    disarm_autoclose()
    pcall(function()
        term:close()
    end)
end

--- Hide output on the next real action in any non-runner pane.
local function arm_autoclose()
    disarm_autoclose()
    vim.defer_fn(function()
        if not runner_term or not runner_term:is_open() then
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
                vim.schedule(close_output_pane)
            end,
        })
    end, 250)
end

local function ensure_toggleterm()
    local ok = pcall(require, "toggleterm")
    if not ok then
        return false
    end
    return true
end

local function get_runner()
    if runner_term then
        return runner_term
    end
    local Terminal = require("toggleterm.terminal").Terminal
    runner_term = Terminal:new({
        id = 99,
        display_name = "runner",
        direction = DIR,
        close_on_exit = false,
        hidden = true,
        -- Stay out of insert/terminal-mode when opening for runs.
        on_open = function()
            vim.cmd("stopinsert")
        end,
    })
    return runner_term
end

--- Open runner pane if needed, send cmd, leave focus on the editor.
function M.send(cmd, dir)
    if not ensure_toggleterm() then
        vim.notify("toggleterm.nvim not available", vim.log.levels.ERROR)
        return
    end

    last_cmd = cmd
    last_dir = dir

    local editor_win = vim.api.nvim_get_current_win()
    local term = get_runner()

    if dir and dir ~= "" then
        term.dir = dir
    end

    if not term:is_open() then
        term:open(runner_size(), DIR)
    end

    -- go_back=true: if send focused the term, return to previous window.
    -- (go_back=false actually *focuses* the term when you are not in it.)
    term:send(cmd, true)

    if vim.api.nvim_win_is_valid(editor_win) then
        vim.api.nvim_set_current_win(editor_win)
    end
    vim.cmd("stopinsert")
    arm_autoclose()
end

local function save_if_needed(bufnr)
    if vim.bo[bufnr].modified then
        local ok, err = pcall(function()
            vim.cmd("write")
        end)
        if not ok then
            vim.notify("Save failed: " .. tostring(err), vim.log.levels.ERROR)
            return false
        end
    end
    return true
end

function M.run_buffer(bufnr)
    bufnr = bufnr or 0
    if not save_if_needed(bufnr) then
        return
    end

    local cmd, dir, err = M.resolve_cmd(bufnr)
    if not cmd then
        vim.notify(err or "Cannot run buffer", vim.log.levels.WARN)
        return
    end
    M.send(cmd, dir)
end

--- Space rr: pipeline if this project has steps, else current-file run.
function M.run(bufnr)
    bufnr = bufnr or 0
    local steps, _, root = M.steps(bufnr)
    if #steps == 0 then
        return M.run_buffer(bufnr)
    end
    if not save_if_needed(bufnr) then
        return
    end
    vim.notify(string.format("run %d steps", #steps), vim.log.levels.INFO)
    -- cd root first so a later `cd build` step is relative to the project, even
    -- if the hidden shell was left in another directory.
    M.send("cd " .. shellescape(root) .. " && " .. table.concat(steps, " && "), root)
end

function M.edit(bufnr)
    local path, root = pipeline_path(bufnr)
    if vim.fn.filereadable(path) == 0 then
        vim.fn.writefile({
            "# sequential run  |  " .. root,
            "# one command per line. Space rr joins them with &&  (fail stops rest)",
            "# blank lines and # comments skipped. delete a line = remove that step.",
            "# :w save, then Space rr",
            "",
        }, path)
    end
    vim.cmd.edit(vim.fn.fnameescape(path))
end

function M.add(bufnr)
    local path, root = pipeline_path(bufnr)
    vim.ui.input({ prompt = "Run step: " }, function(text)
        if not text or vim.trim(text) == "" then
            return
        end
        local line = vim.trim(text)
        if vim.fn.filereadable(path) == 0 then
            vim.fn.writefile({
                "# sequential run  |  " .. root,
                line,
            }, path)
        else
            vim.fn.writefile({ line }, path, "a")
        end
        local n = #parse_steps(path)
        vim.notify(string.format("step added (%d total). Space rr runs them.", n))
    end)
end

function M.run_last()
    if not last_cmd then
        vim.notify("No previous run command", vim.log.levels.WARN)
        return
    end
    M.send(last_cmd, last_dir)
end

function M.toggle()
    if not ensure_toggleterm() then
        vim.notify("toggleterm.nvim not available", vim.log.levels.ERROR)
        return
    end
    local editor_win = vim.api.nvim_get_current_win()
    local term = get_runner()
    term:toggle(runner_size(), DIR)
    -- If we just opened it, still return to editor so "peek" doesn't steal focus.
    if term:is_open() and vim.api.nvim_win_is_valid(editor_win) then
        -- When closing, is_open is false — only restore if still open (opened by toggle).
        vim.schedule(function()
            if term:is_open() and vim.api.nvim_win_is_valid(editor_win) then
                vim.api.nvim_set_current_win(editor_win)
                vim.cmd("stopinsert")
                arm_autoclose()
            else
                disarm_autoclose()
            end
        end)
    else
        disarm_autoclose()
    end
end

function M.setup()
    if setup_done then
        return
    end
    setup_done = true
    vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("sp4ss_runner_pipeline", { clear = true }),
        pattern = "*/sp4ss/run/*",
        callback = function(ev)
            local n = #parse_steps(ev.file)
            vim.notify(string.format("%d run steps saved  (Space rr)", n))
        end,
    })
end

return M
