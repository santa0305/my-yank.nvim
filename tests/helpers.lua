local H = {}

H.new_child = function()
	local child = MiniTest.new_child_neovim()

	local setup = function()
		child.restart()
		child.lua([[M = require('my_yank')]])
	end

	return child, setup
end

H.set_buffer = function(child, lines, filetype)
	child.cmd("enew!")
	child.api.nvim_buf_set_lines(0, 0, -1, false, lines or {})
	if filetype then
		child.bo.filetype = filetype
	end
end

return H
