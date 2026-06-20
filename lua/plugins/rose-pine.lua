return {
    "rose-pine/neovim",
    name = "rose-pine",
    config = function()
        require("rose-pine").setup({
            variant = "main",      -- main, moon, or dawn
            dark_variant = "main", -- main, moon, or dawn
            styles = {
                bold = true,
                italic = true,
                transparency = true, -- [ENABLES TRANSPARENCY]
            },
        })

        -- To switch to Rose Pine, uncomment the line below:
        -- vim.cmd("colorscheme rose-pine")
    end
}

