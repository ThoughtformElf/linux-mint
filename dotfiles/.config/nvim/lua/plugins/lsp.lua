return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = { "lua_ls", "marksman" } -- Add servers for lua and markdown
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Setup for lua
      lspconfig.lua_ls.setup({
        capabilities = capabilities
      })
      -- Setup for markdown
      lspconfig.marksman.setup({
        capabilities = capabilities
      })
    end
  }
}
