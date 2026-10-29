return {
  'isakbm/gitgraph.nvim',
  dependencies = { 'sindrets/diffview.nvim' },
  opts = {
    symbols = {
      merge_commit = 'M',
      commit = '*',
    },
    format = {
      timestamp = '%H:%M:%S %d-%m-%Y',
      fields = { 'hash', 'timestamp', 'author', 'branch_name', 'tag' },
    },
    hooks = {
      -- <Enter> on commit = diffview
      on_select_commit = function(commit)
        vim.notify('DiffviewOpen '.. commit.hash.. '^!')
        vim.cmd(':DiffviewOpen '.. commit.hash.. '^!')
      end,
      -- Visual range + <Enter> = range diff
      on_select_range_commit = function(from, to)
        vim.notify('DiffviewOpen '.. from.hash.. '~1..'.. to.hash)
        vim.cmd(':DiffviewOpen '.. from.hash.. '~1..'.. to.hash)
      end,
    },
  },
  keys = {
    -- <leader>gg is lazygit. <leader>gl is Snacks git log. Do not take those.
    -- g is not a noleader prefix, so these stay Space g … (gv/gq stay builtin).
    {
      "<leader>gA",
      function() require('gitgraph').draw({}, { all = true, max_count = 5000 }) end,
      desc = "GitGraph - all branches",
    },
    {
      "<leader>gG",
      function() require('gitgraph').draw({}, { all = false, max_count = 5000 }) end,
      desc = "GitGraph - current branch",
    },
    {
      "<leader>gv",
      function() vim.cmd("DiffviewOpen") end,
      desc = "Diff working tree",
    },
    {
      "<leader>gC",
      function() vim.cmd("DiffviewFileHistory %") end,
      desc = "Diff this file across commits",
    },
    {
      "<leader>gV",
      function()
        vim.ui.input({ prompt = "Commit range (base..head): " }, function(input)
          if input == nil or input == "" then
            return
          end
          if not input:match("^[%w%./_%-^~@]+%.%.[%w%./_%-^~@]+$") then
            vim.notify("Use base..head, for example HEAD~3..HEAD", vim.log.levels.WARN)
            return
          end
          vim.cmd("DiffviewOpen " .. input)
        end)
      end,
      desc = "Diff between two commits",
    },
    {
      "<leader>gq",
      "<cmd>DiffviewClose<cr>",
      desc = "Close diff view",
    },
  },
}
