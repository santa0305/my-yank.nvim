local util = require("my_yank.util")

local M = {}

-- payload.text と payload.lines を同期させるためのヘルパー関数です
local function with_text(payload, text)
	payload.text = text
	payload.lines = util.text_to_lines(text)
	return payload
end

-- 文字列の前後の空白を削る変換です
function M.trim(payload, opts)
	opts = opts or {}
	local text = payload.text
	if opts.leading ~= false then
		text = text:gsub("^%s+", "")
	end
	if opts.trailing ~= false then
		text = text:gsub("%s+$", "")
	end
	return with_text(payload, text)
end

-- 複数行を1つの文字列に結合する変換です
function M.join(payload, opts)
	opts = opts or {}
	local sep = opts.sep or " "
	return with_text(payload, table.concat(payload.lines or {}, sep))
end

-- 先頭にファイルパスを追加する変換です（既存の挙動はそのまま）
function M.filepath_header(payload, opts)
	opts = opts or {}
	local path = payload.filepath or ""
	if opts.format == "relative" then
		path = util.relative_path(path)
	end
	if path == "" then
		return payload
	end
	return with_text(payload, path .. "\n" .. payload.text)
end

-- コードフェンス（```）で囲む変換です
-- ここを「```lang:relative_path」の形も出せるように拡張します
function M.codeblock(payload, opts)
	opts = opts or {}
	local fence = opts.fence or "```"
	local lang = opts.lang
	local path = nil

	-- 言語の決定ロジック
	if lang == nil or lang == "auto" then
		lang = payload.filetype or ""
	elseif lang == false then
		lang = ""
	end

	-- path オプション:
	--   opts.path = "relative" なら相対パス
	--   opts.path = "absolute" なら絶対パス
	if opts.path == "relative" then
		path = util.relative_path(payload.filepath or "")
	elseif opts.path == "absolute" then
		path = payload.filepath or ""
	end

	-- フェンスの info 文字列を組み立てます
	-- 例:
	--   lang="lua", path="lua/hogehoge.lua" → "lua:lua/hogehoge.lua"
	--   lang="", path="lua/hogehoge.lua"   → ":lua/hogehoge.lua"
	local info = lang or ""
	if path and path ~= "" then
		if info ~= "" then
			info = info .. ":" .. path
		else
			info = ":" .. path
		end
	end

	-- info が空なら従来どおり「```」だけになります
	return with_text(payload, string.format("%s%s\n%s\n%s", fence, info, payload.text, fence))
end

-- 改行コードを LF に揃える変換です
function M.eol(payload, opts)
	opts = opts or {}
	local text = payload.text:gsub("\r\n", "\n"):gsub("\r", "\n")
	if opts.ensure_final_eol then
		if not text:match("\n$") then
			text = text .. "\n"
		end
	elseif opts.strip_final_eol then
		text = text:gsub("\n+$", "")
	end
	return with_text(payload, text)
end

return M
