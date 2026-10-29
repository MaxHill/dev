local M = {}
local watcher
local appearance

local function read_appearance(path)
	local file = io.open(path, "r")
	if not file then
		return "dark"
	end
	local value = file:read("*a"):match("^%s*(.-)%s*$")
	file:close()
	return value == "light" and "light" or "dark"
end

local function apply_highlight_overrides()
	if vim.o.background == "light" then
		for _, group in ipairs({ "LineNr", "LineNrAbove", "LineNrBelow", "CursorLineNr" }) do
			local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
			highlight.fg = group == "CursorLineNr" and 0x3c3836 or 0x665c54
			if group == "CursorLineNr" then
				highlight.bold = true
			end
			vim.api.nvim_set_hl(0, group, highlight)
		end
		vim.api.nvim_set_hl(0, "Visual", {
			fg = "#282828",
			bg = "#bdae93",
		})
		vim.api.nvim_set_hl(0, "Search", {
			fg = "#282828",
			bg = "#fabd2f",
		})
		vim.api.nvim_set_hl(0, "IncSearch", {
			fg = "#fbf1c7",
			bg = "#af3a03",
		})
	end
	-- Use Kitty's background without discarding the palette's foreground colors.
	for _, group in ipairs({
		"Normal", "NormalNC", "SignColumn", "EndOfBuffer", "LineNr",
		"LineNrAbove", "LineNrBelow", "CursorLineNr", "NormalFloat", "FloatBorder",
		"Pmenu", "StatusLine", "StatusLineNC", "TabLine", "TabLineFill",
	}) do
		local highlight = vim.api.nvim_get_hl(0, { name = group, link = false })
		highlight.bg = nil
		highlight.ctermbg = nil
		vim.api.nvim_set_hl(0, group, highlight)
	end
end

local function stop_watching()
	if watcher then
		watcher:stop()
		watcher:close()
		watcher = nil
	end
end

function M.setup()
	stop_watching()
	appearance = nil
	vim.cmd.packadd("gruvbox-material")
	vim.g.gruvbox_material_background = "hard"
	vim.g.gruvbox_material_foreground = "material"
	vim.g.gruvbox_material_enable_italic = 1
	vim.g.gruvbox_material_transparent_background = 2

	local group = vim.api.nvim_create_augroup("UserTheme", { clear = true })
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		pattern = "gruvbox-material",
		callback = apply_highlight_overrides,
	})

	local config_home = vim.env.XDG_CONFIG_HOME
	if not config_home or config_home == "" then
		config_home = vim.fn.expand("~/.config")
	end
	local path = config_home .. "/theme/appearance"
	local function refresh()
		local next_appearance = read_appearance(path)
		if next_appearance == appearance then
			return
		end
		vim.o.background = next_appearance
		vim.cmd.colorscheme("gruvbox-material")
		appearance = next_appearance
	end
	refresh()

	-- Polling survives rsync's file replacement and an initially missing marker.
	watcher = assert(vim.uv.new_fs_poll())
	watcher:start(path, 500, vim.schedule_wrap(function()
		if watcher then
			refresh()
		end
	end))
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = stop_watching,
	})
end

return M
