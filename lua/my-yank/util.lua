local M = {}

-- bufnr を安全に解決する関数です
-- - 引数が nil または 0 の場合は「現在のバッファ番号」を返す
-- - それ以外の場合は、そのまま返す
function M.bufnr(bufnr)
	-- nil や 0 のときは現在のバッファを使います
	if bufnr == nil or bufnr == 0 then
		return vim.api.nvim_get_current_buf()
	end

	-- それ以外は渡された値をそのまま返します
	return bufnr
end

-- （この下は今の util.lua の残りをそのまま）
function M.bufname(bufnr)
	return vim.api.nvim_buf_get_name(M.bufnr(bufnr))
end

function M.relative_path(path)
	if path == nil or path == "" then
		return ""
	end
	return vim.fn.fnamemodify(path, ":.")
end

function M.normalize_step(step)
	if type(step) == "string" then
		return { name = step, opts = {} }
	end

	if type(step) ~= "table" then
		error("my-yank: invalid step")
	end

	local name = step.name or step[1]
	if type(name) ~= "string" or name == "" then
		error("my-yank: step name is required")
	end

	local opts = {}
	for k, v in pairs(step) do
		if k ~= 1 and k ~= "name" then
			opts[k] = v
		end
	end

	return { name = name, opts = opts }
end

function M.normalize_steps(steps)
	local normalized = {}
	for _, step in ipairs(steps or {}) do
		table.insert(normalized, M.normalize_step(step))
	end
	return normalized
end

function M.resolve_spec(name_or_spec, presets)
	if type(name_or_spec) == "string" then
		local preset = presets[name_or_spec]
		if not preset then
			error("my-yank: unknown preset: " .. name_or_spec)
		end
		return vim.deepcopy(preset)
	end

	if type(name_or_spec) == "table" then
		return vim.deepcopy(name_or_spec)
	end

	error("my-yank: spec must be a preset name or table")
end

function M.lines_to_text(lines)
	return table.concat(lines or {}, "\n")
end

function M.text_to_lines(text)
	if text == "" then
		return { "" }
	end
	return vim.split(text, "\n", { plain = true })
end

function M.make_payload(fields)
	local payload = vim.tbl_extend("force", {
		text = "",
		lines = {},
		source = "",
		bufnr = vim.api.nvim_get_current_buf(),
		filetype = vim.bo.filetype,
		filepath = M.bufname(0),
		regtype = "v",
		metadata = {},
	}, fields or {})

	if (not payload.text or payload.text == "") and payload.lines then
		payload.text = M.lines_to_text(payload.lines)
	end
	if (not payload.lines or vim.tbl_isempty(payload.lines)) and payload.text then
		payload.lines = M.text_to_lines(payload.text)
	end

	return payload
end

function M.get_visual_selection()
	local mode = vim.fn.mode()
	if not mode:match("[vV\22]") then
		error("my-yank: visual source requires visual mode")
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local start_pos = vim.fn.getpos("v")
	local end_pos = vim.fn.getpos(".")

	local srow, scol = start_pos[2], start_pos[3]
	local erow, ecol = end_pos[2], end_pos[3]

	if srow > erow or (srow == erow and scol > ecol) then
		srow, erow = erow, srow
		scol, ecol = ecol, scol
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, srow - 1, erow, false)
	if #lines == 0 then
		return { lines = {}, text = "", range = nil }
	end

	local visual_mode = vim.fn.visualmode()
	if visual_mode == "v" then
		lines[1] = string.sub(lines[1], scol)
		lines[#lines] = string.sub(lines[#lines], 1, ecol)
	elseif visual_mode == "V" then
	-- 行選択はそのまま
	else
		error("my-yank: blockwise visual mode is not supported yet")
	end

	return {
		lines = lines,
		text = table.concat(lines, "\n"),
		range = {
			start_row = srow,
			start_col = scol,
			end_row = erow,
			end_col = ecol,
		},
	}
end

return M
