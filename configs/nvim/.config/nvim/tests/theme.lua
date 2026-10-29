-- nvim --headless -u NONE -l configs/nvim/.config/nvim/tests/theme.lua
local config = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
package.path = config .. "/lua/?.lua;" .. package.path
local previous_config_home = vim.env.XDG_CONFIG_HOME
local temporary = vim.fn.tempname()
vim.env.XDG_CONFIG_HOME = temporary
local path = temporary .. "/theme/appearance"

local function wait_for(mode)
	assert(vim.wait(4000, function()
		return vim.o.background == mode
	end, 20), "Theme did not switch to " .. mode)
	for _, group in ipairs({ "Normal", "NormalNC", "SignColumn", "EndOfBuffer", "LineNr",
		"LineNrAbove", "LineNrBelow", "CursorLineNr", "NormalFloat", "FloatBorder",
		"Pmenu", "StatusLine", "StatusLineNC", "TabLine", "TabLineFill" }) do
		local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
		assert(highlight.bg == nil and highlight.ctermbg == nil, group .. " has an opaque background in " .. mode)
	end
	if mode == "light" then
		for _, group in ipairs({ "LineNr", "LineNrAbove", "LineNrBelow" }) do
			assert(vim.api.nvim_get_hl(0, { name = group, link = false }).fg == 0x665c54,
				group .. " lost its high-contrast foreground")
		end
		local current = vim.api.nvim_get_hl(0, { name = "CursorLineNr", link = false })
		assert(current.fg == 0x3c3836 and current.bold, "Current line number lacks emphasis")
	end
end

local ok, err = pcall(function()
	local theme = require("user.theme")
	theme.setup()
	wait_for("dark") -- Missing theme directory defaults to dark.
	vim.fn.mkdir(temporary .. "/theme", "p")
	vim.fn.writefile({ "light" }, path)
	wait_for("light")
	vim.fn.writefile({ "dark" }, path .. ".next")
	assert(vim.uv.fs_rename(path .. ".next", path)) -- Like rsync replacement.
	wait_for("dark")
	vim.fn.writefile({ "light" }, path)
	wait_for("light")
	vim.fn.writefile({ "invalid" }, path)
	wait_for("dark")
	vim.fn.writefile({ "light" }, path)
	wait_for("light")
	assert(os.remove(path))
	wait_for("dark")
	theme.setup() -- Repeated setup must not leave duplicate watchers.
	wait_for("dark")
	vim.api.nvim_exec_autocmds("VimLeavePre", {})
end)
vim.env.XDG_CONFIG_HOME = previous_config_home
vim.fn.delete(temporary, "rf")
assert(ok, err)
print("PASS: startup fallback, missing marker creation, light/dark switches, replacement, invalid marker, deletion, repeated setup")
