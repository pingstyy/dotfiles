local autosave_group = vim.api.nvim_create_augroup("Autosave", { clear = true })

vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
    group = autosave_group,
    callback = function()
        if vim.bo.modified and vim.bo.buftype == "" then
            vim.cmd("silent! write")
        end
    end,
})

