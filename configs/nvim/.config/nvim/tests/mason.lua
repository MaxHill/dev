-- Run from the repository root:
-- nvim --headless -u NONE -l configs/nvim/.config/nvim/tests/mason.lua
local config = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
package.path = config .. "/lua/?.lua;" .. package.path

local function check(refresh_ok)
    package.loaded["user.mason"] = nil
    local ready, refreshes, installs, notifications = false, 0, 0, 0
    local callbacks = {}
    local pkg = {
        is_installed = function() return false end,
        is_installing = function() return installs > 0 end,
        install = function() installs = installs + 1 end,
    }
    package.loaded["mason-registry"] = {
        refresh = function(callback)
            refreshes = refreshes + 1
            callbacks[#callbacks + 1] = callback
        end,
        is_installed = function() return false end,
        get_package = function(name)
            assert(ready, 'Cannot find package "' .. name .. '" before registry refresh')
            return pkg
        end,
    }
    local old_notify = vim.notify
    vim.notify = function() notifications = notifications + 1 end
    local errors = {}
    local old_schedule = vim.schedule
    vim.schedule = function(callback)
        old_schedule(function()
            local ok, err = pcall(callback)
            if not ok then errors[#errors + 1] = err end
        end)
    end
    local installer = require("user.mason")
    installer.install("codelldb")
    installer.install("codelldb")
    vim.wait(20, function() return false end)
    assert(#errors == 0, table.concat(errors, "\n"))
    assert(installs == 0, "installed before registry refresh finished")
    assert(refreshes > 0, "registry was never refreshed")
    ready = refresh_ok
    for _, callback in ipairs(callbacks) do callback(refresh_ok) end
    vim.wait(20, function() return false end)
    assert(#errors == 0, table.concat(errors, "\n"))
    assert(installs == (refresh_ok and 1 or 0), "unexpected install count: " .. installs)
    if not refresh_ok then assert(notifications > 0, "refresh failure was silent") end
    vim.notify = old_notify
    vim.schedule = old_schedule
end

check(true)
check(false)
print("PASS: installs wait for registry refresh; duplicate requests and refresh failures are safe")
