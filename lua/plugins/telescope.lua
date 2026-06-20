return {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
        local status, telescope = pcall(require, "telescope")
        if not status then return end

        telescope.setup({
            defaults = {
                vimgrep_arguments = {
                    "rg", "--color=never", "--no-heading", "--with-filename",
                    "--line-number", "--column", "--smart-case", "--trim"
                },
            }
        })
    end
}

