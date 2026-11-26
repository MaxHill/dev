require("user.types")

---@type Language
local M = {}

M.lsps = {
	{
		mason_name = "typescript-language-server",
		lsp_name = "ts_ls",
		config = {
			cmd = { "typescript-language-server", "--stdio" },
			root_markers = { "tsconfig.json", "package.json" },
		},
	},
	{
		mason_name = "svelte-language-server",
		lsp_name = "svelte",
	},
}

-- Configuration preparation runs in nvim-dap's coroutine, not in an args callback.
local function await(start)
	local co = coroutine.running()
	local completed = false
	start(function(value)
		if completed then
			return
		end
		completed = true
		vim.schedule(function()
			local ok, err = coroutine.resume(co, value)
			if not ok then
				vim.notify("Node DAP: " .. tostring(err), vim.log.levels.ERROR)
			end
		end)
	end)
	return coroutine.yield()
end

local function run(cmd, cwd)
	return await(function(done)
		local ok, err = pcall(vim.system, cmd, { cwd = cwd, text = true }, done)
		if not ok then
			done({ code = -1, stderr = tostring(err) })
		end
	end)
end

local function input(prompt, default)
	return await(function(done)
		vim.ui.input({ prompt = prompt, default = default }, done)
	end)
end

M.setup = function()
	require("user.mason").install("js-debug-adapter")
	local dap = require("dap")
	local server = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"
	dap.adapters["pwa-node"] = {
		type = "server",
		host = "127.0.0.1",
		port = "${port}",
		executable = { command = "node", args = { server, "${port}", "127.0.0.1" } },
	}

	local function configuration(attach)
		return setmetatable({
			name = attach and "Node: Attach inspector" or "Node + tsx: Launch current file",
			type = "pwa-node",
			request = attach and "attach" or "launch",
		}, {
			__call = function(base)
				local config = vim.deepcopy(base)
				setmetatable(config, nil)
				local function abort(message)
					if message then
						vim.notify("Node DAP: " .. message, vim.log.levels.ERROR)
					end
					config.program = dap.ABORT
					return config
				end
				local file = vim.api.nvim_buf_get_name(0)
				local cwd = vim.fs.root(0, { "package.json", "mise.toml", ".git" }) or vim.fn.getcwd()
				if vim.fn.filereadable(server) ~= 1 then
					return abort("js-debug-adapter is missing. Run :MasonInstall js-debug-adapter and retry.")
				end
				if vim.fn.executable("node") ~= 1 or vim.fn.executable("mise") ~= 1 then
					return abort("node and mise must be on PATH (including for the debug adapter)")
				end
				config.cwd, config.dap_layout = cwd, 1
				config.sourceMaps = true
				config.resolveSourceMapLocations = { cwd .. "/**", "!**/node_modules/**" }
				if attach then
					local port = input("Node inspector port: ", "9229")
					if port == nil then
						return abort()
					end
					if not port:match("^%d+$") or tonumber(port) < 1 or tonumber(port) > 65535 then
						return abort("inspector port must be between 1 and 65535")
					end
					config.address, config.port = "127.0.0.1", tonumber(port)
					return config
				end
				if file == "" or vim.fn.filereadable(file) ~= 1 then
					return abort("save the current JS/TS file before launching")
				end
				-- Resolve only an installed workspace dependency; never use npx/downloads.
				local resolved =
					run({ "mise", "exec", "--", "node", "-p", "require.resolve('tsx', {paths: [process.cwd()]})" }, cwd)
				if resolved.code ~= 0 then
					return abort(
						"cannot resolve local tsx with the project Node. Install tsx in the workspace first.\n"
							.. (resolved.stderr or "")
					)
				end
				local tsx = vim.trim(resolved.stdout or "")
				if vim.fn.filereadable(tsx) ~= 1 then
					return abort("tsx resolved to a missing file: " .. tsx)
				end
				local raw = input('Arguments (JSON array, e.g. ["hello world"]): ')
				if raw == nil then
					return abort()
				end
				local ok, args = true, {}
				if raw ~= "" then
					ok, args = pcall(vim.json.decode, raw)
				end
				if
					not ok
					or type(args) ~= "table"
					or not vim.islist(args)
					or (raw ~= "" and not raw:match("^%s*%["))
				then
					return abort("arguments must be a JSON array of strings")
				end
				for _, arg in ipairs(args) do
					if type(arg) ~= "string" then
						return abort("arguments must be strings")
					end
				end
				config.program, config.args = file, args
				config.runtimeExecutable = "mise"
				config.runtimeArgs = { "exec", "--", "node", "--import", tsx }
				config.console = "integratedTerminal"
				config.skipFiles = { "<node_internals>/**" }
				return config
			end,
		})
	end

	for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact", "astro" }) do
		dap.configurations[language] = { configuration(false), configuration(true) }
	end
end

return M
