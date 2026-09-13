return {
    { 
        "folke/tokyonight.nvim", 
        lazy = false,
        priority = 10,
	opts = {
	    style = "night",    -- You can also use "storm", "moon", or "day"
	    transparent = true, -- [THIS ENABLES TRANSPARENCY]
	    styles = {
	      sidebars = "transparent", -- folder explorer, etc.
	      floats = "transparent",   -- popups, etc.
	    },
	    on_highlights = function(hl, c)
            -- Makes the line your cursor is on transparent
            hl.CursorLine = { bg = "NONE" }
            -- Current line number stands out (snacks statuscolumn uses these groups).
            hl.CursorLineNr = { fg = "#e0af68", bold = true }
            hl.LineNr = { fg = c.fg_gutter }

            -- Makes the "Visual Mode" selection semi-transparent/subtle
            -- Note: In terminal, we usually just make the background slightly different
            hl.Visual = { bg = "#2f334d" } -- Change this hex code to adjust the "intensity" of the highlight

            -- Light bg for same-word / LSP reference highlights (VS Code-like)
            hl.LspReferenceText = { bg = c.fg_gutter }
            hl.LspReferenceRead = { bg = c.fg_gutter }
            hl.LspReferenceWrite = { bg = c.fg_gutter }
            hl.Sp4ssCursorWord = { bg = c.fg_gutter }

            -- Tiny file banner — needs a real bg or it vanishes on transparent
            hl.TabLine = { bg = "#1a1b26", fg = "#787c99" }
            hl.TabLineSel = { bg = "#2f334d", fg = "#e0af68", bold = true }
            hl.TabLineFill = { bg = "#16161e" }
        end,
    },

}
}
