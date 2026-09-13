-- Guard blink's emit_completions: crashes if a cached provider id is missing
-- (seen on cmdline after custom sources). Safe no-op for unknown ids.
local function patch_emit_completions()
  local ok, sources = pcall(require, 'blink.cmp.sources.lib')
  if not ok or not sources or sources._sp4ss_emit_patched then
    return
  end
  sources._sp4ss_emit_patched = true

  function sources.emit_completions(context, items_map)
    if type(items_map) ~= 'table' then
      return
    end
    local filtered = {}
    for id, items in pairs(items_map) do
      if type(id) == 'string' then
        local provider = sources.providers[id]
        if not provider then
          local ok_init, p = pcall(sources.get_provider_by_id, id)
          if ok_init then
            provider = p
          end
        end
        if provider then
          local ok_show, show = pcall(function()
            return provider:should_show_items(context, items)
          end)
          if ok_show and show then
            filtered[id] = items
          end
        end
      end
    end
    sources.completions_emitter:emit({ context = context, items = filtered })
  end
end

return {
  'saghen/blink.cmp',
  version = '*',
  build = 'cargo build --release',
  opts = {
    keymap = (function()
      local keymap = {
        preset = 'none',
        ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
        ['<CR>'] = { 'select_and_accept', 'fallback' },
        ['<M-CR>'] = { 'hide', 'fallback' },
        ['<D-CR>'] = { 'hide', 'fallback' },
        ['<C-CR>'] = { 'hide', 'fallback' },
        ['<M-S-CR>'] = { 'hide', 'fallback' },
        ['<D-S-CR>'] = { 'hide', 'fallback' },
        ['<C-S-CR>'] = { 'hide', 'fallback' },
        ['<M-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<C-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },
        ['<M-j>'] = { 'scroll_documentation_down', 'fallback' },
        ['<M-k>'] = { 'scroll_documentation_up', 'fallback' },
      }
      for i = 1, 9 do
        local accept_nth = function(cmp)
          return cmp.accept({ index = i })
        end
        -- Cmd-1..9 = file tabs (sp4ss.tabs). Completion pick stays Option-1..9.
        keymap[string.format('<M-%d>', i)] = { accept_nth }
        keymap[string.format('<A-%d>', i)] = { accept_nth }
      end
      return keymap
    end)(),
    fuzzy = {
      implementation = 'prefer_rust_with_warning',
      max_typos = function(keyword)
        return math.floor(#keyword / 3)
      end,
      use_proximity = true,
      frecency = { enabled = true },
      -- score first so pyclass scaffolds beat plain snippet labels
      sorts = { 'score', 'exact', 'sort_text' },
    },
    snippets = {
      preset = 'default',
      score_offset = 0,
    },
    completion = {
      keyword = { range = 'prefix' },
      trigger = {
        -- Popup while typing — no Esc / re-enter insert needed.
        show_on_keyword = true,
        show_on_trigger_character = true,
        show_on_insert_on_trigger_character = true,
        show_on_backspace = true,
        show_on_backspace_in_keyword = true,
        show_on_insert = true,
        show_on_accept_on_trigger_character = true,
      },
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 250,
      },
      ghost_text = { enabled = true },
      list = {
        selection = { preselect = true, auto_insert = false },
        -- Cap total completion rows (menu height tracks this; fewer if less match).
        max_items = 15,
      },
      menu = {
        auto_show = true,
        auto_show_delay_ms = 0,
        -- At most 15 visible rows; blink shrinks when fewer items.
        max_height = 15,
        draw = {
          columns = {
            { 'item_idx' },
            { 'kind_icon' },
            { 'label', 'label_description', gap = 1 },
            { 'source_name' },
          },
          components = {
            item_idx = {
              text = function(ctx)
                return ctx.idx == 10 and '0' or ctx.idx >= 10 and ' ' or tostring(ctx.idx)
              end,
              highlight = 'BlinkCmpItemIdx',
            },
          },
        },
      },
    },
    signature = {
      enabled = true,
      window = { show_documentation = false },
    },
    -- Keep cmdline on stock providers only (avoids custom-source crashes).
    cmdline = {
      enabled = true,
      sources = { 'buffer', 'cmdline' },
    },
    sources = {
      -- Buffer first in the list (and highest score_offset) so open-file words win.
      default = { 'buffer', 'lsp', 'snippets', 'path', 'case' },
      -- Python-only class scaffolds (not global — keeps cmdline clean).
      per_filetype = {
        python = { inherit_defaults = true, 'pyclass' },
        c = { inherit_defaults = true, 'include' },
        cpp = { inherit_defaults = true, 'include' },
        cuda = { inherit_defaults = true, 'include' },
        objc = { inherit_defaults = true, 'include' },
        objcpp = { inherit_defaults = true, 'include' },
      },
      providers = {
        -- Ranking: Buffer > LSP > Class > Case > snippets > path
        buffer = {
          name = 'Buffer',
          -- Highest: words already in open files (Usetyp, RMSNorm, …).
          score_offset = 120,
          min_keyword_length = 2,
          max_items = 10,
          opts = {
            get_bufnrs = function()
              return vim.tbl_filter(function(bufnr)
                return vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buftype == ''
              end, vim.api.nvim_list_bufs())
            end,
          },
        },
        lsp = {
          score_offset = 50,
          fallbacks = {},
        },
        pyclass = {
          name = 'Class',
          module = 'sp4ss.cmp_class',
          -- Below buffer/LSP so real symbols stay on top.
          score_offset = 30,
          min_keyword_length = 3,
          max_items = 4,
        },
        include = {
          name = 'Include',
          module = 'sp4ss.cmp_include',
          -- Beat case/buffer on include lines so `inc` → `#include <…>`.
          score_offset = 90,
          min_keyword_length = 0,
          max_items = 12,
        },
        case = {
          name = 'Case',
          module = 'sp4ss.cmp_case',
          score_offset = 15,
          min_keyword_length = 2,
          max_items = 8,
        },
        snippets = {
          score_offset = 10,
          max_items = 6,
          opts = {
            friendly_snippets = false,
            search_paths = { vim.fn.stdpath('config') .. '/snippets' },
            global_snippets = { 'all' },
            use_label_description = true,
          },
          transform_items = function(_, items)
            local seen = {}
            local out = {}
            for _, item in ipairs(items) do
              local key = item.insertText or (item.textEdit and item.textEdit.newText) or item.label
              if type(key) == 'string' and not seen[key] then
                seen[key] = true
                table.insert(out, item)
              end
            end
            return out
          end,
        },
        path = {
          score_offset = 5,
          fallbacks = {},
        },
      },
    },
  },
  config = function(_, opts)
    require('blink.cmp').setup(opts)
    -- After setup (and async fuzzy download), patch the crashy emitter.
    patch_emit_completions()
    vim.schedule(patch_emit_completions)
    vim.defer_fn(patch_emit_completions, 500)
  end,
}
