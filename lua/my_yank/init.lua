local config = require("my_yank.config")
local commands = require("my_yank.commands")
local runner = require("my_yank.runner")

local M = {}

function M.setup(opts)
	config.setup(opts or {})
	commands.setup()
end

function M.run(name_or_spec)
	return runner.run(name_or_spec)
end

function M.copy(name_or_spec)
	return M.run(name_or_spec)
end

return M
