local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameplayConfig = require(ReplicatedStorage.Shared.Config.GameplayConfig)
local TrainingConfig = require(ReplicatedStorage.Shared.Config.TrainingConfig)

local TrainingService = {
    Name = "TrainingService",
}

function TrainingService:Init(services)
    self._services = services
    self._hitCooldowns = {}
    self._hitCounts = {}
end

function TrainingService:_resolveDummy(instance)
    if typeof(instance) ~= "Instance" then
        return nil
    end

    local model = instance:IsA("Model") and instance or instance:FindFirstAncestorOfClass("Model")
    if model and CollectionService:HasTag(model, TrainingConfig.DummyTag) then
        return model
    end

    return nil
end

function TrainingService:HandleTrainingHit(player, payload)
    local dummy = self:_resolveDummy(payload and payload.Target)
    if not dummy then
        return
    end

    local playerRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local dummyRoot = dummy.PrimaryPart or dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChildWhichIsA("BasePart")
    if not playerRoot or not dummyRoot then
        return
    end

    if (playerRoot.Position - dummyRoot.Position).Magnitude > GameplayConfig.TrainingHitDistance then
        return
    end

    local now = os.clock()
    local cooldown = self._hitCooldowns[player] or 0
    if now < cooldown then
        return
    end

    self._hitCooldowns[player] = now + GameplayConfig.TrainingHitCooldown
    self._hitCounts[player] = (self._hitCounts[player] or 0) + 1

    self._services:Get("ProgressionService"):AddMastery(player, TrainingConfig.MasteryPerHit)
    self._services:Get("MissionService"):TrackProgress(player, "Train", 1)

    if self._hitCounts[player] % TrainingConfig.StrengthHitsPerPoint == 0 then
        self._services:Get("ProgressionService"):AddStrength(player, 1)
    end
end

return TrainingService
