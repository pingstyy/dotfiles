-- ~/.config/nvim/lua/plugins/trouble.lua
return {
  "folke/trouble.nvim",
  cmd = "Trouble",
  opts = {
    auto_close = false,
    auto_open = false,
    focus = false,
    follow = true,
    indent_guides = true,
    warn_no_results = true,
  },
  keys = {
    { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble) toggle" },
    { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics toggle" },
    { "<leader>xs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols toggle" },
    { "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Loclist toggle" },
    { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix toggle" },
    { "<leader>xt", "<cmd>Trouble close<cr>", desc = "Trouble OFF / Close" },
    { "q", "<cmd>Trouble close<cr>", desc = "Trouble close", ft = "trouble" },
  }
}
