-- Resolve conda/venv/system Python for LSP + runner + iron + tmux panes.
local M = {}

local persist_path = vim.fn.stdpath("data") .. "/sp4ss/last_python.env"

local function executable(path)
    return type(path) == "string" and path ~= "" and vim.fn.executable(path) == 1
end

local function name_from_prefix(prefix)
    local name = vim.fn.fnamemodify(prefix, ":t")
    if prefix:match("miniconda3$") or prefix:match("anaconda3$") or name == "miniconda3" or name == "anaconda3" then
        return "base"
    end
    return name
end

local function kind_from_prefix(prefix)
    if prefix:match("/envs/") or prefix:match("miniconda3$") or prefix:match("anaconda3$") or prefix:match("/miniconda3/") then
        return "conda"
    end
    return "venv"
end

function M.info_from_python(py)
    if not executable(py) then
        return nil
    end
    local bin = vim.fn.fnamemodify(py, ":h")
    local prefix = vim.fn.fnamemodify(bin, ":h")
    return {
        path = py,
        prefix = prefix,
        bin = bin,
        name = name_from_prefix(prefix),
        kind = kind_from_prefix(prefix),
    }
end

function M.read_persist()
    local fd = io.open(persist_path, "r")
    if not fd then
        return nil
    end
    local data = fd:read("*a")
    fd:close()
    local info = {}
    for line in data:gmatch("[^\n]+") do
        local k, v = line:match("^([%w_]+)=(.*)$")
        if k then
            info[k] = v
        end
    end
    if executable(info.path) then
        return info
    end
    return nil
end

function M.persist(info)
    if not info or not info.path then
        return
    end
    vim.fn.mkdir(vim.fn.fnamemodify(persist_path, ":h"), "p")
    local fd = io.open(persist_path, "w")
    if not fd then
        return
    end
    fd:write(string.format(
        "kind=%s\nname=%s\nprefix=%s\npath=%s\n",
        info.kind or "conda",
        info.name or "",
        info.prefix or "",
        info.path
    ))
    fd:close()
end

function M.push_path(bin)
    if not bin or bin == "" then
        return
    end
    local path = vim.env.PATH or ""
    if path:sub(1, #bin + 1) == bin .. ":" then
        return
    end
    path = path:gsub(vim.pesc(bin) .. ":?", "")
    vim.env.PATH = bin .. ":" .. path
end

function M.sync_tmux(info)
    if not info or vim.env.TMUX == nil or vim.env.TMUX == "" then
        return
    end
    if vim.fn.executable("tmux") ~= 1 then
        return
    end
    local function setenv(k, v)
        if v and v ~= "" then
            vim.fn.system({ "tmux", "set-environment", "-g", k, v })
        end
    end
    setenv("CONDA_PREFIX", info.kind == "conda" and info.prefix or "")
    setenv("CONDA_DEFAULT_ENV", info.kind == "conda" and info.name or "")
    setenv("CONDA_PROMPT_MODIFIER", info.kind == "conda" and ("(" .. (info.name or "") .. ") ") or "")
    setenv("CONDA_PYTHON_EXE", info.path or "")
    setenv("CONDA_SHLVL", info.kind == "conda" and "1" or "0")
    setenv("VIRTUAL_ENV", info.kind == "venv" and info.prefix or "")
    setenv("SP4SS_PY_NAME", info.name or "")
    setenv("SP4SS_PY_PREFIX", info.prefix or "")
    setenv("SP4SS_PY_KIND", info.kind or "")
    -- New tmux panes copy session PATH *before* zsh conda hook; still prepend so
    -- a pane that skips the hook has the right python.
    if info.bin and info.bin ~= "" then
        local path = vim.env.PATH or ""
        if path:sub(1, #info.bin + 1) ~= info.bin .. ":" then
            path = info.bin .. ":" .. path
        end
        setenv("PATH", path)
    end
end

--- Make this python the session env (PATH, persist, tmux).
function M.apply(py)
    local info = M.info_from_python(py)
    if not info then
        return nil
    end
    vim.g.python_env_path = info.path
    M.push_path(info.bin)
    if info.kind == "conda" then
        vim.env.CONDA_PREFIX = info.prefix
        vim.env.CONDA_DEFAULT_ENV = info.name
        vim.env.VIRTUAL_ENV = nil
    else
        vim.env.VIRTUAL_ENV = info.prefix
    end
    M.persist(info)
    M.sync_tmux(info)
    return info
end

function M.list_conda()
    local out = {}
    local conda = vim.fn.exepath("conda")
    if conda == "" then
        return out
    end
    local ok, result = pcall(vim.fn.systemlist, { conda, "env", "list", "--json" })
    if not ok or vim.v.shell_error ~= 0 then
        return out
    end
    local decoded = vim.fn.json_decode(table.concat(result, "\n"))
    if type(decoded) ~= "table" or type(decoded.envs) ~= "table" then
        return out
    end
    for _, prefix in ipairs(decoded.envs) do
        local py = prefix .. "/bin/python"
        if executable(py) then
            table.insert(out, {
                name = name_from_prefix(prefix),
                path = py,
                prefix = prefix,
                kind = "conda",
            })
        end
    end
    return out
end

--- Best Python: pick → current conda/venv → last persist → project venv → PATH.
function M.resolve()
    local override = vim.g.python_env_path
    if executable(override) then
        return override
    end

    local conda_prefix = vim.env.CONDA_PREFIX
    if type(conda_prefix) == "string" and conda_prefix ~= "" then
        local py = conda_prefix .. "/bin/python"
        if executable(py) then
            return py
        end
    end

    local venv = vim.env.VIRTUAL_ENV
    if type(venv) == "string" and venv ~= "" then
        local py = venv .. "/bin/python"
        if executable(py) then
            return py
        end
    end

    local last = M.read_persist()
    if last and executable(last.path) then
        return last.path
    end

    local cwd = vim.fn.getcwd()
    for _, rel in ipairs({ ".venv/bin/python", "venv/bin/python", ".conda/bin/python" }) do
        local py = cwd .. "/" .. rel
        if executable(py) then
            return py
        end
    end

    local py3 = vim.fn.exepath("python3")
    if py3 ~= "" then
        return py3
    end
    local py = vim.fn.exepath("python")
    if py ~= "" then
        return py
    end
    return nil
end

function M.ipython()
    local py = M.resolve()
    if not py then
        return nil
    end
    local ipy = vim.fn.fnamemodify(py, ":h") .. "/ipython"
    if executable(ipy) then
        return ipy
    end
    local path_ipy = vim.fn.exepath("ipython")
    if path_ipy ~= "" then
        return path_ipy
    end
    return nil
end

local function restart_pyright()
    local clients = vim.lsp.get_clients({ name = "pyright" })
    for _, client in ipairs(clients) do
        client.stop(true)
    end
    vim.defer_fn(function()
        if vim.bo.filetype == "python" then
            vim.cmd("edit")
        end
        vim.notify("pyright restarted with: " .. (vim.g.python_env_path or M.resolve() or "default"), vim.log.levels.INFO)
    end, 100)
end

local function is_named_env(info)
    return info and info.name and info.name ~= "" and info.name ~= "base"
end

function M.setup()
    -- Named env in this shell (modal-env, not base) wins and is remembered.
    -- Else last persist (so opening nvim from base does NOT wipe modal-env).
    local current
    if executable((vim.env.CONDA_PREFIX or "") .. "/bin/python") then
        current = M.info_from_python(vim.env.CONDA_PREFIX .. "/bin/python")
    elseif executable((vim.env.VIRTUAL_ENV or "") .. "/bin/python") then
        current = M.info_from_python(vim.env.VIRTUAL_ENV .. "/bin/python")
    end
    local last = M.read_persist()
    if is_named_env(current) then
        M.apply(current.path)
    elseif last then
        M.apply(last.path)
    elseif current then
        M.apply(current.path)
    else
        local py = M.resolve()
        if py then
            M.apply(py)
        end
    end

    vim.api.nvim_create_user_command("PythonSelectEnv", function()
        local envs = M.list_conda()
        local cwd = vim.fn.getcwd()
        for _, rel in ipairs({ ".venv/bin/python", "venv/bin/python" }) do
            local py = cwd .. "/" .. rel
            if executable(py) then
                table.insert(envs, 1, {
                    name = "project:" .. rel,
                    path = py,
                    prefix = vim.fn.fnamemodify(py, ":h:h"),
                    kind = "venv",
                })
            end
        end
        if #envs == 0 then
            vim.notify("No conda/venv pythons found", vim.log.levels.WARN)
            return
        end
        local labels = {}
        for i, e in ipairs(envs) do
            labels[i] = string.format("%s  (%s)", e.name, e.path)
        end
        vim.ui.select(labels, { prompt = "Python env (pyright + runner + iron + tmux):" }, function(choice, idx)
            if not choice or not idx then
                return
            end
            M.apply(envs[idx].path)
            restart_pyright()
        end)
    end, { desc = "Pick conda/venv Python for pyright + runner + iron + tmux" })

    vim.api.nvim_create_user_command("PythonShowEnv", function()
        local py = M.resolve()
        local info = py and M.info_from_python(py)
        if not info then
            vim.notify("python: (none)", vim.log.levels.INFO)
            return
        end
        vim.notify(string.format("python: %s  [%s %s]", info.path, info.kind, info.name), vim.log.levels.INFO)
    end, { desc = "Show resolved Python path" })
end

return M
