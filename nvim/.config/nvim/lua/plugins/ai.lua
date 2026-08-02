-- claudecode.nvim comes from lazyvim.plugins.extras.ai.claudecode, which leaves
-- opts empty. The plugin speaks the same IDE protocol as the VS Code extension,
-- so the `claude` started from inside Neovim sees the active buffer and the
-- visual selection by itself — what is set here is only how it is displayed.
return {
  {
    "coder/claudecode.nvim",
    opts = {
      -- Jump into the terminal after sending a selection, so the question can
      -- be typed straight away instead of reaching for <leader>af first.
      focus_after_send = true,
      terminal = {
        provider = "snacks",
        split_side = "right",
        split_width_percentage = 0.35,
      },
      -- The diff Claude writes opens side by side; <leader>aa accepts it.
      diff_opts = { layout = "vertical" },
    },
    -- stylua: ignore
    keys = {
      { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
      { "<leader>aS", "<cmd>ClaudeCodeStatus<cr>", desc = "Claude connection status" },
    },
  },
}
