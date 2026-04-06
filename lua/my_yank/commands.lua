local config = require("my_yank.config")

local M = {}

local function complete_presets(arg_lead)
	local presets = config.get().presets or {}
	local items = {}

	for name, _ in pairs(presets) do
		if arg_lead == "" or vim.startswith(name, arg_lead) then
			table.insert(items, name)
		end
	end

	table.sort(items)
	return items
end

function M.setup()
	vim.api.nvim_create_user_command("MyYank", function(opts)
		local preset = opts.fargs[1]
		if not preset or preset == "" then
			vim.notify("preset 名を指定してください", vim.log.levels.WARN)
			return
		end

		require("my_yank").run(preset)
	end, {
		nargs = 1,
		complete = function(arg_lead, _, _)
			return complete_presets(arg_lead)
		end,
		desc = "Run my-yank preset",
	})
end

return M
