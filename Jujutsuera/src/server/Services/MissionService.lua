local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MissionConfig = require(ReplicatedStorage.Shared.Config.MissionConfig)
local ProgressionConfig = require(ReplicatedStorage.Shared.Config.ProgressionConfig)

local MissionService = {
    Name = "MissionService",
}

function MissionService:Init(services)
    self._services = services
end

function MissionService:_getMissionPool(player)
    local level = player:GetAttribute("Level") or 1
    local phase = ProgressionConfig.GetPhaseForLevel(level)
    local pool = {}

    for _, mission in ipairs(MissionConfig.BoardPools[phase.Key] or {}) do
        table.insert(pool, mission)
    end

    for _, mission in ipairs(MissionConfig.SpecialMissions or {}) do
        if self:_canAssignMission(player, mission) then
            table.insert(pool, mission)
        end
    end

    return pool
end

function MissionService:_findMissionById(id)
    for _, pool in pairs(MissionConfig.BoardPools) do
        for _, mission in ipairs(pool) do
            if mission.Id == id then
                return mission
            end
        end
    end

    for _, mission in ipairs(MissionConfig.SpecialMissions or {}) do
        if mission.Id == id then
            return mission
        end
    end

    return nil
end

function MissionService:_canAssignMission(player, mission)
    if type(mission) ~= "table" then
        return false
    end

    local level = player:GetAttribute("Level") or 1
    if mission.MinLevel and level < mission.MinLevel then
        return false
    end

    if mission.RequiresUnwitnessedDomain and player:GetAttribute("WitnessedDomain") == true then
        return false
    end

    return true
end

function MissionService:_applyMissionAttributes(player, mission, progress)
    if not mission then
        player:SetAttribute("ActiveMissionId", "")
        player:SetAttribute("ActiveMissionProgress", 0)
        player:SetAttribute("ActiveMissionGoal", 0)
        player:SetAttribute("ActiveMissionName", "")
        player:SetAttribute("ActiveMissionCategory", "")
        player:SetAttribute("ActiveMissionRewardXP", 0)
        player:SetAttribute("ActiveMissionRewardYen", 0)
        player:SetAttribute("ActiveMissionRewardFragments", 0)
        return
    end

    player:SetAttribute("ActiveMissionId", mission.Id)
    player:SetAttribute("ActiveMissionProgress", math.min(mission.Goal, math.max(0, progress or 0)))
    player:SetAttribute("ActiveMissionGoal", mission.Goal)
    player:SetAttribute("ActiveMissionName", mission.Name)
    player:SetAttribute("ActiveMissionCategory", mission.Category or "Side")
    player:SetAttribute("ActiveMissionRewardXP", mission.RewardXP or 0)
    player:SetAttribute("ActiveMissionRewardYen", mission.RewardYen or 0)
    player:SetAttribute("ActiveMissionRewardFragments", mission.RewardFragments or 0)
end

function MissionService:_setMission(player, mission)
    local profile = self._services:Get("DataService"):GetProfile(player)
    if not profile then
        return
    end

    profile.ActiveMissionId = mission.Id
    profile.ActiveMissionProgress = 0

    self:_applyMissionAttributes(player, mission, 0)
    self._services:Get("DataService"):MarkDirty(player)
    self:PushMissionUpdate(player)
end

function MissionService:AssignMission(player)
    if (player:GetAttribute("ActiveMissionId") or "") ~= "" then
        return false, "Conclua a missao atual antes de pegar outra."
    end

    local pool = self:_getMissionPool(player)
    if type(pool) ~= "table" or #pool == 0 then
        return false, "Nenhuma missao disponivel para o seu nivel atual."
    end

    local mission = pool[math.random(1, #pool)]
    self:_setMission(player, mission)
    return true, string.format("%s atribuida: %s.", mission.Category or "Missao", mission.Name)
end

function MissionService:TrackProgress(player, missionType, amount)
    local resolvedAmount = math.max(0, math.floor(tonumber(amount) or 0))
    if resolvedAmount <= 0 then
        return
    end

    local missionId = player:GetAttribute("ActiveMissionId")
    if missionId == "" then
        return
    end

    local mission = self:_findMissionById(missionId)
    if not mission or mission.Type ~= missionType then
        return
    end

    local progress = math.min(mission.Goal, (player:GetAttribute("ActiveMissionProgress") or 0) + resolvedAmount)
    self:_applyMissionAttributes(player, mission, progress)

    local profile = self._services:Get("DataService"):GetProfile(player)
    if profile then
        profile.ActiveMissionProgress = progress
        self._services:Get("DataService"):MarkDirty(player)
    end

    self:PushMissionUpdate(player)

    if progress >= mission.Goal then
        self:CompleteMission(player, mission)
    end
end

function MissionService:RestoreMissionState(player)
    local missionId = player:GetAttribute("ActiveMissionId")
    if missionId == "" then
        self:_applyMissionAttributes(player, nil, 0)
        self:PushMissionUpdate(player)
        return
    end

    local mission = self:_findMissionById(missionId)
    if not mission or not self:_canAssignMission(player, mission) then
        self:ClearMission(player, true)
        self:PushMissionUpdate(player)
        return
    end

    self:_applyMissionAttributes(player, mission, player:GetAttribute("ActiveMissionProgress") or 0)
    self:PushMissionUpdate(player)
end

function MissionService:ClearMission(player, skipPush)
    local profile = self._services:Get("DataService"):GetProfile(player)
    if profile then
        profile.ActiveMissionId = ""
        profile.ActiveMissionProgress = 0
        self._services:Get("DataService"):MarkDirty(player)
    end

    self:_applyMissionAttributes(player, nil, 0)

    if not skipPush then
        self:PushMissionUpdate(player)
    end
end

function MissionService:_buildRewardText(mission)
    local rewardParts = {}

    if (mission.RewardXP or 0) > 0 then
        table.insert(rewardParts, string.format("+%d XP", mission.RewardXP))
    end

    if (mission.RewardYen or 0) > 0 then
        table.insert(rewardParts, string.format("+%d Yen", mission.RewardYen))
    end

    if (mission.RewardFragments or 0) > 0 then
        table.insert(rewardParts, string.format("+%d Fragmentos", mission.RewardFragments))
    end

    return table.concat(rewardParts, ", ")
end

function MissionService:CompleteMission(player, mission)
    self._services:Get("ProgressionService"):AddXP(player, mission.RewardXP)
    self._services:Get("ProgressionService"):AddYen(player, mission.RewardYen or 0)
    self._services:Get("ProgressionService"):AddFragments(player, mission.RewardFragments or 0)
    self:ClearMission(player, true)

    self._services:Get("RemoteService"):FireClient(player, "ServerMessage", {
        Type = "Success",
        Text = string.format("Missao concluida: %s (%s).", mission.Name, self:_buildRewardText(mission)),
    })

    self:PushMissionUpdate(player)
end

function MissionService:GetMissionSnapshot(player)
    return {
        Id = player:GetAttribute("ActiveMissionId"),
        Name = player:GetAttribute("ActiveMissionName"),
        Category = player:GetAttribute("ActiveMissionCategory"),
        Progress = player:GetAttribute("ActiveMissionProgress") or 0,
        Goal = player:GetAttribute("ActiveMissionGoal") or 0,
        RewardXP = player:GetAttribute("ActiveMissionRewardXP") or 0,
        RewardYen = player:GetAttribute("ActiveMissionRewardYen") or 0,
        RewardFragments = player:GetAttribute("ActiveMissionRewardFragments") or 0,
    }
end

function MissionService:PushMissionUpdate(player)
    self._services:Get("RemoteService"):FireClient(player, "MissionUpdate", self:GetMissionSnapshot(player))
end

return MissionService
