local config = require("my-yank.config")

local M = {}

function M.register(payload, opts)
	opts = opts or {}
	local reg = opts.register or '"'
	vim.fn.setreg(reg, payload.text, payload.regtype or "v")
	return payload
end

function M.clipboard(payload, opts)
	opts = opts or {}
	local conf = config.get()
	local reg = opts.register or conf.clipboard.default_register or "+"
	local ok = pcall(vim.fn.setreg, reg, payload.text, payload.regtype or "v")

	if not ok then
		local fallback = conf.clipboard.fallback_register or '"'
		vim.fn.setreg(fallback, payload.text, payload.regtype or "v")
		if conf.notify then
			vim.notify(
				string.format("my-yank: clipboard unavailable, wrote to %s register", fallback),
				vim.log.levels.WARN
			)
		end
	end

	return payload
end

function M.notify(payload, opts)
	opts = opts or {}
	local conf = config.get()
	if conf.notify == false or opts.enabled == false then
		return payload
	end
	local msg = opts.message or string.format("Copied %d chars", #payload.text)
	vim.notify(msg, opts.level or vim.log.levels.INFO)
	return payload
end

return M
