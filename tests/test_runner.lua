-- mini.test を読み込みます
local MiniTest = require("mini.test")

local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local my_yank = require("my_yank")
local runner = require("my_yank.runner")

-- ★ runner 用のテスト preset を登録する関数
local function setup_my_yank_for_runner()
	if vim.g._my_yank_runner_test_setup_done then
		return
	end
	vim.g._my_yank_runner_test_setup_done = true

	my_yank.setup({
		presets = {
			buffer_to_codeblock = {
				source = "buffer",
				transforms = {
					{ "codeblock", lang = "lua" },
				},
				sinks = {},
			},
			copy_buffer_codeblock = {
				source = "buffer",
				transforms = {
					{ "codeblock", lang = "lua" },
				},
				sinks = {},
			},
		},
	})
end

local TestRunner = new_set()

TestRunner["run() returns a table (buffer_to_codeblock)"] = function()
	-- ★ 各テストの最初で setup を呼ぶ
	setup_my_yank_for_runner()

	vim.cmd("new")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, {
		"print('hello')",
	})

	local result = runner.run("buffer_to_codeblock")

	eq(type(result), "table")
	-- 現状仕様では要素数 0 であることだけ確認
	eq(#result, 0)
end

TestRunner["run() returns a table (copy_buffer_codeblock)"] = function()
	setup_my_yank_for_runner()

	vim.cmd("new")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, {
		"print('source')",
	})

	local result = runner.run("copy_buffer_codeblock")

	eq(type(result), "table")
	eq(#result, 0)
end

return TestRunner
