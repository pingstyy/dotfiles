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
            
            -- Makes the "Visual Mode" selection semi-transparent/subtle
            -- Note: In terminal, we usually just make the background slightly different
            hl.Visual = { bg = "#2f334d" } -- Change this hex code to adjust the "intensity" of the highlight
        end,
    },

}
}
