-- General configuration options for Neovim
-- Numbers live on the focused pane only. Space ul flips this master switch.
vim.g.sp4ss_line_numbers = true
vim.opt.number = false
vim.opt.relativenumber = false

local function apply_win_numbers()
    local master = vim.g.sp4ss_line_numbers ~= false
    local cur = vim.api.nvim_get_current_win()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) then
            local cfg = vim.api.nvim_win_get_config(win)
            if cfg.relative == "" then
                local show = master and win == cur
                if show then
                    local bt = vim.bo[vim.api.nvim_win_get_buf(win)].buftype
                    -- editor panes only (skip term / explorer / float leftovers)
                    show = bt == ""
                end
                vim.wo[win].number = show
                vim.wo[win].relativenumber = show
            end
        end
    end
end

local num_grp = vim.api.nvim_create_augroup("sp4ss_win_numbers", { clear = true })
vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "VimEnter" }, {
    group = num_grp,
    callback = apply_win_numbers,
})
vim.api.nvim_create_autocmd("User", {
    group = num_grp,
    pattern = "Sp4ssLineNumbers",
    callback = apply_win_numbers,
})
apply_win_numbers()

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50


