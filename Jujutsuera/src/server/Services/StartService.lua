local StarterPlayer = game:GetService("StarterPlayer")

local StartService = {
    Name = "StartService",
}

function StartService:Init(services)
    self._services = services
end

function StartService:Start()
    StarterPlayer.CharacterRigType = Enum.HumanoidRigType.R6

    local remoteService = self._services:Get("RemoteService")

    remoteService:GetEvent("PlayRequest").OnServerEvent:Connect(function(player)
        player:SetAttribute("HasStarted", true)
        player:LoadCharacter()
    end)

    remoteService:GetEvent("ClanSpinRequest").OnServerEvent:Connect(function(player)
        self._services:Get("ClanService"):HandleSpinRequest(player)
    end)

    remoteService:GetEvent("ClanSpinDecisionRequest").OnServerEvent:Connect(function(player, payload)
        self._services:Get("ClanService"):HandleSpinDecisionRequest(player, payload)
    end)

    remoteService:GetEvent("AbilityRequest").OnServerEvent:Connect(function(player, payload)
        self._services:Get("AbilityService"):ExecuteAbility(player, payload)
    end)

    remoteService:GetEvent("RequestDomainActivation").OnServerEvent:Connect(function(player)
        self._services:Get("DomainService"):HandleActivationRequest(player)
    end)

    remoteService:GetEvent("EnchantedModeRequest").OnServerEvent:Connect(function(player)
        local success, reason = self._services:Get("EnchantedModeService"):Activate(player)
        if reason then
            remoteService:FireClient(player, "ServerMessage", {
                Type = success and "Success" or "Error",
                Text = reason,
            })
        end
    end)

    remoteService:GetEvent("TrainingHitRequest").OnServerEvent:Connect(function(player, payload)
        self._services:Get("TrainingService"):HandleTrainingHit(player, payload)
    end)

    remoteService:GetFunction("GetClientState").OnServerInvoke = function(player)
        local missionSnapshot = self._services:Get("MissionService"):GetMissionSnapshot(player)

        return {
            Abilities = self._services:Get("AbilityService"):GetAvailableAbilities(player),
            Mission = missionSnapshot,
            Clan = player:GetAttribute("Clan"),
            SubTechnique = player:GetAttribute("SubTechnique"),
            Spins = player:GetAttribute("Spins"),
            ClanLegendaryPity = player:GetAttribute("ClanLegendaryPity"),
            ClanEpicPity = player:GetAttribute("ClanEpicPity"),
            Yen = player:GetAttribute("Yen"),
            Fragments = player:GetAttribute("Fragments"),
            Level = player:GetAttribute("Level"),
            XP = player:GetAttribute("XP"),
            XPToNextLevel = player:GetAttribute("XPToNextLevel"),
            Mastery = player:GetAttribute("Mastery"),
            Rank = player:GetAttribute("Rank"),
            ProgressionPhase = player:GetAttribute("ProgressionPhase"),
            Faction = player:GetAttribute("Faction"),
            CanChooseFaction = player:GetAttribute("CanChooseFaction"),
            HasDomain = player:GetAttribute("HasDomain"),
            DomainActive = player:GetAttribute("DomainActive"),
            DomainCooldown = player:GetAttribute("DomainCooldown"),
            ZeninType = player:GetAttribute("ZeninType"),
        }
    end

end

return StartService
