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
            local python_env = require('sp4ss.python_env')

            lsp_zero.on_attach(function(client, bufnr)
                -- This creates the standard LSP keybindings
                -- (gd for definition, K for hover, etc.)
                lsp_zero.default_keymaps({ buffer = bufnr })
                -- Never format the WHOLE file on save. Visual Space f = range only.
                vim.b[bufnr].lsp_zero_enable_autoformat = false
                if client.server_capabilities then
                    client.server_capabilities.documentFormattingProvider = false
                end
            end)

            ---------------------------------------------------------------------------
            -- Installed-library completions (all languages)
            --
            -- Dropdown API members (pkg.sub.xxx → real symbols) come from each LSP
            -- seeing the right toolchain + project deps:
            --   pyright  → conda/venv pythonPath  (special: often not on bare PATH)
            --   gopls    → go.mod + GOPATH/module cache
            --   rust-analyzer → Cargo.toml + target/
            --   ts_ls    → package.json + node_modules
            --   clangd   → compile_commands.json
            --   …others  → project root + tools on PATH when nvim is launched
            --
            -- Blink ranks the `lsp` source highest so package APIs beat buffer words.
            -- Python: :PythonSelectEnv or conda activate / project .venv
            -- (shared with the file runner via sp4ss.python_env).
            ---------------------------------------------------------------------------

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
                    pyright = function()
                        require('lspconfig').pyright.setup({
                            capabilities = capabilities,
                            settings = {
                                python = {
                                    analysis = {
                                        -- Use installed package source/stubs for attribute completions
                                        -- (jax.lax.*, numpy.*, torch.*, …) from the resolved env.
                                        autoSearchPaths = true,
                                        useLibraryCodeForTypes = true,
                                        diagnosticMode = 'openFilesOnly',
                                        typeCheckingMode = 'basic',
                                        autoImportCompletions = true,
                                    },
                                },
                            },
                            before_init = function(_, config)
                                local python = python_env.resolve()
                                if not python then
                                    return
                                end
                                config.settings = config.settings or {}
                                config.settings.python = config.settings.python or {}
                                config.settings.python.pythonPath = python
                            end,
                            on_new_config = function(config, _)
                                local python = python_env.resolve()
                                if not python then
                                    return
                                end
                                config.settings = config.settings or {}
                                config.settings.python = config.settings.python or {}
                                config.settings.python.pythonPath = python
                            end,
                        })
                    end,
                }
            })
        end
    }
}
