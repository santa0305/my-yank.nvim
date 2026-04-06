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

function M.terminal_block(opts)
	opts = opts or {}
	local bufnr = util.bufnr(opts.bufnr)
	local cur_row = opts.row or vim.api.nvim_win_get_cursor(0)[1]
	local last_row = vim.api.nvim_buf_line_count(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	local function is_prompt(line)
		if not line then
			return false
		end
		return line:match("^%s*PS>") or line:match("^%s*%$") or line:match("^%s*>")
	end

	-- 現在位置から上へたどって、直近の「prompt 2行目」を探す
	local prompt_row = cur_row
	while prompt_row > 1 and not is_prompt(lines[prompt_row]) do
		prompt_row = prompt_row - 1
	end

	-- prompt は常に 2 行構成なので、ブロック開始はその 1 行前
	local start_row = math.max(1, prompt_row)

	-- 次のブロックの prompt 2行目を探す
	local next_prompt_row = nil
	for row = prompt_row + 1, last_row do
		if is_prompt(lines[row]) then
			next_prompt_row = row
			break
		end
	end

	-- 次ブロックが見つかったら、その 2 行前までをこのブロックにする
	-- つまり:
	--   next_prompt_row - 1 = 次ブロックの prompt 1行目
	--   next_prompt_row - 2 = このブロックの最終行
	local end_row
	if next_prompt_row then
		end_row = math.max(start_row, next_prompt_row - 2)
	else
		end_row = last_row
	end

	local block_lines = {}
	for i = start_row, end_row do
		table.insert(block_lines, lines[i])
	end

	local text = table.concat(block_lines, "\n")

	return util.make_payload({
		text = text,
		lines = block_lines,
		source = "terminal_block",
		bufnr = bufnr,
		filetype = "terminal",
		filepath = vim.api.nvim_buf_get_name(bufnr),
		metadata = {
			range = { start_row = start_row, end_row = end_row },
			prompt_row = prompt_row,
			next_prompt_row = next_prompt_row,
		},
	})
end

return M
