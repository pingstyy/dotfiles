-- ss: innermost function or loop, else the blank-line block under the cursor.
local M = {}

local FUNCTION = {
    ["function"] = true,
    function_definition = true,
    function_declaration = true,
    function_item = true,
    function_expression = true,
    generator_function = true,
    generator_function_declaration = true,
    arrow_function = true,
    method = true,
    method_definition = true,
    method_declaration = true,
    constructor_declaration = true,
    local_function = true,
    func_literal = true,
    lambda = true,
    lambda_expression = true,
    anonymous_function = true,
}

local LOOP = {
    for_statement = true,
    for_in_statement = true,
    foreach_statement = true,
    enhanced_for_statement = true,
    while_statement = true,
    do_statement = true,
    repeat_statement = true,
    loop_expression = true,
    for_expression = true,
    while_expression = true,
}

local function blank(lnum)
    return vim.fn.getline(lnum):match("^%s*$") ~= nil
end

local function node_lines(node)
    local sr, _, er, ec = node:range()
    local start_line = sr + 1
    local end_line = ec == 0 and er or (er + 1)
    if end_line < start_line then
        end_line = start_line
    end
    local last = vim.api.nvim_buf_line_count(0)
    if end_line > last then
        end_line = last
    end
    return start_line, end_line
end

local function node_at_cursor()
    local ok, node = pcall(vim.treesitter.get_node, { ignore_injections = true })
    if ok and node then
        return node
    end
    local pok, parser = pcall(vim.treesitter.get_parser, 0)
    if not pok or not parser then
        return nil
    end
    local trees = parser:parse(true)
    local tree = trees and trees[1]
    if not tree then
        return nil
    end
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    row = row - 1
    return tree:root():named_descendant_for_range(row, col, row, col)
end

function M.range()
    local node = node_at_cursor()
    while node do
        local t = node:type()
        if FUNCTION[t] or LOOP[t] then
            return node_lines(node)
        end
        node = node:parent()
    end

    local cur = vim.api.nvim_win_get_cursor(0)[1]
    if blank(cur) then
        return nil
    end
    local s, e = cur, cur
    local last = vim.api.nvim_buf_line_count(0)
    while s > 1 and not blank(s - 1) do
        s = s - 1
    end
    while e < last and not blank(e + 1) do
        e = e + 1
    end
    return s, e
end

function M.select()
    local s, e = M.range()
    if not s then
        vim.notify("No scope here", vim.log.levels.WARN)
        return
    end
    vim.api.nvim_win_set_cursor(0, { s, 0 })
    vim.cmd("normal! V")
    if e > s then
        vim.cmd("normal! " .. (e - s) .. "j")
    end
end

return M
