return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      -- A list of parser names, or "all"
      ensure_installed = {
        "json", "javascript", "typescript", "tsx", "yaml", "html", "css",
        "c", "cpp", "go",
        "csv", "diff", "xml", "mermaid",
        "markdown", "markdown_inline", "bash",
        "lua", "vim", "dockerfile", "gitignore",
      },

      -- Install parsers synchronously (only applied to `ensure_installed`)
      sync_install = false,

      -- Automatically install missing parsers when entering a buffer
      auto_install = true,

      highlight = {
        enable = true,
        additional_vim_regex_highlighting = {"markdown"},
      },

      indent = { enable = true },
    })
  end,
}
