local M = {}

function M.setup()
	if vim.g.my_yank_commands_loaded then
		return
	end
	vim.g.my_yank_commands_loaded = true

	vim.api.nvim_create_user_command("MyYankRun", function(opts)
		require("my-yank").run(opts.args)
	end, {
		nargs = 1,
		complete = function()
			local presets = require("my-yank.config").get().presets or {}
			return vim.tbl_keys(presets)
		end,
	})

	vim.api.nvim_create_user_command("MyYankCopyPath", function()
		require("my-yank").run("copy_path")
	end, {})

	vim.api.nvim_create_user_command("MyYankCopyBufferCodeblock", function()
		require("my-yank").run("copy_buffer_codeblock")
	end, {})
end

return M
