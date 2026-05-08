return {
  "prettier/vim-prettier",
  build = "npm install --frozen-lockfile --production",
  ft = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "json",
    "jsonc",
    "css",
    "scss",
    "less",
    "html",
    "markdown",
    "yaml",
    "graphql",
  },
  config = function()
    -- Use project-local Prettier config automatically
    vim.g["prettier#autoformat"] = 1             -- enable autoformat
    vim.g["prettier#autoformat_require_pragma"] = 0  -- ignore pragma
    vim.g["prettier#exec_cmd_path_node"] = ""    -- use project Node
    vim.g["prettier#config#use_local_config"] = 1 -- use local prettier config

    -- Optional: keymap to manually format
    vim.keymap.set("n", "<leader>p", ":Prettier<CR>", { silent = true })

    -- Autoformat on save
    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*.{js,jsx,ts,tsx,json,css,scss,less,html,md,yaml,yml,graphql}",
      command = "Prettier",
    })
  end,
}
