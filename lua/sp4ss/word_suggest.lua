--- Turn a partial identifier into dictionary completions.
--- Letters already typed stay as written. Only the missing tail is appended.
--- currentSlackR → currentSlackRate
--- current_slack_r → current_slack_rate
--- CURRENT_SLACK_R → CURRENT_SLACK_Rate
local M = {}

local wordbank = require('sp4ss.wordbank')

local function is_sep(c)
  return c == '_' or c == '-'
end

local function preserve(prefix, word)
  return prefix .. word:sub(#prefix + 1)
end

function M.parse(s)
  if type(s) ~= 'string' or s == '' then
    return nil
  end
  local parts = {}
  local i = 1
  local n = #s
  while i <= n do
    local sep = ''
    if #parts > 0 then
      local sep_start = i
      while i <= n and is_sep(s:sub(i, i)) do
        i = i + 1
      end
      sep = s:sub(sep_start, i - 1)
      if i > n then
        parts[#parts + 1] = { sep = sep, raw = '' }
        break
      end
    end
    local start = i
    local c = s:sub(i, i)
    if c:match('%d') then
      repeat
        i = i + 1
      until i > n or not s:sub(i, i):match('%d')
    elseif c:match('%u') then
      i = i + 1
      if i <= n and s:sub(i, i):match('%u') then
        while i <= n and s:sub(i, i):match('%u') do
          if s:sub(i + 1, i + 1):match('%l') then
            break
          end
          i = i + 1
        end
      else
        while i <= n and s:sub(i, i):match('[%l%d]') do
          i = i + 1
        end
      end
    elseif c:match('%l') then
      i = i + 1
      while i <= n and s:sub(i, i):match('[%l%d]') do
        i = i + 1
      end
    else
      return nil
    end
    local raw = s:sub(start, i - 1)
    if raw == '' then
      return nil
    end
    parts[#parts + 1] = { sep = sep, raw = raw }
  end
  if #parts == 0 then
    return nil
  end
  return parts
end

local function render(parts, last_word)
  local chunks = {}
  for i, part in ipairs(parts) do
    local text = part.raw
    if i == #parts then
      text = preserve(part.raw, last_word)
    end
    chunks[i] = part.sep .. text
  end
  return table.concat(chunks)
end

function M.suggest(keyword, limit)
  local parts = M.parse(keyword)
  if not parts then
    return {}
  end
  local last = parts[#parts]
  if last.raw == '' or not last.raw:match('^%a+$') then
    return {}
  end
  local prefix = last.raw:lower()
  if #prefix < 2 and #parts < 2 then
    return {}
  end
  local hits = wordbank.lookup(prefix, limit or 8)
  local out = {}
  for _, word in ipairs(hits) do
    local insert = render(parts, word)
    if insert ~= keyword then
      out[#out + 1] = {
        insert = insert,
        word = preserve(last.raw, word),
      }
    end
  end
  return out
end

local function render_known(parts, name)
  local chunks = {}
  for i, part in ipairs(parts) do
    if i == #parts then
      chunks[i] = part.sep .. name
    else
      chunks[i] = part.sep .. part.raw
    end
  end
  return table.concat(chunks)
end

--- Existing spellings win over the letters typed for that last word.
--- atF + FeRRA → atFeRRA. atf + FeRRA → atFeRRA.
function M.suggest_known(keyword, names, limit)
  local parts = M.parse(keyword)
  if not parts or type(names) ~= 'table' then
    return {}
  end
  local last = parts[#parts]
  if last.raw == '' or not last.raw:match('^%a[%w_]*$') then
    return {}
  end
  if #last.raw < 2 and #parts < 2 then
    return {}
  end
  local raw = last.raw
  local low = raw:lower()
  local exact, loose = {}, {}
  for _, name in ipairs(names) do
    if type(name) == 'string' and #name > #raw and name:match('^%a[%w_]*$') then
      local head = name:sub(1, #raw)
      if head == raw then
        exact[#exact + 1] = name
      elseif head:lower() == low then
        loose[#loose + 1] = name
      end
    end
  end
  local cap = limit or 6
  local out = {}
  local function push(name)
    if #out >= cap then
      return
    end
    local insert = render_known(parts, name)
    if insert ~= keyword then
      out[#out + 1] = { insert = insert, word = name }
    end
  end
  for _, name in ipairs(exact) do
    push(name)
  end
  for _, name in ipairs(loose) do
    push(name)
  end
  return out
end

return M
