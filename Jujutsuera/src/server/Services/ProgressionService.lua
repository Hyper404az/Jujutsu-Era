local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityConfig = require(ReplicatedStorage.Shared.Config.AbilityConfig)
local FactionConfig = require(ReplicatedStorage.Shared.Config.FactionConfig)
local ProgressionConfig = require(ReplicatedStorage.Shared.Config.ProgressionConfig)

local ProgressionService = {
    Name = "ProgressionService",
}

function ProgressionService:Init(services)
    self._services = services
end

function ProgressionService:GetXPToNextLevel(level)
    return ProgressionConfig.GetXPToNextLevel(level)
end

function ProgressionService:_syncProfileValue(player, key, value)
    local profile = self._services:Get("DataService"):GetProfile(player)
    if not profile then
        return
    end

    profile[key] = value
    self._services:Get("DataService"):MarkDirty(player)
end

function ProgressionService:GetPhaseForPlayer(player)
    return ProgressionConfig.GetPhaseForLevel(player:GetAttribute("Level") or 1)
end

function ProgressionService:RefreshProgressionState(player)
    local level = math.clamp(math.floor(player:GetAttribute("Level") or 1), 1, ProgressionConfig.MaxLevel)
    local phase = ProgressionConfig.GetPhaseForLevel(level)
    local xpToNextLevel = self:GetXPToNextLevel(level)
    local xp = math.max(0, math.floor(player:GetAttribute("XP") or 0))

    if xpToNextLevel > 0 then
        xp = math.min(xp, xpToNextLevel - 1)
    else
        xp = 0
    end

    local faction = player:GetAttribute("Faction")
    if type(faction) ~= "string" or faction == "" then
        faction = FactionConfig.DefaultFaction
    end

    player:SetAttribute("Level", level)
    player:SetAttribute("XP", xp)
    player:SetAttribute("XPToNextLevel", xpToNextLevel)
    player:SetAttribute("Rank", phase.Rank)
    player:SetAttribute("ProgressionPhase", phase.Name)
    player:SetAttribute("Faction", faction)
    player:SetAttribute("CanChooseFaction", ProgressionConfig.CanChooseFaction(level))

    self:_syncProfileValue(player, "Level", level)
    self:_syncProfileValue(player, "XP", xp)
    self:_syncProfileValue(player, "Rank", phase.Rank)
    self:_syncProfileValue(player, "Faction", faction)
end

function ProgressionService:_addNumericAttribute(player, key, amount)
    local resolvedAmount = math.floor(tonumber(amount) or 0)
    if resolvedAmount == 0 then
        return player:GetAttribute(key) or 0
    end

    local value = math.max(0, math.floor((player:GetAttribute(key) or 0) + resolvedAmount))
    player:SetAttribute(key, value)
    self:_syncProfileValue(player, key, value)

    return value
end

function ProgressionService:AddXP(player, amount)
    local resolvedAmount = math.max(0, math.floor(tonumber(amount) or 0))
    if resolvedAmount <= 0 then
        return
    end

    local currentLevel = math.clamp(math.floor(player:GetAttribute("Level") or 1), 1, ProgressionConfig.MaxLevel)
    local nextXP = math.max(0, math.floor(player:GetAttribute("XP") or 0)) + resolvedAmount

    while currentLevel < ProgressionConfig.MaxLevel do
        local xpToNextLevel = self:GetXPToNextLevel(currentLevel)
        if xpToNextLevel <= 0 or nextXP < xpToNextLevel then
            break
        end

        nextXP = nextXP - xpToNextLevel
        currentLevel += 1
    end

    if currentLevel >= ProgressionConfig.MaxLevel then
        currentLevel = ProgressionConfig.MaxLevel
        nextXP = 0
    end

    player:SetAttribute("Level", currentLevel)
    player:SetAttribute("XP", nextXP)
    self:RefreshProgressionState(player)
end

function ProgressionService:AddSpins(player, amount)
    self:_addNumericAttribute(player, "Spins", amount)
end

function ProgressionService:AddYen(player, amount)
    self:_addNumericAttribute(player, "Yen", amount)
end

function ProgressionService:AddFragments(player, amount)
    self:_addNumericAttribute(player, "Fragments", amount)
end

function ProgressionService:AddMastery(player, amount)
    self:_addNumericAttribute(player, "Mastery", amount)
end

function ProgressionService:AddStrength(player, amount)
    self:_addNumericAttribute(player, "Strength", amount)
end

function ProgressionService:RecordAbilityUse(player, abilityId)
    if AbilityConfig.Abilities[abilityId] then
        self:AddMastery(player, 1)
        self._services:Get("MissionService"):TrackProgress(player, "UseAbility", 1)
    end
end

return ProgressionService
