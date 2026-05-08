return {
  'neovim/nvim-lspconfig',
  opts = {
    inlay_hints = { enabled = true },
  },
  config = function()
    local lspconfig = require('lspconfig')

    lspconfig.pylsp.setup({})
    -- lspconfig.pyright.setup({})
    lspconfig.crystalline.setup({})
    lspconfig.terraformls.setup({})
  end
}
