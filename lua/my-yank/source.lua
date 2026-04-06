local util = require("my-yank.util")

local M = {}

function M.buffer(opts)
	opts = opts or {}
	local bufnr = util.bufnr(opts.bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	return util.make_payload({
		text = table.concat(lines, "\n"),
		lines = lines,
		source = "buffer",
		bufnr = bufnr,
		filetype = vim.bo[bufnr].filetype,
		filepath = vim.api.nvim_buf_get_name(bufnr),
	})
end

function M.line(opts)
	opts = opts or {}
	local bufnr = util.bufnr(opts.bufnr)
	local row = opts.row or vim.api.nvim_win_get_cursor(0)[1]
	local lines = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)
	return util.make_payload({
		text = table.concat(lines, "\n"),
		lines = lines,
		source = "line",
		bufnr = bufnr,
		filetype = vim.bo[bufnr].filetype,
		filepath = vim.api.nvim_buf_get_name(bufnr),
		metadata = { row = row },
	})
end

function M.visual(opts)
	opts = opts or {}
	local bufnr = util.bufnr(opts.bufnr)
	local selected = util.get_visual_selection()
	return util.make_payload({
		text = selected.text,
		lines = selected.lines,
		source = "visual",
		bufnr = bufnr,
		filetype = vim.bo[bufnr].filetype,
		filepath = vim.api.nvim_buf_get_name(bufnr),
		metadata = { range = selected.range },
	})
end

function M.filepath(opts)
	opts = opts or {}
	local bufnr = util.bufnr(opts.bufnr)
	local path = vim.api.nvim_buf_get_name(bufnr)
	if opts.format == "relative" then
		path = util.relative_path(path)
	end
	if opts.with_line then
		local row = vim.api.nvim_win_get_cursor(0)[1]
		path = string.format("%s:%d", path, row)
	end
	return util.make_payload({
		text = path,
		lines = { path },
		source = "filepath",
		bufnr = bufnr,
		filetype = vim.bo[bufnr].filetype,
		filepath = vim.api.nvim_buf_get_name(bufnr),
	})
end

function M.register(opts)
	opts = opts or {}
	local reg = opts.register or '"'
	local text = vim.fn.getreg(reg)
	local regtype = vim.fn.getregtype(reg)
	return util.make_payload({
		text = text,
		lines = util.text_to_lines(text),
		source = "register",
		bufnr = vim.api.nvim_get_current_buf(),
		filetype = vim.bo.filetype,
		filepath = vim.api.nvim_buf_get_name(0),
		regtype = regtype,
		metadata = { register = reg },
	})
end

function M.messages(opts)
	opts = opts or {}

	local text = vim.fn.execute("messages", "silent")
	local lines = util.text_to_lines(text)

	return util.make_payload({
		text = text,
		lines = lines,
		source = "messages",
		bufnr = vim.api.nvim_get_current_buf(),
		filetype = "txt",
		filepath = "messages",
		metadata = { kind = "messages" },
	})
end

return M
