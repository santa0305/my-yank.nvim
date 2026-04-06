local MiniTest = require("mini.test")

MiniTest.setup({
	collect = {
		emulate_busted = true,
		-- FILE が指定されていないときだけ「tests 配下全部」を探す
		find_files = function()
			local file = vim.env.FILE
			if file and file ~= "" then
				-- 特定ファイルだけを返す
				return { file }
			end
			-- いつもの: tests 配下の test_*.lua を全部
			return vim.fn.globpath("tests", "test_*.lua", true, true)
		end,
	},
})

MiniTest.run()
