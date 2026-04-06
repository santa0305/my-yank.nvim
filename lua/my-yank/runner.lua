local config = require("my-yank.config")
local source = require("my-yank.source")
local transform = require("my-yank.transform")
local sink = require("my-yank.sink")
local util = require("my-yank.util")

local M = {}

function M.run(name_or_spec)
	local conf = config.get()
	local spec = util.resolve_spec(name_or_spec, conf.presets or {})

	if not spec.source then
		error("my-yank: spec.source is required")
	end

	local src = source[spec.source]
	if type(src) ~= "function" then
		error("my-yank: unknown source: " .. tostring(spec.source))
	end

	local payload = src(spec.source_opts or {})

	for _, step in ipairs(util.normalize_steps(spec.transforms)) do
		local fn = transform[step.name]
		if type(fn) ~= "function" then
			error("my-yank: unknown transform: " .. tostring(step.name))
		end
		payload = fn(payload, step.opts or {})
	end

	for _, step in ipairs(util.normalize_steps(spec.sinks)) do
		local fn = sink[step.name]
		if type(fn) ~= "function" then
			error("my-yank: unknown sink: " .. tostring(step.name))
		end
		fn(payload, step.opts or {})
	end

	return payload
end

return M
