return {
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v3.x',
        dependencies = {
            --- LSP Support
            { 'neovim/nvim-lspconfig' },
            { 'williamboman/mason.nvim' },
            { 'williamboman/mason-lspconfig.nvim' },

            --- Autocompletion
            { 'saghen/blink.cmp' },
        },
        config = function()
            local lsp_zero = require('lsp-zero')
            local capabilities = require('blink.cmp').get_lsp_capabilities()

            lsp_zero.on_attach(function(client, bufnr)
                -- This creates the standard LSP keybindings
                -- (gd for definition, K for hover, etc.)
                lsp_zero.default_keymaps({ buffer = bufnr })
            end)

            require('mason').setup({})
            require('mason-lspconfig').setup({
                -- This is your massive language list
                ensure_installed = {
                    'rust_analyzer', -- Rust
                    'gopls',         -- Go
                    'jdtls',         -- Java
                    'pyright',       -- Python
                    'clangd',        -- C, C++, CUDA
                    'hls',           -- Haskell
                    -- 'ocamllsp',       -- OCaml / OxCaml-adjacent editing
                    'elixirls',      -- Elixir
                    'julials',       -- Julia
                    'zls',           -- Zig
                    'lua_ls',        -- Lua
                    'ts_ls',         -- JS/TS
                    'html',          -- HTML
                    'cssls',         -- CSS
                    --                    'makefile_language_server', -- Make
                },
                handlers = {
                    function(server_name)
                        require('lspconfig')[server_name].setup({
                            capabilities = capabilities,
                        })
                    end,
                    lua_ls = function()
                        local lua_opts = lsp_zero.nvim_lua_ls()
                        lua_opts.capabilities = capabilities
                        require('lspconfig').lua_ls.setup(lua_opts)
                    end,
                }
            })
        end
    }
}
