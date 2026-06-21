return {
    "HakonHarnes/img-clip.nvim",
    event = "VeryLazy",
    opts = {
        default = {
            -- Where to save the files (relative to the current file)
            dir_path = "assets",

            -- Extension to use when pulling from clipboard
            extension = "png",

            -- This triggers a prompt asking you to name the file every time you paste!
            prompt_for_file_name = true,

            -- Markdown template for inserting the link
            template = "![[$FILE_PATH]]",
        },
        -- Filetype specific overrides if needed
        filetypes = {
            markdown = {
                url_encode_path = true,
                template = "![$LABEL]($FILE_PATH)",
            },
        },
    },
    keys = {
        -- Press <leader>p to paste the image from your clipboard
        { "<leader>p", "<cmd>PasteImage<cr>", desc = "Paste clipboard image" },
    },
}
