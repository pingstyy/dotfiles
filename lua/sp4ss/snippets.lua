local M = {}

local snippets_dir = vim.fn.stdpath("config") .. "/snippets"
local package_path = snippets_dir .. "/package.json"

local function notify(msg, level)
    vim.notify(msg, level or vim.log.levels.INFO)
end

local function read_file(path)
    local fd = io.open(path, "r")
    if not fd then
        return nil
    end
    local data = fd:read("*a")
    fd:close()
    return data
end

local function write_file(path, data)
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
    local fd = assert(io.open(path, "w"))
    fd:write(data)
    fd:close()
end

local function decode_json(path, fallback)
    local data = read_file(path)
    if not data or vim.trim(data) == "" then
        return fallback
    end

    local ok, decoded = pcall(vim.json.decode, data)
    if not ok then
        notify("Invalid JSON: " .. path, vim.log.levels.ERROR)
        return fallback
    end
    return decoded
end

local function encode_json(value)
    return vim.json.encode(value) .. "\n"
end

local function snippet_file_for(ft)
    return ft:gsub("[^%w_%-]", "_") .. ".json"
end

local function package()
    local pkg = decode_json(package_path, nil)
    if pkg then
        pkg.contributes = pkg.contributes or {}
        pkg.contributes.snippets = pkg.contributes.snippets or {}
        return pkg
    end

    return {
        name = "sp4ss-snippets",
        contributes = {
            snippets = {
                { language = "all", path = "./all.json" },
            },
        },
    }
end

local function has_entry(entries, ft, relpath)
    for _, entry in ipairs(entries) do
        local languages = type(entry.language) == "table" and entry.language or { entry.language }
        if entry.path == relpath and vim.tbl_contains(languages, ft) then
            return true
        end
    end
    return false
end

local function ensure_package_entry(ft, relpath)
    local pkg = package()
    local entries = pkg.contributes.snippets

    if not has_entry(entries, ft, relpath) then
        table.insert(entries, { language = ft, path = relpath })
        write_file(package_path, encode_json(pkg))
        notify("Registered snippets for " .. ft)
    end
end

local function default_snippet(ft)
    return {
        ["note"] = {
            prefix = "note",
            description = "Tiny personal note snippet",
            body = {
                "// ${1:note}",
            },
        },
    }
end

function M.edit(ft)
    ft = ft ~= "" and ft or vim.bo.filetype
    if not ft or ft == "" then
        ft = "all"
    end

    local relpath = "./" .. snippet_file_for(ft)
    local path = snippets_dir .. "/" .. snippet_file_for(ft)

    ensure_package_entry(ft, relpath)
    if vim.fn.filereadable(path) == 0 then
        write_file(path, encode_json(default_snippet(ft)))
    end

    vim.cmd.edit(vim.fn.fnameescape(path))
end

function M.package()
    if vim.fn.filereadable(package_path) == 0 then
        write_file(package_path, encode_json(package()))
    end
    vim.cmd.edit(vim.fn.fnameescape(package_path))
end

function M.check(prefix)
    prefix = prefix or ""
    if prefix == "" then
        prefix = vim.fn.expand("<cword>")
    end
    if prefix == "" then
        notify("Usage: :SnippetCheck <prefix>", vim.log.levels.WARN)
        return
    end

    local pkg = package()
    local hits = {}

    for _, entry in ipairs(pkg.contributes.snippets or {}) do
        local path = snippets_dir .. "/" .. (entry.path or ""):gsub("^%./", "")
        local snippets = decode_json(path, {})
        for name, snippet in pairs(snippets or {}) do
            local prefixes = type(snippet.prefix) == "table" and snippet.prefix or { snippet.prefix or name }
            if name == prefix or vim.tbl_contains(prefixes, prefix) then
                local language = type(entry.language) == "table" and table.concat(entry.language, ",") or entry.language
                table.insert(hits, string.format("%s -> %s (%s)", prefix, path, language or "unknown"))
            end
        end
    end

    if #hits == 0 then
        notify("No custom snippet prefix found: " .. prefix)
    else
        notify(table.concat(hits, "\n"))
    end
end

return M
