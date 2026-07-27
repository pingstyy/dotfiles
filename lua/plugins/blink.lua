return {
  'saghen/blink.cmp',
  dependencies = 'rafamadriz/friendly-snippets',
  version = '*',
  opts = {
    keymap = {
      preset = 'none', -- Disables standard presets so we can optimize around your hand posture

      -- Popup/snippet flow: reachable on Mac without stretching to left Control.
      ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
      ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },

      -- Confirm the selected completion. If the menu is closed, Enter stays normal.
      ['<CR>'] = { 'select_and_accept', 'fallback' },
      ['<M-CR>'] = { 'accept_and_enter', 'fallback' },
      ['<M-Space>'] = { 'show', 'show_documentation', 'hide_documentation' },

      -- Directly accept suggestion 1-5 with Option+number.
      ['<M-1>'] = { function(cmp) cmp.accept({ index = 1 }) end },
      ['<M-2>'] = { function(cmp) cmp.accept({ index = 2 }) end },
      ['<M-3>'] = { function(cmp) cmp.accept({ index = 3 }) end },
      ['<M-4>'] = { function(cmp) cmp.accept({ index = 4 }) end },
      ['<M-5>'] = { function(cmp) cmp.accept({ index = 5 }) end },

      -- Thumb-driven doc scrolling.
      ['<M-j>'] = { 'scroll_documentation_down', 'fallback' },
      ['<M-k>'] = { 'scroll_documentation_up', 'fallback' },
    },
    -- Case-insensitive fuzzy: e.g. "selfatn" -> "Self_attention_score"
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
