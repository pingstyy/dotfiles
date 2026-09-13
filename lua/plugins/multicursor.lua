-- Multi-cursor for non-contiguous line edits (VSCode-style).
return {
  'jake-stewart/multicursor.nvim',
  branch = '1.0',
  event = 'VeryLazy',
  config = function()
    local mc = require('multicursor-nvim')
    mc.setup()

    local set = vim.keymap.set

    -- Add cursor on line above/below (skip continuous block selection).
    -- Option+Ctrl+j/k — works in terminal; Cmd variants often swallowed on Mac.
    set({ 'n', 'x' }, '<M-C-j>', function()
      mc.lineAddCursor(1)
    end, { desc = 'Multi-cursor: add below' })
    set({ 'n', 'x' }, '<M-C-k>', function()
      mc.lineAddCursor(-1)
    end, { desc = 'Multi-cursor: add above' })
    set({ 'n', 'x' }, '<D-M-j>', function()
      mc.lineAddCursor(1)
    end, { desc = 'Multi-cursor: add below (Cmd)' })
    set({ 'n', 'x' }, '<D-M-k>', function()
      mc.lineAddCursor(-1)
    end, { desc = 'Multi-cursor: add above (Cmd)' })

    -- Skip a line when building multi-cursors.
    set({ 'n', 'x' }, '<M-C-S-j>', function()
      mc.lineSkipCursor(1)
    end, { desc = 'Multi-cursor: skip below' })
    set({ 'n', 'x' }, '<M-C-S-k>', function()
      mc.lineSkipCursor(-1)
    end, { desc = 'Multi-cursor: skip above' })

    -- VSCode-ish: add next match of word/selection (like Cmd+D).
    set({ 'n', 'x' }, '<D-d>', function()
      mc.matchAddCursor(1)
    end, { desc = 'Multi-cursor: next match' })
    set({ 'n', 'x' }, '<M-d>', function()
      mc.matchAddCursor(1)
    end, { desc = 'Multi-cursor: next match (Option)' })
    set({ 'n', 'x' }, '<D-S-d>', function()
      mc.matchSkipCursor(1)
    end, { desc = 'Multi-cursor: skip match' })

    -- Visual: put a cursor on every selected line (non-contiguous edits after).
    set({ 'n', 'x' }, 'ga', mc.addCursorOperator, { desc = 'Multi-cursor: operator / each line' })

    -- Visual block-like insert/append on every selected line.
    set('x', 'I', mc.insertVisual, { desc = 'Multi-cursor: insert at line starts' })
    set('x', 'A', mc.appendVisual, { desc = 'Multi-cursor: append at line ends' })

    -- Mouse: Ctrl-click to add/remove cursors.
    set('n', '<c-leftmouse>', mc.handleMouse)
    set('n', '<c-leftdrag>', mc.handleMouseDrag)
    set('n', '<c-leftrelease>', mc.handleMouseRelease)

    -- Toggle main-only vs all cursors.
    set({ 'n', 'x' }, '<C-q>', mc.toggleCursor, { desc = 'Multi-cursor: toggle' })

    mc.addKeymapLayer(function(layerSet)
      layerSet({ 'n', 'x' }, '<left>', mc.prevCursor)
      layerSet({ 'n', 'x' }, '<right>', mc.nextCursor)
      layerSet({ 'n', 'x' }, '<leader>x', mc.deleteCursor)
      layerSet('n', '<esc>', function()
        if not mc.cursorsEnabled() then
          mc.enableCursors()
        else
          mc.clearCursors()
        end
      end)
    end)

    local hl = vim.api.nvim_set_hl
    hl(0, 'MultiCursorCursor', { reverse = true })
    hl(0, 'MultiCursorVisual', { link = 'Visual' })
    hl(0, 'MultiCursorSign', { link = 'SignColumn' })
    hl(0, 'MultiCursorMatchPreview', { link = 'Search' })
    hl(0, 'MultiCursorDisabledCursor', { reverse = true })
    hl(0, 'MultiCursorDisabledVisual', { link = 'Visual' })
    hl(0, 'MultiCursorDisabledSign', { link = 'SignColumn' })
  end,
}
