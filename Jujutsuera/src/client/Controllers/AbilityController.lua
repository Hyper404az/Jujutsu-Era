local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameplayConfig = require(ReplicatedStorage.Shared.Config.GameplayConfig)

local AbilityController = {}
AbilityController.__index = AbilityController

local KEY_TO_ABILITY_INDEX = {
    [Enum.KeyCode.One] = 1,
    [Enum.KeyCode.Two] = 2,
    [Enum.KeyCode.Three] = 3,
    [Enum.KeyCode.Four] = 4,
    [Enum.KeyCode.Five] = 5,
}

function AbilityController.new(network)
    local self = setmetatable({}, AbilityController)
    self._network = network
    self._player = Players.LocalPlayer
    self._mouse = self._player:GetMouse()
    self._abilities = {}
    self:_refreshAbilityMap()
    self:_bind()
    return self
end

function AbilityController:_refreshAbilityMap()
    local state = self._network:Invoke("GetClientState")
    self._abilities = state.Abilities or {}
end

function AbilityController:_resolveHumanoidModel(instance)
    if typeof(instance) ~= "Instance" then
        return nil
    end

    local model = instance:IsA("Model") and instance or instance:FindFirstAncestorOfClass("Model")
    if not model or model == self._player.Character then
        return nil
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    if humanoid and root and humanoid.Health > 0 then
        return model, root
    end

    return nil
end

function AbilityController:_findBestTarget()
    local localCharacter = self._player.Character
    local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")
    if not localRoot then
        return nil
    end

    local mouseTargetModel, mouseRoot = self:_resolveHumanoidModel(self._mouse.Target)
    if mouseTargetModel and (mouseRoot.Position - localRoot.Position).Magnitude <= GameplayConfig.TargetAcquireDistance then
        return mouseTargetModel
    end

    local closestModel = nil
    local closestDistance = math.huge

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= self._player and otherPlayer.Character then
            local otherRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
            if otherRoot and humanoid and humanoid.Health > 0 then
                local distance = (otherRoot.Position - localRoot.Position).Magnitude
                if distance < closestDistance and distance <= GameplayConfig.TargetAcquireDistance then
                    closestDistance = distance
                    closestModel = otherPlayer.Character
                end
            end
        end
    end

    return closestModel
end

function AbilityController:_bind()
    self._player:GetAttributeChangedSignal("Clan"):Connect(function()
        self:_refreshAbilityMap()
    end)
    self._player:GetAttributeChangedSignal("SubTechnique"):Connect(function()
        self:_refreshAbilityMap()
    end)
    self._player:GetAttributeChangedSignal("Mastery"):Connect(function()
        self:_refreshAbilityMap()
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if input.KeyCode == Enum.KeyCode.V then
            self._network:Fire("EnchantedModeRequest")
            return
        end

        local abilityIndex = KEY_TO_ABILITY_INDEX[input.KeyCode]
        if not abilityIndex then
            return
        end

        local ability = self._abilities[abilityIndex]
        if not ability then
            return
        end

        local target = self:_findBestTarget()
        local targetPlayer = target and Players:GetPlayerFromCharacter(target) or nil
        self._network:Fire("AbilityRequest", {
            AbilityId = ability.Id,
            TargetUserId = targetPlayer and targetPlayer.UserId or nil,
            TargetModel = target,
        })
    end)
end

return AbilityController
