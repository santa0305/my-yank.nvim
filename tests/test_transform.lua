-- mini.test を読み込みます
local MiniTest = require("mini.test")

-- テストセットを作る関数です
local new_set = MiniTest.new_set

-- 値が等しいか確認する関数です
local eq = MiniTest.expect.equality

-- transform モジュールと util を読み込みます
local transform = require("my-yank.transform")
local util = require("my-yank.util")

-- このファイルのテストセットを作ります
local TestTransform = new_set()

-- filepath_header() がファイルパスを先頭行として追加することをテストします
TestTransform["filepath_header() adds filepath line to text"] = function()
	-- テスト用 payload を作ります
	local payload = util.make_payload({
		text = "line1\nline2",
		filepath = "/path/to/file.lua",
	})

	-- 相対パスではなく絶対パスのままヘッダを付ける
	local result = transform.filepath_header(payload, { format = "absolute" })

	-- text にファイルパス + 元のテキストが入っていることを確認します
	eq(result.text, "/path/to/file.lua\nline1\nline2")

	-- lines にも反映されているはずなので 1 行目を確認します
	eq(result.lines[1], "/path/to/file.lua")
end

-- codeblock() がコードブロック形式のテキストに変換することをテストします
TestTransform["codeblock() wraps text in fenced code block"] = function()
	-- Lua コードを含む payload を作ります
	local payload = util.make_payload({
		text = "print('hello')",
		filetype = "lua",
	})

	-- lang="lua" を指定してコードブロック化します
	local result = transform.codeblock(payload, { lang = "lua" })

	-- text 全体を期待値と比較します
	eq(result.text, "```lua\nprint('hello')\n```")

	-- lines で見ても 1 行目と最終行が適切になっているか確認します
	eq(result.lines[1], "```lua")
	eq(result.lines[#result.lines], "```")
end

-- trim() が先頭・末尾の空白を削ることをテストします
TestTransform["trim() removes leading and trailing whitespace by default"] = function()
	local payload = util.make_payload({
		text = "  hello  ",
	})

	local result = transform.trim(payload, {})

	eq(result.text, "hello")
end

-- join() が lines を指定した区切りで結合することをテストします
TestTransform["join() concatenates lines with separator"] = function()
	local payload = util.make_payload({
		lines = { "a", "b", "c" },
	})

	local result = transform.join(payload, { sep = "," })

	eq(result.text, "a,b,c")
end

-- eol() が改行コードを LF に揃えることをテストします
TestTransform["eol() normalizes line endings to LF"] = function()
	-- 混在した改行コードを含むテキストを用意します
	local payload = util.make_payload({
		text = "a\r\nb\rc\n",
	})

	local result = transform.eol(payload, {})

	-- すべて LF に統一されていることを確認します
	eq(result.text, "a\nb\nc\n")
end

-- テストセットを返します
return TestTransform
