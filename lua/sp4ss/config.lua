vim.o.number = true
vim.o.relativenumber = true
vim.o.numberwidth = 1
vim.o.signcolumn = "yes:1"
vim.o.foldcolumn = "0"
vim.o.cursorline = true
vim.o.cursorlineopt = "number"
-- ultra squeezed: number at left edge + gutter, no spaces, no right-align
vim.o.statuscolumn = "%{v:relnum?v:relnum:v:lnum}%s"
vim.o.timeoutlen = 200
vim.o.ttimeoutlen = 10

local function set_colors()
  vim.api.nvim_set_hl(0, "LineNr", { fg="#8B7355", bg="NONE" })
  vim.api.nvim_set_hl(0, "LineNrAbove", { fg="#8B7355", bg="NONE" })
  vim.api.nvim_set_hl(0, "LineNrBelow", { fg="#8B7355", bg="NONE" })
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg="#f54814", bg="NONE", bold=true })
end
set_colors()
vim.api.nvim_create_autocmd("ColorScheme", {callback=set_colors})
