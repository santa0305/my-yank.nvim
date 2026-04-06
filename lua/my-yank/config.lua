local M = {}

M.defaults = {
	clipboard = {
		default_register = "+",
		fallback_register = '"',
	},
	notify = true,
	presets = {
		copy_buffer_codeblock = {
			source = "buffer",
			transforms = {
				{ "filepath_header", format = "relative" },
				{ "codeblock", lang = "auto", path = "relative" },
			},
			sinks = {
				"clipboard",
				"notify",
			},
		},
		copy_visual_codeblock = {
			source = "visual",
			transforms = {
				{ "codeblock", lang = "auto" },
			},
			sinks = {
				"clipboard",
				"notify",
			},
		},
		copy_path = {
			source = "filepath",
			source_opts = { format = "relative" },
			sinks = {
				"clipboard",
				"notify",
			},
		},
		copy_path_with_line = {
			source = "filepath",
			source_opts = { format = "relative", with_line = true },
			sinks = {
				"clipboard",
				"notify",
			},
		},
	},
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
	return M.options
end

function M.get()
	return M.options
end

return M
