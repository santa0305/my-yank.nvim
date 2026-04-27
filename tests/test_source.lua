local MiniTest = require("mini.test")
local new_set = MiniTest.new_set
local eq = MiniTest.expect.equality

local source = require("my_yank.source")

local TestSource = new_set()

TestSource["terminal_block() supports prompt lines beginning with box-drawing corner"] = function()
	vim.cmd("enew!")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, {
		"user@host",
		"workspace info",
		"╰─ pwsh -NoLogo",
		"PowerShell 7.5.0",
		"Get-Location",
		"Path",
		"----",
		"C:\\Users\\santa",
		"user@host",
		"workspace info",
		"╰─ Get-ChildItem",
		"README.md",
		"lua",
	})
	vim.api.nvim_win_set_cursor(0, { 5, 0 })

	local result = source.terminal_block({ bufnr = 0 })

	eq(result.metadata.range.start_row, 3)
	eq(result.metadata.range.end_row, 9)
	eq(result.lines, "╰─ pwsh -NoLogo")[1]
	eq(result.lines[#result.lines], "workspace info")
	eq(result.metadata.prompt_patterns, "^%s*PS>")[1]
end

TestSource["terminal_block() supports other default prompt candidates"] = function()
	vim.cmd("enew!")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, {
		"root meta",
		"container info",
		"# uname -a",
		"Linux test-host 6.6.0",
		"root meta",
		"container info",
		"# exit",
	})
	vim.api.nvim_win_set_cursor(0, { 4, 0 })

	local result = source.terminal_block({ bufnr = 0 })

	eq(result.metadata.range.start_row, 3)
	eq(result.metadata.range.end_row, 4)
	eq(result.lines, "# uname -a")[1]
	eq(result.lines[#result.lines], "Linux test-host 6.6.0")
end

TestSource["terminal_block() supports user-defined prompt_patterns"] = function()
	vim.cmd("enew!")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, {
		"prompt meta 1",
		"prompt meta 2",
		">>> python",
		"print('hello')",
		"hello",
		"prompt meta 3",
		"prompt meta 4",
		">>> exit()",
	})
	vim.api.nvim_win_set_cursor(0, { 4, 0 })

	local result = source.terminal_block({
		bufnr = 0,
		prompt_patterns = {
			"^%s*>>>",
		},
	})

	eq(result.metadata.range.start_row, 3)
	eq(result.metadata.range.end_row, 5)
	eq(result.lines, ">>> python")[1]
	eq(result.lines[#result.lines], "hello")
	eq(result.metadata.prompt_patterns[#result.metadata.prompt_patterns], "^%s*>>>")
end

return TestSource
