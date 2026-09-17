-- ~/.config/nvim/lua/plugins/mini-diff.lua
return {
  'nvim-mini/mini.diff',
  version = false,
  config = function()
    require('mini.diff').setup({
      view = {
        style = 'sign', -- keeps your #f54814 current line color, not number style
        signs = { add = '▎', change = '▎', delete = '▁' },
        priority = 199,
      },
      source = nil, -- default git
      delay = { text_change = 200 },
      mappings = {
        apply = 'gh',
        reset = 'gH',
        textobject = 'gh',
        goto_first = '[H',
        goto_prev = '[h',
        goto_next = ']h',
        goto_last = ']H',
      },
    })
  end,
  keys = {
    { "<leader>gd", function() require('mini.diff').toggle_overlay(0) end, desc = "Diff overlay toggle" },
    { "<leader>gt", function()
        local buf = vim.api.nvim_get_current_buf()
        if vim.b[buf].minidiff_disable then
          require('mini.diff').enable(buf)
        else
          require('mini.diff').disable(buf)
        end
      end, desc = "Diff toggle ON/OFF" },
  }
}
