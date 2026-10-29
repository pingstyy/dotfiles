return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local harpoon = require("harpoon")
        harpoon:setup({
            settings = {
                save_on_toggle = true,
            },
        })

        local function list()
            return harpoon:list()
        end

        local function menu()
            local hlist = list()
            local n = math.max(hlist:length(), 1)
            local cap = math.max(1, vim.o.lines - 6)
            harpoon.ui:toggle_quick_menu(hlist, {
                height_in_lines = math.min(n, cap),
                title = "Harpoon (" .. hlist:length() .. ")",
            })
        end

        vim.keymap.set("n", "<leader>ha", function()
            local hlist = list()
            local before = hlist:length()
            hlist:add()
            local after = hlist:length()
            if after == before then
                vim.notify("Already in Harpoon (" .. after .. ")")
            else
                vim.notify("Harpoon " .. after)
            end
        end, { desc = "Harpoon add" })

        local function index_of_current(hlist)
            local bufname = vim.api.nvim_buf_get_name(0)
            local rel = vim.fn.fnamemodify(bufname, ":.")
            for i = 1, hlist:length() do
                local item = hlist:get(i)
                if item and (item.value == bufname or item.value == rel) then
                    return i
                end
            end
        end

        local function step(delta)
            local hlist = list()
            local n = hlist:length()
            if n == 0 then
                vim.notify("Harpoon list is empty", vim.log.levels.WARN)
                return
            end
            local idx = index_of_current(hlist)
            local nxt
            if not idx then
                nxt = delta > 0 and 1 or n
            else
                nxt = idx + delta
                if nxt > n then
                    nxt = 1
                elseif nxt < 1 then
                    nxt = n
                end
            end
            hlist._index = nxt
            hlist:select(nxt)
        end

        vim.keymap.set("n", "<leader>he", menu, { desc = "Harpoon menu" })
        vim.keymap.set("n", "<leader>hn", function() step(1) end, { desc = "Harpoon next" })
        vim.keymap.set("n", "<leader>hp", function() step(-1) end, { desc = "Harpoon prev" })

        for i = 1, 4 do
            vim.keymap.set("n", "<leader>" .. i, function()
                list():select(i)
            end, { desc = "Harpoon " .. i })
        end

        local modes = { "n", "i", "v" }
        for i = 1, 9 do
            vim.keymap.set(modes, "<D-" .. i .. ">", function()
                list():select(i)
            end, { desc = "Harpoon " .. i, silent = true })
        end
        vim.keymap.set(modes, "<D-0>", function()
            list():select(10)
        end, { desc = "Harpoon 10", silent = true })

        vim.keymap.set("n", "<C-y>", function() list():select(1) end, { desc = "Harpoon 1" })
        vim.keymap.set("n", "<C-t>", function() list():select(2) end, { desc = "Harpoon 2" })
        vim.keymap.set("n", "<C-n>", function() list():select(3) end, { desc = "Harpoon 3" })
    end,
}
