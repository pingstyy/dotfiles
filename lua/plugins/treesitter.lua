return {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    config = function()
        -- This "pcall" prevents the error you saw!
        local status, ts = pcall(require, "nvim-treesitter.configs")
        if not status then return end

        ts.setup({
            ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "rust", "go", "python", "javascript", "typescript", "html", "css", "markdown", "markdown_inline" },
            sync_install = false,
            highlight = {
                enable = true,
                disable = function(_, buf)
                    return vim.b[buf].snacks_previewed == true or vim.bo[buf].buftype == "nofile"
                end,
            },
            indent = { enable = true },
        })

        -- nvim-treesitter markdown fence injection: match[id] is sometimes not a
        -- TSNode (table / stale). get_node_text then does node:range() and E5108 spam.
        pcall(vim.treesitter.query.add_directive, "set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
            local node = match[pred[2]]
            if type(node) == "table" and type(node.range) ~= "function" then
                node = node[1] or node.node
            end
            if type(node) ~= "userdata" and type(node) ~= "table" then
                return
            end
            if type(node.range) ~= "function" then
                return
            end
            local ok, text = pcall(vim.treesitter.get_node_text, node, bufnr)
            if not ok or type(text) ~= "string" then
                return
            end
            text = text:lower()
            local lang = vim.filetype.match({ filename = "a." .. text }) or text
            metadata["injection.language"] = lang
        end, { force = true, all = false })
    end
}

