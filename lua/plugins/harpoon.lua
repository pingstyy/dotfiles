return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local harpoon = require("harpoon")
        
        -- Crucial: This MUST happen before any keymaps try to call it
        harpoon:setup({})

        -- 1. Add File to List
        vim.keymap.set("n", "<leader>ha", function() 
            harpoon:list():add() 
            print("Added file to Harpoon!") -- This will confirm it's working
        end, { desc = "Harpoon Add" })

        -- 2. Open UI Toggle Menu
        vim.keymap.set("n", "<leader>he", function()
            harpoon.ui:toggle_quick_menu(harpoon:list())
        end, { desc = "Harpoon Menu" })

        -- 3. File Selection Keys
        vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end)
        vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end)
        vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end)
        vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end)
    end
}
