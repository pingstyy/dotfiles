-- Add a hover shortcut to preview any file path under the cursor
vim.keymap.set("n", "K", function()
    -- 1. Grab the string/filepath directly under the cursor
    local filepath = vim.fn.expand("<cfile>")

    -- 2. Clean it up if it uses common Markdown syntax like ![](path) or [[path]]
    filepath = filepath:gsub("^!%[.-%]%(", ""):gsub("%)$", "")
    filepath = filepath:gsub("^%[%[", ""):gsub("%]%]$", "")

    -- 3. Check if the file actually exists locally
    if vim.fn.filereadable(filepath) == 1 then
        -- Open it using rndr's path command
        vim.cmd("RndrOpen " .. filepath)
    else
        -- Fall back to default LSP hover behavior if it's not a local file path
        local lsp_has_hover = false
        for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
            if client.supports_method("textDocument/hover") then
                lsp_has_hover = true
                break
            end
        end

        if lsp_has_hover then
            vim.lsp.buf.hover()
        else
            print("No local file found at: " .. filepath)
        end
    end
end, { desc = "Rndr Hover Preview / LSP Hover" })
