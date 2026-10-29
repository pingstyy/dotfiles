return {
  "stevearc/overseer.nvim",
  cmd = {
    "OverseerRun",
    "OverseerToggle",
    "OverseerShell",
    "OverseerTaskAction",
    "OverseerRestartLast",
  },
  keys = {
    { "<leader>or", "<cmd>OverseerRun<cr>", desc = "Overseer: run task" },
    { "<leader>ol", "<cmd>OverseerRestartLast<cr>", desc = "Overseer: restart last" },
    { "<leader>ot", "<cmd>OverseerToggle<cr>", desc = "Overseer: toggle task list" },
    { "<leader>oa", "<cmd>OverseerTaskAction<cr>", desc = "Overseer: task action" },
    { "<leader>os", "<cmd>OverseerShell<cr>", desc = "Overseer: shell command" },
  },
  opts = {
    task_list = {
      direction = "bottom",
    },
  },
  config = function(_, opts)
    local overseer = require("overseer")
    overseer.setup(opts)

    vim.api.nvim_create_user_command("OverseerRestartLast", function()
      local tasks = overseer.list_tasks({
        status = {
          overseer.STATUS.SUCCESS,
          overseer.STATUS.FAILURE,
          overseer.STATUS.CANCELED,
        },
        sort = require("overseer.task_list").sort_finished_recently,
      })
      if vim.tbl_isempty(tasks) then
        vim.notify("No finished Overseer tasks", vim.log.levels.WARN)
        return
      end
      overseer.run_action(tasks[1], "restart")
    end, { desc = "Restart the most recent finished Overseer task" })
  end,
}
