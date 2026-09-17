-- Prefer Snacks explorer / Oil over netrw (avoids Ex replacing buffers & split weirdness)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1



require("sp4ss.ui")
require("sp4ss.ide")
require("sp4ss.remap")
require("sp4ss.lazy")
require("sp4ss.config")
require("sp4ss.python_env").setup()
require("sp4ss.runner").setup()
require("sp4ss.tabs").setup()
require("sp4ss.noleader").setup()

-- Save undo history to a file so it persists after closing Neovim
vim.opt.undofile = true

