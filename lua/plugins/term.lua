return {
  'akinsho/toggleterm.nvim',
  version = "*",
  opts = {
    -- Free interactive shell (float). File runner uses a separate vertical split.
    open_mapping = [[<c-\>]],
    direction = 'float',
    float_opts = { border = 'single' },
    start_in_insert = true,
    persist_mode = false,
    -- Runner overrides this; keep vertical ~30% so a fallback is not a fat pane.
    size = function(term)
      if term.direction == 'horizontal' then
        return 12
      elseif term.direction == 'vertical' then
        return math.max(28, math.floor(vim.o.columns * 0.30))
      end
      return 20
    end,
  },
}
