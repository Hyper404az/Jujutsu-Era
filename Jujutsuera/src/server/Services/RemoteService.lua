local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteDefinitions = require(ReplicatedStorage.Shared.Config.RemoteDefinitions)

local RemoteService = {
    Name = "RemoteService",
}

function RemoteService:Init()
    local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
    if not remotesFolder then
        remotesFolder = Instance.new("Folder")
        remotesFolder.Name = "Remotes"
        remotesFolder.Parent = ReplicatedStorage
    end

    local eventFolder = remotesFolder:FindFirstChild("Events")
    if not eventFolder then
        eventFolder = Instance.new("Folder")
        eventFolder.Name = "Events"
        eventFolder.Parent = remotesFolder
    end

    local functionFolder = remotesFolder:FindFirstChild("Functions")
    if not functionFolder then
        functionFolder = Instance.new("Folder")
        functionFolder.Name = "Functions"
        functionFolder.Parent = remotesFolder
    end

    self.Events = {}
    self.Functions = {}

    for _, remoteName in ipairs(RemoteDefinitions.Events) do
        local remote = eventFolder:FindFirstChild(remoteName)
        if not remote then
            remote = Instance.new("RemoteEvent")
            remote.Name = remoteName
            remote.Parent = eventFolder
        end
        self.Events[remoteName] = remote
    end

    for _, remoteName in ipairs(RemoteDefinitions.Functions) do
        local remote = functionFolder:FindFirstChild(remoteName)
        if not remote then
            remote = Instance.new("RemoteFunction")
            remote.Name = remoteName
            remote.Parent = functionFolder
        end
        self.Functions[remoteName] = remote
    end
end

function RemoteService:GetEvent(name)
    return self.Events[name]
end

function RemoteService:GetFunction(name)
    return self.Functions[name]
end

function RemoteService:FireClient(player, eventName, payload)
    local remote = self.Events[eventName]
    if remote then
        remote:FireClient(player, payload)
    end
end

function RemoteService:Broadcast(eventName, payload)
    local remote = self.Events[eventName]
    if remote then
        remote:FireAllClients(payload)
    end
end

return RemoteService
