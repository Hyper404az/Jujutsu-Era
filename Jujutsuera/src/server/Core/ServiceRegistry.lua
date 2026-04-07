local ServiceRegistry = {}
ServiceRegistry.__index = ServiceRegistry

function ServiceRegistry.new()
    return setmetatable({
        _services = {},
        _order = {},
    }, ServiceRegistry)
end

function ServiceRegistry:Register(name, service)
    self._services[name] = service
    table.insert(self._order, service)
end

function ServiceRegistry:Get(name)
    return self._services[name]
end

function ServiceRegistry:InitAll()
    for _, service in ipairs(self._order) do
        if service.Init then
            service:Init(self)
        end
    end
end

function ServiceRegistry:StartAll()
    for _, service in ipairs(self._order) do
        if service.Start then
            service:Start()
        end
    end
end

return ServiceRegistry
