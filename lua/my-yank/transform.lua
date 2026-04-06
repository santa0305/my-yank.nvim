local util = require("my-yank.util")

local M = {}

local function with_text(payload, text)
	payload.text = text
	payload.lines = util.text_to_lines(text)
	return payload
end

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

function M.join(payload, opts)
	opts = opts or {}
	local sep = opts.sep or " "
	return with_text(payload, table.concat(payload.lines or {}, sep))
end

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

function M.codeblock(payload, opts)
	opts = opts or {}
	local fence = opts.fence or "```"
	local lang = opts.lang

	if lang == nil or lang == "auto" then
		lang = payload.filetype or ""
	elseif lang == false then
		lang = ""
	end

	return with_text(payload, string.format("%s%s\n%s\n%s", fence, lang, payload.text, fence))
end

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
