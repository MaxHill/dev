require("user.types")

---@type Language
local M = {}

local function root(bufnr)
	return vim.fs.root(bufnr or 0, { "build.zig", "build.zig.zon" }) or vim.fn.getcwd()
end

M.lsps = {
	{
		mason_name = "zls",
		lsp_name = "zls",
		config = {
			cmd = { vim.fn.expand("~/.local/share/mise/shims/zls") },
			filetypes = { "zig", "zon", "zir" },
			root_markers = { "build.zig", "build.zig.zon", ".git" },
		},
	},
}
M.filetypes = { "zig", "zon" }
M.treesitter_parsers = { "zig" }
M.formatters = {
	{
		name = "zigfmt",
		options = {
			command = "mise",
			args = { "exec", "--", "zig", "fmt", "--stdin" },
			cwd = function(_, ctx)
				return root(ctx.buf)
			end,
			stdin = true,
		},
	},
}

-- All completion paths resume after yielding, even synchronous UI callbacks.
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
				vim.notify("Zig DAP: " .. tostring(err), vim.log.levels.ERROR)
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

local function arguments(dap)
	local value = await(function(done)
		vim.ui.input({ prompt = 'Arguments (JSON array, e.g. ["hello world"]): ' }, done)
	end)
	if value == nil then
		return dap.ABORT
	end
	if value == "" then
		return {}
	end
	local ok, args = pcall(vim.json.decode, value)
	if ok and type(args) == "table" and vim.islist(args) and value:match("^%s*%[") then
		for _, arg in ipairs(args) do
			if type(arg) ~= "string" then
				ok = false
			end
		end
		if ok then
			return args
		end
	end
	vim.notify("Zig DAP: arguments must be a JSON array of strings", vim.log.levels.ERROR)
	return dap.ABORT
end

local function pick_executable(dir, dap)
	local candidates = {}
	local scan = vim.uv.fs_scandir(dir)
	if scan then
		while true do
			local name, kind = vim.uv.fs_scandir_next(scan)
			if not name then
				break
			end
			local path = dir .. "/" .. name
			if (kind == "file" or kind == "link") and vim.fn.executable(path) == 1 then
				table.insert(candidates, path)
			end
		end
	end
	table.sort(candidates)
	if #candidates == 0 then
		vim.notify(
			"Zig DAP: no executables in "
				.. dir
				.. ". Build the selected target first; see :help or docs/nvim-debugging.md for the debug-test contract.",
			vim.log.levels.ERROR
		)
		return dap.ABORT
	end
	if #candidates == 1 then
		return candidates[1]
	end
	return await(function(done)
		vim.ui.select(candidates, { prompt = "Zig executable" }, done)
	end) or dap.ABORT
end

local source = debug.getinfo(1, "S").source:sub(2)
local printer = vim.fs.normalize(vim.fs.dirname(source) .. "/../../../lldb/zig.py")

local function formatter_commands(cwd)
	local result = run({ "mise", "exec", "--", "zig", "env" }, cwd)
	local output = result.stdout or ""
	local ok, env = pcall(vim.json.decode, output)
	-- Zig 0.14+ emits ZON. Read only the quoted path field, never evaluate it.
	if not ok then
		local literal = output:match('\n%s*%.lib_dir%s*=%s*("[^\n]+"),')
		local path_ok, path = pcall(vim.json.decode, literal or "")
		ok, env = path_ok, { lib_dir = path_ok and path or nil }
	end
	if result.code ~= 0 or not ok or type(env) ~= "table" then
		-- A toolchain failure must not silently launch an artifact from another version.
		vim.notify(
			"Zig DAP: cannot resolve project Zig with mise exec -- zig env:\n" .. (result.stderr or ""),
			vim.log.levels.ERROR
		)
		return nil
	end
	local lib = env.lib_dir or env.zig_lib_dir
	local paths = lib and { lib .. "/lldb/pretty_printers.py", lib .. "/../tools/lldb_pretty_printers.py" } or {}
	local upstream
	for _, path in ipairs(paths) do
		if vim.fn.filereadable(path) == 1 then
			upstream = path
			break
		end
	end
	if not upstream or vim.fn.filereadable(printer) ~= 1 then
		vim.notify(
			"Zig DAP: selected Zig has no usable LLDB formatters (or nvim/lldb/zig.py is missing); values will use raw LLDB rendering",
			vim.log.levels.WARN
		)
		return {}
	end
	-- JSON string literals are also valid Python string literals; paths cannot become commands.
	return {
		"script import runpy; runpy.run_path("
			.. vim.json.encode(printer)
			.. ')["setup"](lldb.debugger, '
			.. vim.json.encode(upstream)
			.. ")",
	}
end

local zig_errorformat = table.concat({ "%E%f:%l:%c: %t%*[^:]: %m", "%C%m", "    %m: %f:%l:%c", "%-G%.%#" }, ",")

M.setup = function()
	local dap = require("dap")
	require("user.mason").install("codelldb")
	vim.api.nvim_create_autocmd("FileType", {
		group = vim.api.nvim_create_augroup("ZigTools", { clear = true }),
		pattern = { "zig", "zon" },
		callback = function()
			vim.opt_local.errorformat = zig_errorformat
		end,
	})

	local adapter = vim.fn.stdpath("data") .. "/mason/bin/codelldb"
	dap.adapters.codelldb = {
		type = "server",
		host = "127.0.0.1",
		port = "${port}",
		executable = { command = adapter, args = { "--port", "${port}" } },
	}

	local function configuration(name, mode)
		return setmetatable({ name = name, type = "codelldb", request = mode == "attach" and "attach" or "launch" }, {
			__call = function(base)
				local config = vim.deepcopy(base)
				setmetatable(config, nil)
				local function abort(message)
					if message then
						vim.notify("Zig DAP: " .. message, vim.log.levels.ERROR)
					end
					config.program = dap.ABORT
					return config
				end
				local cwd = root()
				config.cwd = cwd
				config.dap_layout = 1
				config.terminal = "integrated"
				if vim.fn.executable(adapter) ~= 1 then
					return abort("CodeLLDB is missing. Run :MasonInstall codelldb and retry after installation.")
				end
				if vim.fn.executable("mise") ~= 1 then
					return abort("mise is not on PATH")
				end
				config.initCommands = formatter_commands(cwd)
				if not config.initCommands then
					return abort()
				end
				if mode == "attach" then
					config.pid = require("dap.utils").pick_process()
					if not config.pid or config.pid == dap.ABORT then
						return abort()
					end
					return config
				end
				if mode ~= "launch" then
					local cmd = { "mise", "exec", "--", "zig", "build" }
					if mode == "test" then
						table.insert(cmd, "debug-test")
					end
					table.insert(cmd, "-Doptimize=Debug")
					-- Zig's self-hosted backend emits DW_LANG_Zig, which CodeLLDB cannot inspect.
					-- Projects expose this option through b.option(bool, "llvm", ...).
					table.insert(cmd, "-Dllvm=true")
					vim.notify("Zig DAP: building in " .. cwd)
					local result = run(cmd, cwd)
					if result.code ~= 0 then
						return abort(
							"build failed:\n"
								.. (result.stderr or "")
								.. "\nDAP builds require a build.zig -Dllvm option wired to .use_llvm; see docs/nvim-debugging.md."
								.. (
									mode == "test"
										and "\nExpected build-only target: debug-test, installing binaries under zig-out/debug-tests/."
									or ""
								)
						)
					end
				end
				config.program =
					pick_executable(cwd .. (mode == "test" and "/zig-out/debug-tests" or "/zig-out/bin"), dap)
				if config.program == dap.ABORT then
					return config
				end
				if vim.fn.executable(config.program) ~= 1 then
					return abort("selected executable disappeared: " .. config.program)
				end
				config.args = arguments(dap)
				return config
			end,
		})
	end

	dap.configurations.zig = {
		configuration("Build & Launch", "build"),
		configuration("Launch (no build)", "launch"),
		configuration("Build & Test (build-only)", "test"),
		configuration("Attach to Process", "attach"),
	}
end

return M
