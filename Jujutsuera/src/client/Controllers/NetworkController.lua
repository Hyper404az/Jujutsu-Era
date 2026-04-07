local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkController = {}
NetworkController.__index = NetworkController

function NetworkController.new()
    local self = setmetatable({}, NetworkController)
    local remotes = ReplicatedStorage:WaitForChild("Remotes")
    self._events = remotes:WaitForChild("Events")
    self._functions = remotes:WaitForChild("Functions")
    return self
end

function NetworkController:GetEvent(name)
    return self._events:WaitForChild(name)
end

function NetworkController:GetFunction(name)
    return self._functions:WaitForChild(name)
end

function NetworkController:Fire(name, payload)
    self:GetEvent(name):FireServer(payload)
end

function NetworkController:Invoke(name, payload)
    return self:GetFunction(name):InvokeServer(payload)
end

return NetworkController
