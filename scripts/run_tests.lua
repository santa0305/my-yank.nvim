-- my-yank.nvim プロジェクトローカルの mini.test 実行スクリプト

local mt = require("mini.test")

mt.setup({
	collect = {
		emulate_busted = true,
		find_files = function()
			-- このリポジトリ内の tests/test_*.lua を全部拾う
			return vim.fn.globpath("tests", "test_*.lua", true, true)
		end,
	},
})

mt.run()
