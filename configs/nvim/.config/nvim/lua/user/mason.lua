local M = {}

M.install = function(name)
    vim.schedule(function()
        local registry = require("mason-registry")
        if registry.is_installed(name) then
            return
        end

        -- Scheduling alone does not populate the registry on a fresh install.
        registry.refresh(vim.schedule_wrap(function(success)
            if not success then
                vim.notify("Mason: registry refresh failed; see :MasonLog", vim.log.levels.ERROR)
                return
            end

            local ok, pkg = pcall(registry.get_package, name)
            if not ok then
                vim.notify("Mason: unknown package " .. name .. "; see :MasonLog", vim.log.levels.ERROR)
                return
            end
            if not pkg:is_installed() and not pkg:is_installing() then
                pkg:install()
            end
        end))
    end)
end

return M
