-- ~/.config/nvim/lua/plugins/gitsigns.lua
return {
  'lewis6991/gitsigns.nvim',
  opts = {
    signcolumn = true,
    signs = {
      add = { text = '▎' },
      change = { text = '▎' },
      delete = { text = '▁' },
      topdelete = { text = '▔' },
      changedelete = { text = '▎' },
      untracked = { text = '▎' },
    },
    signs_staged_enable = false,
  }
}
