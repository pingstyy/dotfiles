return {
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        dependencies = {
            --- LSP Support
            {'neovim/nvim-lspconfig'},
            {'williamboman/mason.nvim'},
            {'williamboman/mason-lspconfig.nvim'},

            --- Autocompletion
            {'hrsh7th/nvim-cmp'},
            {'hrsh7th/cmp-nvim-lsp'},
            {'L3MON4D3/LuaSnip'},
        },
        config = function()
            local lsp_zero = require('lsp-zero')

            lsp_zero.on_attach(function(client, bufnr)
                -- This creates the standard LSP keybindings
                -- (gd for definition, K for hover, etc.)
                lsp_zero.default_keymaps({buffer = bufnr})
            end)

            require('mason').setup({})
            require('mason-lspconfig').setup({
                -- This is your massive language list
                ensure_installed = {
                    'rust_analyzer',  -- Rust
--                    'gopls',          -- Go
                    'jdtls',          -- Java
                    'pyright',        -- Python
                    'clangd',         -- C, C++, CUDA
                    'hls',            -- Haskell
  --                  'ocamllsp',       -- OCaml
                    'zls',            -- Zig
                    'lua_ls',         -- Lua
                    'ts_ls',          -- JS/TS
                    'html',           -- HTML
                    'cssls',          -- CSS
--                    'makefile_language_server', -- Make
                },
                handlers = {
                    lsp_zero.default_setup,
                    lua_ls = function()
                        local lua_opts = lsp_zero.nvim_lua_ls()
                        require('lspconfig').lua_ls.setup(lua_opts)
                    end,
                }
            })

            -- Setup Autocompletion
            local cmp = require('cmp')
            cmp.setup({
                mapping = cmp.mapping.preset.insert({
                    ['<C-p>'] = cmp.mapping.select_prev_item(cmp_select),
                    ['<C-n>'] = cmp.mapping.select_next_item(cmp_select),
                    ['<C-y>'] = cmp.mapping.confirm({ select = true }),
                    ["<C-Space>"] = cmp.mapping.complete(),
                })
            })
        end
    }
}

