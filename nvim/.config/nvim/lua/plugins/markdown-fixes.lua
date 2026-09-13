return {
  -- ltex (yazım denetimi) sunucusunu devre dışı bırakıyoruz
  {
    "neovim/nvim-lspconfig",
    opts = {
      setup = {
        ltex = function()
          return true -- ltex lsp'sinin başlatılmasını engeller
        end,
        ltex_plus = function()
          return true
        end,
      },
    },
  },
  -- nvim-lint için markdown üzerinde çalışan linter'ları (markdownlint dahil) temizliyoruz
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        -- markdown dosyaları için hiçbir linter çalıştırma
        markdown = {},
      },
    },
  },
}
