return {
  -- ltex (yazım denetimi) sunucusunu devre dışı bırakıyoruz
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.setup = opts.setup or {}
      opts.setup.ltex = function()
        return true -- ltex lsp'sinin başlatılmasını engeller
      end
      opts.setup.ltex_plus = function()
        return true
      end
    end,
  },
  -- nvim-lint için markdown üzerinde çalışan linter'ları (markdownlint dahil) temizliyoruz
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      -- markdown dosyaları için hiçbir linter çalıştırma (lazy.nvim'in array'leri merge etmesini önlüyoruz)
      opts.linters_by_ft.markdown = {}
    end,
  },
}
