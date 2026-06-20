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

-- 1. Strip Neovim's UI background colors so it's transparent inside
local clear_bg = function()
    vim.cmd([[
    highlight Normal guibg=none ctermbg=none
    highlight NormalNC guibg=none ctermbg=none
    highlight NonText guibg=none ctermbg=none
    highlight SignColumn guibg=none ctermbg=none
    highlight StatusLine guibg=none ctermbg=none
    highlight NeoTreeNormal guibg=none ctermbg=none
  ]])
end

clear_bg()

-- 2. Dynamically swap Ghostty's wallpaper when Neovim opens/closes
local image_path = vim.fn.expand("$HOME/.config/nvim/assets/logo-bg.jpg")

vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        -- Set background image and set opacity tint so text is readable
        vim.fn.system("ghostty +config background-image=" .. image_path)
        vim.fn.system("ghostty +config background-image-opacity=0.25")
        clear_bg()
    end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        -- Reset Ghostty back to your standard clean shell color when you exit Neovim
        vim.fn.system("ghostty +config background-image=")
    end,
})
