local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AttributeConfig = require(ReplicatedStorage.Shared.Config.AttributeConfig)
local GameplayConfig = require(ReplicatedStorage.Shared.Config.GameplayConfig)
local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)

local PlayerStateService = {
    Name = "PlayerStateService",
}

function PlayerStateService:Init(services)
    self._services = services
    self._humanoidConnections = {}
    self._rigReloadGuard = {}
end

function PlayerStateService:_applyDefaults(player)
    for key, value in pairs(AttributeConfig.Defaults) do
        if player:GetAttribute(key) == nil then
            player:SetAttribute(key, value)
        end
    end
end

function PlayerStateService:RefreshDerivedAttributes(player)
    local modifiers = self._services:Get("ClanService"):GetStatModifiers(player)
    local maxHealth = math.floor(GameplayConfig.BaseHealth * (modifiers.MaxHealthMultiplier or 1))
    local maxFocus = math.floor(GameplayConfig.BaseFocus * (modifiers.MaxFocusMultiplier or 1))

    player:SetAttribute("MaxHealth", maxHealth)
    player:SetAttribute("MaxFocus", maxFocus)

    self:SetHealth(player, math.clamp(player:GetAttribute("Health") or maxHealth, 0, maxHealth))
    self:SetFocus(player, math.clamp(player:GetAttribute("Focus") or maxFocus, 0, maxFocus))
end

function PlayerStateService:SetHealth(player, value)
    local maxHealth = player:GetAttribute("MaxHealth") or GameplayConfig.BaseHealth
    local clamped = math.clamp(value, 0, maxHealth)
    player:SetAttribute("Health", clamped)

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.MaxHealth = maxHealth
        humanoid.Health = clamped
    end

    if clamped <= 0 then
        self:HandleDeath(player)
    end
end

function PlayerStateService:AdjustHealth(player, delta)
    self:SetHealth(player, (player:GetAttribute("Health") or 0) + delta)
end

function PlayerStateService:SetFocus(player, value)
    local maxFocus = player:GetAttribute("MaxFocus") or GameplayConfig.BaseFocus
    player:SetAttribute("Focus", math.clamp(value, 0, maxFocus))
end

function PlayerStateService:AdjustFocus(player, delta)
    self:SetFocus(player, (player:GetAttribute("Focus") or 0) + delta)
end

function PlayerStateService:ConsumeFocus(player, amount)
    local current = player:GetAttribute("Focus") or 0
    if current < amount then
        return false
    end

    self:SetFocus(player, current - amount)
    return true
end

function PlayerStateService:GetCooldowns(player)
    return Serialization.Decode(player:GetAttribute("CooldownStates"))
end

function PlayerStateService:SetCooldowns(player, stateTable)
    player:SetAttribute("CooldownStates", Serialization.Encode(stateTable))
end

function PlayerStateService:SetStunned(player, value)
    player:SetAttribute("IsStunned", value == true)
end

function PlayerStateService:HandleDeath(player)
    if player:GetAttribute("IsAlive") == false then
        return
    end

    player:SetAttribute("IsAlive", false)
    player:SetAttribute("EnchantedMode", false)

    task.defer(function()
        if player.Parent == Players then
            player:LoadCharacter()
        end
    end)
end

function PlayerStateService:_bindCharacter(player, character)
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

    if humanoid.RigType ~= Enum.HumanoidRigType.R6 then
        local lastReloadAt = self._rigReloadGuard[player] or 0
        if os.clock() - lastReloadAt > 2 then
            self._rigReloadGuard[player] = os.clock()
            task.defer(function()
                if player.Parent == Players then
                    player:LoadCharacter()
                end
            end)
        end
        return
    end

    self._rigReloadGuard[player] = nil

    if self._humanoidConnections[player] then
        self._humanoidConnections[player]:Disconnect()
        self._humanoidConnections[player] = nil
    end

    self:RefreshDerivedAttributes(player)
    player:SetAttribute("IsAlive", true)
    player:SetAttribute("IsStunned", false)
    player:SetAttribute("DomainLocked", false)

    self._humanoidConnections[player] = humanoid.HealthChanged:Connect(function(health)
        player:SetAttribute("Health", math.max(0, health))
        if health <= 0 then
            self:HandleDeath(player)
        end
    end)
end

function PlayerStateService:LoadPlayerState(player, profile)
    self:_applyDefaults(player)

    player:SetAttribute("Clan", profile.Clan)
    player:SetAttribute("SubTechnique", profile.SubTechnique or "")
    player:SetAttribute("ZeninType", profile.ZeninType or profile.SubTechnique or "")
    player:SetAttribute("Level", profile.Level or 1)
    player:SetAttribute("XP", profile.XP or 0)
    player:SetAttribute("XPToNextLevel", AttributeConfig.Defaults.XPToNextLevel)
    player:SetAttribute("Mastery", profile.Mastery or 0)
    player:SetAttribute("Spins", profile.Spins or 0)
    player:SetAttribute("ClanLegendaryPity", profile.ClanLegendaryPity or 0)
    player:SetAttribute("ClanEpicPity", profile.ClanEpicPity or 0)
    player:SetAttribute("Yen", profile.Yen or 0)
    player:SetAttribute("Fragments", profile.Fragments or 0)
    player:SetAttribute("Strength", profile.Strength or 0)
    player:SetAttribute("WitnessedDomain", profile.WitnessedDomain == true)
    player:SetAttribute("HasDomain", false)
    player:SetAttribute("DomainActive", false)
    player:SetAttribute("DomainCooldown", 0)
    player:SetAttribute("Rank", profile.Rank or "Grade 4")
    player:SetAttribute("ProgressionPhase", AttributeConfig.Defaults.ProgressionPhase)
    player:SetAttribute("Faction", profile.Faction or AttributeConfig.Defaults.Faction)
    player:SetAttribute("CanChooseFaction", false)
    player:SetAttribute("ActiveMissionId", profile.ActiveMissionId or "")
    player:SetAttribute("ActiveMissionProgress", profile.ActiveMissionProgress or 0)
    player:SetAttribute("ActiveMissionGoal", 0)
    player:SetAttribute("ActiveMissionName", "")
    player:SetAttribute("ActiveMissionCategory", "")
    player:SetAttribute("ActiveMissionRewardXP", 0)
    player:SetAttribute("ActiveMissionRewardYen", 0)
    player:SetAttribute("ActiveMissionRewardFragments", 0)
    player:SetAttribute("CooldownStates", "{}")
    player:SetAttribute("HasStarted", false)
    player:SetAttribute("EnchantedMode", false)
    player:SetAttribute("IsStunned", false)
    player:SetAttribute("DomainLocked", false)

    self:RefreshDerivedAttributes(player)
    self:SetHealth(player, player:GetAttribute("MaxHealth"))
    self:SetFocus(player, player:GetAttribute("MaxFocus"))
    self._services:Get("ProgressionService"):RefreshProgressionState(player)
    self._services:Get("MissionService"):RestoreMissionState(player)

    player.CharacterAdded:Connect(function(character)
        self:_bindCharacter(player, character)
    end)

    if player.Character then
        task.defer(function()
            if player.Character then
                self:_bindCharacter(player, player.Character)
            end
        end)
    end
end

function PlayerStateService:_tickRegen()
    while true do
        task.wait(GameplayConfig.RegenTick)
        self._services:Get("SixEyesService"):TickRecovery()

        for _, player in ipairs(Players:GetPlayers()) do
            if player:GetAttribute("HasStarted") and player:GetAttribute("IsAlive") then
                local modifiers = self._services:Get("ClanService"):GetStatModifiers(player)
                local regenMultiplier = modifiers.RegenMultiplier or 1

                if modifiers.SixEyes then
                    regenMultiplier = regenMultiplier * self._services:Get("SixEyesService"):GetRegenBonus(player)
                end

                self:AdjustHealth(player, GameplayConfig.HealthRegenPerTick * regenMultiplier)
                self:AdjustFocus(player, GameplayConfig.FocusRegenPerTick * regenMultiplier)
            end
        end
    end
end

function PlayerStateService:Start()
    Players.PlayerAdded:Connect(function(player)
        local profile = self._services:Get("DataService"):LoadProfile(player)
        self:LoadPlayerState(player, profile)
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        local profile = self._services:Get("DataService"):LoadProfile(player)
        self:LoadPlayerState(player, profile)
    end

    task.spawn(function()
        self:_tickRegen()
    end)
end

return PlayerStateService
