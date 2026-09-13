return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      setup = {
        ltex = function() return true end,
        ltex_plus = function() return true end,
      },
    },
  },
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.markdown = {}
      return opts
    end,
  },
}
