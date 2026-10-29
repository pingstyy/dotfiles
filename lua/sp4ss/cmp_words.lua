--- blink.cmp source: English / math / science word completions inside identifiers.
--- @module 'blink.cmp'
--- @class blink.cmp.Source
local source = {}

local suggest = require('sp4ss.word_suggest')

local cache = {}

local function ident_list(buf)
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local hit = cache[buf]
  if hit and hit.tick == tick then
    return hit.list
  end
  local list = {}
  local seen = {}
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    for word in line:gmatch('[%a_][%w_]*') do
      if #word >= 2 and not seen[word] then
        seen[word] = true
        list[#list + 1] = word
      end
    end
  end
  cache[buf] = { tick = tick, list = list }
  return list
end

local function known_names()
  local cur = vim.api.nvim_get_current_buf()
  local bufs = { cur }
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= cur and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == '' then
      bufs[#bufs + 1] = buf
    end
  end
  local names = {}
  local seen = {}
  for _, buf in ipairs(bufs) do
    for _, word in ipairs(ident_list(buf)) do
      if not seen[word] then
        seen[word] = true
        names[#names + 1] = word
      end
    end
  end
  return names
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
    if not keyword or #keyword < 2 or not keyword:match('[%a]') then
      respond({})
      return
    end

    local hits = {}
    local seen = {}
    local function add(hit)
      if hit and hit.insert and not seen[hit.insert] then
        seen[hit.insert] = true
        hits[#hits + 1] = hit
      end
    end
    for _, hit in ipairs(suggest.suggest_known(keyword, known_names(), 6)) do
      add(hit)
    end
    for _, hit in ipairs(suggest.suggest(keyword, 8)) do
      add(hit)
    end
    if #hits == 0 then
      respond({})
      return
    end
    if #hits > 8 then
      for i = 9, #hits do
        hits[i] = nil
      end
    end

    local start_col, end_col = require('blink.cmp.fuzzy').get_keyword_range(ctx.line, ctx.cursor[2], 'prefix')
    local line0 = ctx.cursor[1] - 1
    local kind = require('blink.cmp.types').CompletionItemKind.Text
    local plain = vim.lsp.protocol.InsertTextFormat.PlainText
    local items = {}

    for rank, hit in ipairs(hits) do
      items[rank] = {
        label = hit.insert,
        labelDescription = hit.word,
        kind = kind,
        insertTextFormat = plain,
        filterText = keyword,
        sortText = string.format('%02d%s', rank, hit.word),
        textEdit = {
          newText = hit.insert,
          range = {
            start = { line = line0, character = start_col },
            ['end'] = { line = line0, character = end_col },
          },
        },
      }
    end

    respond(items)
  end)

  if not ok then
    vim.schedule(function()
      vim.notify('words source: ' .. tostring(err), vim.log.levels.WARN)
    end)
    respond({})
  end

  return function() end
end

return source
