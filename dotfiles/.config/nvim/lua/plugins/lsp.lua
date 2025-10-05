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
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Configure servers using new vim.lsp.config API
      vim.lsp.config('lua_ls', {
        capabilities = capabilities
      })
      
      vim.lsp.config('marksman', {
        capabilities = capabilities
      })

      -- Enable the configured servers
      vim.lsp.enable({'lua_ls', 'marksman'})
    end
  }
}

