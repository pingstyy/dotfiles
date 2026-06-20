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
            highlight = { enable = true },
            indent = { enable = true },
        })
    end
}

