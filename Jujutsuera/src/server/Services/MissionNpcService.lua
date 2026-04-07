local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameplayConfig = require(ReplicatedStorage.Shared.Config.GameplayConfig)

local MissionNpcService = {
    Name = "MissionNpcService",
}

function MissionNpcService:Init(services)
    self._services = services
    self._bound = {}
end

function MissionNpcService:_bindClickDetector(model, clickDetector)
    if self._bound[clickDetector] then
        return
    end

    self._bound[clickDetector] = clickDetector.MouseClick:Connect(function(player)
        local success, text = self._services:Get("MissionService"):AssignMission(player)
        self._services:Get("RemoteService"):FireClient(player, "ServerMessage", {
            Type = success and "Info" or "Error",
            Text = text or "Falha ao atribuir missao.",
        })
    end)
end

function MissionNpcService:_bindPrompt(model, prompt)
    if self._bound[prompt] then
        return
    end

    self._bound[prompt] = prompt.Triggered:Connect(function(player)
        local success, text = self._services:Get("MissionService"):AssignMission(player)
        self._services:Get("RemoteService"):FireClient(player, "ServerMessage", {
            Type = success and "Info" or "Error",
            Text = text or "Falha ao atribuir missao.",
        })
    end)
end

function MissionNpcService:_ensureInteraction(model)
    local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt then
        prompt.ObjectText = "Mission Board"
        prompt.ActionText = "Get Mission"
        self:_bindPrompt(model, prompt)
        return
    end

    local primary = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
    if not primary then
        return
    end

    local clickDetector = primary:FindFirstChildOfClass("ClickDetector")
    if not clickDetector then
        clickDetector = Instance.new("ClickDetector")
        clickDetector.MaxActivationDistance = 18
        clickDetector.Parent = primary
    end

    self:_bindClickDetector(model, clickDetector)
end

function MissionNpcService:_registerModel(model)
    if not model:IsA("Model") then
        return
    end

    self:_ensureInteraction(model)
end

function MissionNpcService:Start()
    for _, instance in ipairs(CollectionService:GetTagged(GameplayConfig.MissionNpcTag)) do
        self:_registerModel(instance)
    end

    for _, instance in ipairs(workspace:GetDescendants()) do
        if instance:IsA("Model") and string.lower(instance.Name) == "gojo" then
            self:_registerModel(instance)
        end
    end

    CollectionService:GetInstanceAddedSignal(GameplayConfig.MissionNpcTag):Connect(function(instance)
        self:_registerModel(instance)
    end)

    workspace.DescendantAdded:Connect(function(instance)
        if instance:IsA("Model") and string.lower(instance.Name) == "gojo" then
            self:_registerModel(instance)
        end
    end)
end

return MissionNpcService
