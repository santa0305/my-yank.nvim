-- mini.test を読み込みます
local MiniTest = require("mini.test")

-- テストセットを作るための関数です
local new_set = MiniTest.new_set

-- 値が等しいかを確認する関数です
local eq = MiniTest.expect.equality

-- util モジュール本体を読み込みます
local util = require("my_yank.util")

-- このファイルのテストセットを作成します
local TestUtil = new_set()

-- bufnr() が 0 や nil のときに「現在のバッファ番号」に解決されることをテストします
TestUtil["bufnr() resolves 0 or nil to current buffer"] = function()
	-- 現在のバッファ番号（数値）を取得します
	local cur = vim.api.nvim_get_current_buf()

	-- nil の場合
	eq(type(util.bufnr(nil)), "number")
	eq(util.bufnr(nil), cur)

	-- 0 の場合
	eq(type(util.bufnr(0)), "number")
	eq(util.bufnr(0), cur)

	-- 通常の番号の場合
	eq(util.bufnr(cur), cur)
end

-- normalize_step() が文字列やテーブルを正しい形式に変換することをテストします
TestUtil["normalize_step() normalizes string and table steps"] = function()
	-- 文字列の場合
	local s1 = util.normalize_step("codeblock")
	eq(s1.name, "codeblock")
	eq(type(s1.opts), "table")

	-- テーブルで name 指定の場合
	local s2 = util.normalize_step({ name = "trim", keep_indent = true })
	eq(s2.name, "trim")
	eq(s2.opts.keep_indent, true)

	-- テーブルで位置引数（[1]）の場合
	local s3 = util.normalize_step({ "join", sep = ", " })
	eq(s3.name, "join")
	eq(s3.opts.sep, ", ")
end

-- normalize_steps() が複数ステップをまとめて変換できるかをテストします
TestUtil["normalize_steps() maps all steps through normalize_step()"] = function()
	local steps = { "trim", { "join", sep = " " } }
	local normalized = util.normalize_steps(steps)

	eq(#normalized, 2)
	eq(normalized[1].name, "trim")
	eq(normalized[2].name, "join")
	eq(normalized[2].opts.sep, " ")
end

-- resolve_spec() が preset 名またはテーブルから spec を返すことをテストします
TestUtil["resolve_spec() returns spec from preset name or table"] = function()
	local presets = {
		example = {
			source = "buffer",
		},
	}

	-- preset 名から spec を取得
	local spec_from_name = util.resolve_spec("example", presets)
	eq(spec_from_name.source, "buffer")

	-- テーブルをそのまま渡した場合
	local spec_from_table = util.resolve_spec({ source = "visual" }, presets)
	eq(spec_from_table.source, "visual")
end

-- lines_to_text() / text_to_lines() の相互変換をテストします
TestUtil["lines_to_text() and text_to_lines() round-trip"] = function()
	local lines = { "line1", "line2" }

	local text = util.lines_to_text(lines)
	eq(text, "line1\nline2")

	local back = util.text_to_lines(text)
	eq(back[1], "line1")
	eq(back[2], "line2")
end

-- make_payload() が text と lines を補完してくれることをテストします
TestUtil["make_payload() fills text and lines fields"] = function()
	-- lines だけを渡した場合、text が自動で埋まる
	local p1 = util.make_payload({ lines = { "a", "b" } })
	eq(p1.text, "a\nb")

	-- text だけを渡した場合、lines が自動で埋まる
	local p2 = util.make_payload({ text = "x\ny" })
	eq(p2.lines[1], "x")
	eq(p2.lines[2], "y")
end

-- テストセットを mini.test に返します
return TestUtil
