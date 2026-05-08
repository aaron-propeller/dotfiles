return {
  'nvim-treesitter/nvim-treesitter',
  dependencies = { "RRethy/nvim-treesitter-endwise" },
  config = function() 
    require('nvim-treesitter.config').setup({
      ensure_installed = { "c", "lua", "vim", "vimdoc", "query", 'typescript' },
      auto_install = true,
      endwise = {
        enable = true,
      },
    })
  end
}
