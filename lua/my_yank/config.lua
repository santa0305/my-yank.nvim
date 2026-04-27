local M = {}

M.defaults = {
	clipboard = {
		default_register = "+",
		fallback_register = '"',
	},
	notify = true,
	presets = {
		-- バッファ全体を ```lang:relative/path 形式のコードブロックとしてコピーします
		buffer = {
			source = "buffer",
			transforms = {
				{ "codeblock", lang = "auto", path = "relative" },
			},
			sinks = {
				"clipboard",
				"notify",
			},
		},
		visual = {
			source = "visual",
			transforms = {
				{ "codeblock", lang = "auto" },
			},
			sinks = {
				"clipboard",
				"notify",
			},
		},
		messages = {
			source = "messages",
			transforms = {
				{ "codeblock", lang = "txt", path = "relative" },
			},
			sinks = {
				-- クリップボードに書き込み
				"clipboard",
				-- 通知でフィードバック
				"notify",
			},
		},
		terminal = {
			source = "terminal_block",
			source_opts = {
				prompt_patterns = {},
			},
			transforms = {
				{ "codeblock", lang = "pwsh", path = "none" },
			},
			sinks = {
				"clipboard",
				"notify",
			},
		},
		path = {
			source = "filepath",
			source_opts = { format = "relative" },
			sinks = {
				"clipboard",
				"notify",
			},
		},
		path_with_line = {
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
