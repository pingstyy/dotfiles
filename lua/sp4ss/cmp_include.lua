--- blink.cmp source: C/C++ #include helper.
--- Type `inc` / `include` / `#include` at line start → `#include <header>`.
--- Type a lib stub (`include std`, `#include <io`) → full `<stdio.h>` / `<iostream>`.
--- @module 'blink.cmp'
--- @class blink.cmp.Source
local source = {}

local FT = {
  c = true,
  cpp = true,
  cuda = true,
  objc = true,
  objcpp = true,
}

-- Common stdlib headers. Prefix match + substring match on the typed stub.
local HEADERS = {
  'iostream', 'string', 'vector', 'map', 'unordered_map', 'set', 'unordered_set',
  'algorithm', 'memory', 'utility', 'functional', 'iterator', 'numeric',
  'array', 'deque', 'list', 'queue', 'stack', 'forward_list', 'tuple',
  'optional', 'variant', 'any', 'string_view', 'span', 'filesystem',
  'thread', 'mutex', 'atomic', 'chrono', 'random', 'regex', 'type_traits',
  'exception', 'stdexcept', 'limits', 'bitset', 'sstream', 'fstream',
  'iomanip', 'ios', 'istream', 'ostream', 'locale', 'complex', 'cmath',
  'cstdio', 'cstdlib', 'cstring', 'cstdint', 'cstddef', 'cassert',
  'format', 'ranges', 'concepts', 'bit', 'expected', 'print',
  'initializer_list', 'new', 'source_location', 'numbers',
  'bits/stdc++.h',
  'stdio.h', 'stdlib.h', 'string.h', 'math.h', 'ctype.h', 'time.h',
  'stdbool.h', 'stdint.h', 'stddef.h', 'assert.h', 'limits.h', 'float.h',
  'stdarg.h', 'errno.h', 'unistd.h', 'fcntl.h', 'signal.h', 'pthread.h',
  'inttypes.h', 'wchar.h', 'locale.h', 'sys/types.h', 'sys/stat.h',
}

local POPULAR = {
  iostream = 1, vector = 2, string = 3, map = 4, algorithm = 5, memory = 6,
  ['stdio.h'] = 7, ['stdlib.h'] = 8, ['string.h'] = 9, ['stdint.h'] = 10,
  ['bits/stdc++.h'] = 11,
}

local function is_inc_kw(s)
  if type(s) ~= 'string' or #s < 3 or #s > 7 then
    return false
  end
  return ('include'):sub(1, #s) == s:lower()
end

local function parse_include(before)
  local indent, hash, kw, after = before:match('^([ \t]*)(#?)[ \t]*([%w]+)(.*)$')
  if not indent or not is_inc_kw(kw) then
    return nil
  end
  local open, name = after:match('^[ \t]*([<"]?)[ \t]*([^>"]*)')
  return {
    start_col = #indent,
    open = open or '',
    name = name or '',
    hash = hash or '',
  }
end

local function matches(header, q)
  if q == '' then
    return true
  end
  local h = header:lower()
  if h:sub(1, #q) == q then
    return true
  end
  local base = h:gsub('%.h$', ''):gsub('^.*/', '')
  if base:sub(1, #q) == q then
    return true
  end
  return h:find(q, 1, true) ~= nil
end

function source.new()
  return setmetatable({}, { __index = source })
end

function source:enabled()
  local mode = vim.api.nvim_get_mode().mode
  if mode == 'c' or mode == 't' then
    return false
  end
  if vim.bo.buftype ~= '' then
    return false
  end
  return FT[vim.bo.filetype] == true
end

function source:get_trigger_characters()
  return { '<', '"', '/', '.', '#' }
end

function source:get_completions(ctx, callback)
  local function respond(items)
    callback({
      items = items or {},
      is_incomplete_forward = true,
      is_incomplete_backward = true,
    })
  end

  local ok, err = pcall(function()
    local col = ctx.cursor[2]
    local parsed = parse_include(ctx.line:sub(1, col))
    if not parsed then
      respond({})
      return
    end

    local q = parsed.name:lower()
    local open = parsed.open
    if open == '' then
      open = '<'
    end
    local close = open == '"' and '"' or '>'

    local kind = require('blink.cmp.types').CompletionItemKind.File
    local plain = vim.lsp.protocol.InsertTextFormat.PlainText
    local line0 = ctx.cursor[1] - 1
    -- Blink filters against this; must contain the current keyword (`inc` / `std`).
    local keyword = ctx.get_keyword()
    if not keyword or keyword == '' then
      keyword = q ~= '' and q or 'inc'
    end

    local hits = {}
    for _, header in ipairs(HEADERS) do
      if matches(header, q) then
        table.insert(hits, header)
      end
    end
    table.sort(hits, function(a, b)
      local pa, pb = POPULAR[a] or 99, POPULAR[b] or 99
      if pa ~= pb then
        return pa < pb
      end
      local qa = a:lower():sub(1, #q) == q
      local qb = b:lower():sub(1, #q) == q
      if qa ~= qb then
        return qa
      end
      return a < b
    end)

    local items = {}
    for rank, header in ipairs(hits) do
      if rank > 15 then
        break
      end
      local text = '#include ' .. open .. header .. close
      table.insert(items, {
        label = text,
        labelDescription = 'include',
        kind = kind,
        insertTextFormat = plain,
        filterText = keyword,
        sortText = string.format('%02d%s', rank, header),
        textEdit = {
          newText = text,
          range = {
            start = { line = line0, character = parsed.start_col },
            ['end'] = { line = line0, character = col },
          },
        },
      })
    end
    respond(items)
  end)

  if not ok then
    vim.schedule(function()
      vim.notify('include source: ' .. tostring(err), vim.log.levels.WARN)
    end)
    respond({})
  end

  return function() end
end

return source
