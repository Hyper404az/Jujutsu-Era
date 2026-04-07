local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AttributeConfig = require(ReplicatedStorage.Shared.Config.AttributeConfig)
local FactionConfig = require(ReplicatedStorage.Shared.Config.FactionConfig)
local ProgressionConfig = require(ReplicatedStorage.Shared.Config.ProgressionConfig)

local DataService = {
    Name = "DataService",
    StoreName = "JujutsuEra_PlayerData_v1",
}

function DataService:Init()
    self._store = DataStoreService:GetDataStore(self.StoreName)
    self._profiles = {}
    self._sessionDirty = {}
end

function DataService:_buildDefaultProfile()
    local profile = {}

    for _, key in ipairs(AttributeConfig.PersistedKeys) do
        profile[key] = AttributeConfig.Defaults[key]
    end

    return profile
end

function DataService:_normalizeProfile(stored)
    local profile = self:_buildDefaultProfile()

    if type(stored) == "table" then
        for key, value in pairs(stored) do
            if profile[key] ~= nil then
                profile[key] = value
            end
        end
    end

    local numberKeys = {
        Level = true,
        XP = true,
        Mastery = true,
        Spins = true,
        ClanLegendaryPity = true,
        ClanEpicPity = true,
        Yen = true,
        Fragments = true,
        Strength = true,
        ActiveMissionProgress = true,
    }

    local booleanKeys = {
        WitnessedDomain = true,
    }

    local stringKeys = {
        Clan = true,
        SubTechnique = true,
        ZeninType = true,
        Rank = true,
        Faction = true,
        ActiveMissionId = true,
    }

    for key in pairs(numberKeys) do
        profile[key] = math.max(0, math.floor(tonumber(profile[key]) or 0))
    end

    for key in pairs(booleanKeys) do
        profile[key] = profile[key] == true
    end

    for key in pairs(stringKeys) do
        if type(profile[key]) ~= "string" then
            profile[key] = AttributeConfig.Defaults[key]
        end
    end

    profile.Level = math.clamp(profile.Level, 1, ProgressionConfig.MaxLevel)
    profile.XP = math.max(0, profile.XP)

    local xpToNextLevel = ProgressionConfig.GetXPToNextLevel(profile.Level)
    if xpToNextLevel > 0 then
        profile.XP = math.min(profile.XP, xpToNextLevel - 1)
    else
        profile.XP = 0
    end

    if profile.Faction == "" then
        profile.Faction = FactionConfig.DefaultFaction
    end

    local phase = ProgressionConfig.GetPhaseForLevel(profile.Level)
    profile.Rank = phase.Rank

    return profile
end

function DataService:LoadProfile(player)
    local success, stored = pcall(function()
        return self._store:GetAsync(tostring(player.UserId))
    end)

    local profile = self:_normalizeProfile(success and stored or nil)

    self._profiles[player] = profile
    self._sessionDirty[player] = false
    return profile
end

function DataService:GetProfile(player)
    return self._profiles[player]
end

function DataService:MarkDirty(player)
    self._sessionDirty[player] = true
end

function DataService:SaveProfile(player)
    local profile = self._profiles[player]
    if not profile then
        return false
    end

    local success = pcall(function()
        self._store:SetAsync(tostring(player.UserId), profile)
    end)

    if success then
        self._sessionDirty[player] = false
    end

    return success
end

function DataService:FlushAll()
    for _, player in ipairs(Players:GetPlayers()) do
        self:SaveProfile(player)
    end
end

function DataService:Start()
    Players.PlayerRemoving:Connect(function(player)
        self:SaveProfile(player)
        self._profiles[player] = nil
        self._sessionDirty[player] = nil
    end)

    game:BindToClose(function()
        self:FlushAll()
    end)
end

return DataService
