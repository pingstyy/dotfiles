return {
  "3rd/image.nvim",
  build = false, -- prevents lazy from trying to compile the rock binary manually
  opts = {
    processor = "magick_cli", -- Uses your system's ImageMagick CLI directly
    backend = "kitty",        -- Change to "ueberzug" or "sixel" if not using Kitty terminal
    integrations = {
      markdown = {
        enabled = true,
        clear_in_insert_mode = false,
        download_remote_images = true,
        only_render_image_at_cursor = true, -- Highly recommended in tmux to prevent ghosting bugs
        floating_windows = false,
        filetypes = { "markdown", "vimwiki" },
      },
    },
    max_width = nil,
    max_height = nil,
    max_width_window_percentage = nil,
    max_height_window_percentage = 50,
    window_overlap_clear_enabled = true, -- Clears images if an nvim float/popup covers them
    window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "Directive" },
  },
}
