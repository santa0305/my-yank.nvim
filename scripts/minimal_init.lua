-- プロジェクト自身を runtimepath に追加
-- vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.opt.runtimepath:prepend(".")

-- mini.nvim を runtimepath に追加（lazy.nvim の実際のパス）
vim.opt.runtimepath:append(vim.fn.stdpath("data") .. "/lazy/mini.nvim")

-- mini.test を初期化
require("mini.test").setup()
