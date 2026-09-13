--- blink.cmp source: Python class scaffolds while you type *any* word (3+ chars).
--- Not tied to the letter "x" — any identifier of length >= 3 shows templates.
--- Auto-updates every keystroke (is_incomplete_* = true).
--- @module 'blink.cmp'
--- @class blink.cmp.Source
local source = {}

local FT = {
  python = true,
  python3 = true,
}

local MIN_LEN = 3

local SCAFFOLDS = {
  {
    label = '◆ class + init + call',
    desc = 'class with clean __init__ and __call__',
    body = table.concat({
      'class ${1:Name}:',
      '\tdef __init__(self${2:}):',
      '\t\t${3:pass}',
      '',
      '\tdef __call__(self${4:}, *args, **kwargs):',
      '\t\t${0:return None}',
    }, '\n'),
  },
  {
    label = '◆ class + init',
    desc = 'class with clean __init__ only',
    body = table.concat({
      'class ${1:Name}:',
      '\tdef __init__(self${2:}):',
      '\t\t${0:pass}',
    }, '\n'),
  },
  {
    label = '◆ @dataclass',
    desc = '@dataclass class (no import)',
    body = table.concat({
      '@dataclass',
      'class ${1:Name}:',
      '\t${2:field}: ${3:str}',
      '\t${0}',
    }, '\n'),
  },
  {
    label = '◆ @dataclass + import',
    desc = 'from dataclasses import dataclass + class',
    body = table.concat({
      'from dataclasses import dataclass',
      '',
      '',
      '@dataclass',
      'class ${1:Name}:',
      '\t${2:field}: ${3:str}',
      '\t${0}',
    }, '\n'),
  },
}

function source.new()
  return setmetatable({}, { __index = source })
end

function source:enabled()
  -- Allow whenever filetype is python and not cmdline (insert or normal preview).
  local mode = vim.api.nvim_get_mode().mode
  if mode == 'c' or mode == 't' then
    return false
  end
  if vim.bo.buftype ~= '' then
    return false
  end
  return FT[vim.bo.filetype] == true
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
    -- Any word 3+ chars (user meant "xxxx" as placeholder, not letter x).
    if not keyword or #keyword < MIN_LEN then
      respond({})
      return
    end

    local start_col, end_col = require('blink.cmp.fuzzy').get_keyword_range(ctx.line, ctx.cursor[2], 'prefix')
    local line0 = ctx.cursor[1] - 1
    local kind = require('blink.cmp.types').CompletionItemKind.Snippet
    local snip_fmt = vim.lsp.protocol.InsertTextFormat.Snippet

    -- If they typed a class-looking name, pre-fill ${1:Name} with it.
    local name = keyword
    if name:match('^[%a_][%w_]*$') and not name:match('^x+$') then
      -- PascalCase-ish default from keyword
      local parts = {}
      local n = name
        :gsub('([a-z0-9])([A-Z])', '%1_%2')
        :gsub('[-_]+', '_')
      for p in n:gmatch('[^_]+') do
        table.insert(parts, p:sub(1, 1):upper() .. p:sub(2):lower())
      end
      if #parts > 0 then
        name = table.concat(parts, '')
      end
    else
      name = 'Name'
    end

    local items = {}
    for i, sc in ipairs(SCAFFOLDS) do
      local body = sc.body:gsub('%$%{1:Name%}', '${1:' .. name .. '}')
      local pretty = body:gsub('\t', '    ')
      table.insert(items, {
        label = sc.label,
        labelDescription = sc.desc,
        kind = kind,
        insertTextFormat = snip_fmt,
        filterText = keyword,
        sortText = string.format('%02d', i),
        score_offset = 50,
        detail = pretty,
        documentation = {
          kind = 'markdown',
          value = '```python\n' .. pretty .. '\n```\n\n' .. sc.desc,
        },
        textEdit = {
          newText = body,
          range = {
            start = { line = line0, character = start_col },
            ['end'] = { line = line0, character = end_col },
          },
        },
      })
    end

    respond(items)
  end)

  if not ok then
    vim.schedule(function()
      vim.notify('pyclass source: ' .. tostring(err), vim.log.levels.WARN)
    end)
    respond({})
  end

  return function() end
end

return source
