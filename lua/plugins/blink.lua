return {
  'saghen/blink.cmp',
  dependencies = 'rafamadriz/friendly-snippets',
  version = '*',
  opts = {
    keymap = (function()
      local keymap = {
        preset = 'none', -- Disables standard presets so we can optimize around your hand posture

        -- Popup/snippet flow: reachable on Mac without stretching to left Control.
        ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },

        -- Confirm the selected completion. If the menu is closed, Enter stays normal.
        ['<CR>'] = { 'select_and_accept', 'fallback' },
        ['<M-CR>'] = { 'accept_and_enter', 'fallback' },
        ['<M-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },

        -- Thumb-driven doc scrolling.
        ['<M-j>'] = { 'scroll_documentation_down', 'fallback' },
        ['<M-k>'] = { 'scroll_documentation_up', 'fallback' },
      }

      -- Accept nth dropdown item (1-based index).
      -- Cmd+N works in GUI (Neovide); Option+N is the reliable terminal fallback.
      for i = 1, 9 do
        local accept_nth = function(cmp)
          cmp.accept({ index = i })
        end
        keymap[string.format('<D-%d>', i)] = { accept_nth }
        keymap[string.format('<M-%d>', i)] = { accept_nth }
      end

      return keymap
    end)(),
    -- Case-insensitive fuzzy: "selfatn" / "self-attention" -> "Self_Attention_Xxx"
    -- Typo resistance / snake_case scoring need the Rust matcher.
    fuzzy = {
      implementation = 'prefer_rust_with_warning',
      max_typos = function(keyword)
        return math.floor(#keyword / 3)
      end,
      use_proximity = true,
      sorts = { 'score', 'sort_text' },
    },
    completion = {
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 350,
      },
      ghost_text = {
        enabled = true,
      },
      list = {
        selection = {
          preselect = true,
          auto_insert = false,
        },
      },
    },
    signature = {
      enabled = true,
      window = {
        show_documentation = false,
      },
    },
    snippets = {
      preset = 'default',
    },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer' },
      -- Treat _ and - as interchangeable for matching so typing
      -- "self-attention-xxx" can rank "Self_Attention_Xxx".
      transform_items = function(_, items)
        for _, item in ipairs(items) do
          local text = item.filterText or item.label
          if type(text) == 'string' and text:find('_', 1, true) then
            -- Match needle with hyphens against symbols that use underscores.
            item.filterText = text:gsub('_', '-')
          end
        end
        return items
      end,
      providers = {
        snippets = {
          opts = {
            friendly_snippets = true,
            search_paths = { vim.fn.stdpath('config') .. '/snippets' },
            global_snippets = { 'all' },
            use_label_description = true,
          },
        },
        buffer = {
          opts = {
            get_bufnrs = function()
              return vim.tbl_filter(function(bufnr)
                return vim.bo[bufnr].buftype == ''
              end, vim.api.nvim_list_bufs())
            end,
          },
        },
      },
    },
  },
}
