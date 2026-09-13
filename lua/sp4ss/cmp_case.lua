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

--- Split into lowercase word parts (snake, kebab, camel, Pascal).
local function split_parts(s)
  if type(s) ~= 'string' or s == '' then
    return {}
  end

  local normalized = s
    :gsub('([a-z0-9])([A-Z])', '%1_%2')
    :gsub('([A-Z]+)([A-Z][a-z])', '%1_%2')
    :gsub('[-_]+', '_')
    :gsub('^_+', '')
    :gsub('_+$', '')

  local parts = {}
  for part in normalized:gmatch('[^_]+') do
    if part ~= '' then
      table.insert(parts, part:lower())
    end
  end
  return parts
end

--- Build style variants for any token (1+ parts).
local function build_variants(parts)
  if #parts == 0 then
    return {}
  end

  local titled = {}
  for i, p in ipairs(parts) do
    titled[i] = title(p)
  end

  local snake = table.concat(parts, '_')
  local kebab = table.concat(parts, '-')
  local pascal = table.concat(titled, '')
  local camel = pascal:sub(1, 1):lower() .. pascal:sub(2)
  local screaming = snake:upper()
  local pascal_snake = table.concat(titled, '_')
  local pascal_kebab = table.concat(titled, '-')
  local dsnake = table.concat(parts, '__')
  local dkebab = table.concat(parts, '--')

  local rows = {
    { snake, 'snake' },
    { kebab, 'kebab' },
    { camel, 'camel' },
    { pascal, 'Pascal' },
    { pascal_snake, 'Pascal_Snake' },
    { pascal_kebab, 'Pascal-Kebab' },
    { screaming, 'SCREAMING' },
  }

  if #parts >= 2 then
    table.insert(rows, { dsnake, 'snake__' })
    table.insert(rows, { dkebab, 'kebab--' })
  end

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

    local seen = { [keyword] = true }
    local items = {}

    for rank, row in ipairs(build_variants(parts)) do
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
