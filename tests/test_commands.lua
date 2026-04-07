local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local my_yank = require("my_yank")
local runner = require("my_yank.runner")

-- ★ このファイル内でだけ使う setup 関数
local function setup_my_yank_for_commands()
	-- すでにセットアップ済みなら何もしない（テスト間で二重初期化を避ける）
	if vim.g._my_yank_commands_test_setup_done then
		return
	end
	vim.g._my_yank_commands_test_setup_done = true

	my_yank.setup({
		presets = {
			test_preset = {
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
			copy_path = {
				source = "filepath",
				transforms = {},
				sinks = {},
			},
		},
	})
end

-- このファイルのテストセット
local TestCommands = new_set()

TestCommands[":MyYank is defined"] = function()
	-- ★ 各テストの先頭で必ず setup を呼ぶ
	setup_my_yank_for_commands()

	local commands = vim.api.nvim_get_commands({})

	eq(commands["MyYank"] ~= nil, true)
end

TestCommands[":MyYank executes preset without error"] = function()
	setup_my_yank_for_commands()

	vim.cmd("new")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, {
		"print('cmd test')",
	})

	local called = 0
	local original_run = runner.run

	runner.run = function(name_or_spec)
		called = called + 1
		return original_run(name_or_spec)
	end

	vim.cmd("MyYank test_preset")

	runner.run = original_run

	eq(called > 0, true)
end

return TestCommands
