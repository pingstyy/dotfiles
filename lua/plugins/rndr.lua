return {
  dir = "~/.config/nvim/rndr.nvim",
  config = function()
    require("rndr").setup({
      preview = {
        auto_open = true,
        events = { "BufReadPost" },
        render_on_resize = true,
      },
      hover = {
        enabled = true,
        min_width = 20,
        max_width = 80,
        min_height = 10,
        max_height = 30,
      },
      assets = {
        images = { "png", "jpg", "jpeg", "gif", "bmp", "webp" },
        vectors = { "svg", "svgz" },
        models = { "obj", "fbx", "glb", "gltf", "dae", "blend", "ply", "stl" },
      },
      window = {
        termguicolors = true,
        size = {
          width_offset = 0,
          height_offset = 0,
          min_width = 1,
          min_height = 1,
        },
        options = {
          number = false,
          relativenumber = false,
          wrap = false,
          signcolumn = "no",
        },
      },
      renderer = {
        supersample = 2,
        brightness = 1.0,
        saturation = 1.18,
        contrast = 1.08,
        gamma = 0.92,
        background = "0d0f14",
      },
      controls = {
        rotate_step = 15,
        keymaps = {
          close = "q",
          rerender = "R",
          reset_view = "0",
          rotate_left = "h",
          rotate_right = "l",
          rotate_up = "k",
          rotate_down = "j",
        },
      },
    })
  end,
}
