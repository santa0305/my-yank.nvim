local config = require("my-yank.config")
local commands = require("my-yank.commands")
local runner = require("my-yank.runner")

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
