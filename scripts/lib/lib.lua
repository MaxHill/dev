---@class LibFzfOptions
---@field items? string[] Candidate lines; defaults to an empty list.
---@field args? string[] Additional fzf command-line arguments.
---@field print_query? boolean Also return an unmatched query when Enter is pressed.

---@class Lib
---@field shell_quote fun(value: string): string
---@field exec fun(command: string, verbose?: boolean): boolean
---@field run fun(command: string): string
---@field fzf fun(options?: LibFzfOptions): string|nil, string|nil
---@field file_exists fun(path: string): boolean
---@field program_exists fun(name: string): boolean
---@field git_branch_exists fun(name: string): boolean
---@field git_base_branch fun(): string

---@type Lib
local lib = {}

---Quote a value so the shell passes it as one literal argument.
---@param value string
---@return string
function lib.shell_quote(value)
    return "'" .. value:gsub("'", "'\\''") .. "'"
end

---Run a shell command; raise an error if it exits unsuccessfully.
---@param command string
---@param verbose? boolean Write the command to stderr before running it.
---@return boolean
function lib.exec(command, verbose)
    if verbose then
        io.stderr:write("> " .. command .. "\n")
    end
    local ok, kind, code = os.execute(command)
    if not ok then
        error("Command failed: " .. command .. " (" .. tostring(code) .. ")")
    end
    return ok
end

---Run a shell command, capture stdout, and raise an error on failure.
---@param command string
---@return string stdout
function lib.run(command)
    io.stderr:write("> " .. command .. "\n")

    local pipe, err = io.popen(command, "r")
    if not pipe then
        error(err)
    end

    local output = pipe:read("*a")
    local ok, kind, code = pipe:close()
    if not ok then
        error("Command failed: " .. command .. " (" .. tostring(code) .. ")")
    end

    return output
end

---Show candidates in fzf and return the selected line, if any.
---When print_query is enabled, return an unmatched query if Enter submits it.
---@param options? LibFzfOptions
---@return string|nil selection
---@return string|nil query Non-nil only for an unmatched submitted query.
function lib.fzf(options)
    options = options or {}
    local items = options.items or {}
    if type(items) ~= "table" then
        error("lib.fzf expects options.items to be a table")
    end

    local temp_path = os.tmpname()
    local input, err = io.open(temp_path, "w")
    if not input then
        error("Could not create fzf input file: " .. tostring(err))
    end
    for _, item in ipairs(items) do
        if type(item) ~= "string" or item:find("[\r\n]") then
            input:close()
            os.remove(temp_path)
            error("lib.fzf items must be strings without newlines")
        end
        input:write(item, "\n")
    end
    input:close()

    local args = { "fzf" }
    for _, value in ipairs(options.args or {}) do
        args[#args + 1] = lib.shell_quote(value)
    end
    if options.print_query then
        args[#args + 1] = "--print-query"
    end
    local command = table.concat(args, " ") .. " < " .. lib.shell_quote(temp_path)
    local picker, picker_err = io.popen(command, "r")
    if not picker then
        os.remove(temp_path)
        error("Could not start fzf: " .. tostring(picker_err))
    end

    local output = picker:read("*a")
    local ok, _, exit_code = picker:close()
    os.remove(temp_path)

    if options.print_query then
        local query, selected = output:match("^([^\n]*)\n(.*)$")
        query = query or ""
        selected = (selected or ""):gsub("[\r\n]+$", "")
        if ok and selected ~= "" then
            return selected, nil
        end
        if not ok and exit_code == 1 and query ~= "" then
            return nil, query
        end
        if not ok and exit_code ~= 130 and exit_code ~= 1 then
            error("fzf failed with exit code " .. tostring(exit_code))
        end
        return nil, nil
    end

    local selected = output:gsub("[\r\n]+$", "")
    if ok and selected ~= "" then
        return selected, nil
    end
    if not ok and exit_code ~= 130 and exit_code ~= 1 then
        error("fzf failed with exit code " .. tostring(exit_code))
    end
    return nil, nil
end

---Return whether a file can be opened for reading.
---@param path string
---@return boolean
function lib.file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

---Return whether a command is available on PATH.
---@param name string
---@return boolean
function lib.program_exists(name)
    local ok = os.execute("command -v " .. lib.shell_quote(name) .. " >/dev/null 2>&1")
    return ok == true
end

---Return whether Git can resolve a branch or ref.
---@param name string
---@return boolean
function lib.git_branch_exists(name)
    local ok = os.execute("git rev-parse --verify " .. lib.shell_quote(name) .. " >/dev/null 2>&1")
    return ok == true
end

---Find the preferred mainline ref, preferring origin/main and then main/master.
---@return string
function lib.git_base_branch()
    for _, candidate in ipairs({
        "origin/main",
        "main",
        "origin/master",
        "master",
    }) do
        if lib.git_branch_exists(candidate) then
            return candidate
        end
    end

    io.stderr:write("Error: Could not find main or master to create the branch from.\n")
    os.exit(1)
end

return lib
