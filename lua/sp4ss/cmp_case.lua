--- blink.cmp source: live case/style variants for *whatever* you are typing.
---
--- "xxxx" in docs = any identifier, not the letter x.
--- While you type foo_bar / foo-bar / fooBar / myname (3+ chars) the menu
--- offers snake, kebab, camel, Pascal, SCREAMING, etc. — no Esc needed.
---
--- is_incomplete_* always true so blink re-queries every keystroke.
--- @module 'blink.cmp'
--- @class blink.cmp.Source
local source = {}

local MIN_LEN = 2

local function title(part)
  if part == '' then
    return part
  end
  return part:sub(1, 1):upper() .. part:sub(2):lower()
end

--- Word parts with the capitalization the user typed.
local function split_parts(s)
  local parsed = require('sp4ss.word_suggest').parse(s)
  if not parsed then
    return {}
  end
  local parts = {}
  for _, part in ipairs(parsed) do
    if part.raw ~= '' then
      parts[#parts + 1] = part.raw
    end
  end
  return parts
end

local function map_parts(parts, fn)
  local out = {}
  for i, part in ipairs(parts) do
    out[i] = fn(part)
  end
  return out
end

--- Separator styles keep each word's case. Rewrites (lower, Pascal, SCREAMING)
--- come after the style that matches what was typed, so the default does not recase.
local function build_variants(parts, original)
  if #parts == 0 then
    return {}
  end

  local function join(list, sep)
    return table.concat(list, sep)
  end

  local preserved = {
    { join(parts, '_'), 'snake' },
    { join(parts, '-'), 'kebab' },
    { join(parts, ''), 'camel' },
  }
  if #parts >= 2 then
    preserved[#preserved + 1] = { join(parts, '__'), 'snake__' }
    preserved[#preserved + 1] = { join(parts, '--'), 'kebab--' }
  end

  local rows = {}
  local function add(text, style)
    rows[#rows + 1] = { text, style }
  end

  local matched = false
  for _, row in ipairs(preserved) do
    if row[1] == original then
      add(row[1], row[2])
      matched = true
    end
  end
  if not matched then
    add(original, 'as typed')
  end
  for _, row in ipairs(preserved) do
    if row[1] ~= original then
      add(row[1], row[2])
    end
  end

  local lower = map_parts(parts, string.lower)
  local titled = map_parts(parts, function(part)
    return title(part:lower())
  end)
  add(join(lower, '_'), 'lower_snake')
  add(join(titled, ''), 'Pascal')
  add(join(titled, '_'), 'Pascal_Snake')
  add(join(titled, '-'), 'Pascal-Kebab')
  add(join(lower, '_'):upper(), 'SCREAMING')

  return rows
end

function source.new()
  return setmetatable({}, { __index = source })
end

function source:enabled()
  local mode = vim.api.nvim_get_mode().mode
  if mode == 'c' or mode == 't' then
    return false
  end
  return vim.bo.buftype == ''
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
    local keyword = ctx.get_keyword()
    if not keyword or #keyword < MIN_LEN or not keyword:match('[%a_]') then
      respond({})
      return
    end

    local parts = split_parts(keyword)
    if #parts == 0 then
      respond({})
      return
    end

    local start_col, end_col = require('blink.cmp.fuzzy').get_keyword_range(ctx.line, ctx.cursor[2], 'prefix')
    local line0 = ctx.cursor[1] - 1
    local kind = require('blink.cmp.types').CompletionItemKind.Text
    local plain = vim.lsp.protocol.InsertTextFormat.PlainText

    local seen = {}
    local items = {}

    for rank, row in ipairs(build_variants(parts, keyword)) do
      local text, style = row[1], row[2]
      if text ~= '' and not seen[text] then
        seen[text] = true
        table.insert(items, {
          label = text,
          labelDescription = style,
          kind = kind,
          insertTextFormat = plain,
          filterText = keyword,
          sortText = string.format('%02d%s', rank, style),
          textEdit = {
            newText = text,
            range = {
              start = { line = line0, character = start_col },
              ['end'] = { line = line0, character = end_col },
            },
          },
        })
      end
    end

    respond(items)
  end)

  if not ok then
    vim.schedule(function()
      vim.notify('case source: ' .. tostring(err), vim.log.levels.WARN)
    end)
    respond({})
  end

  return function() end
end

return source
