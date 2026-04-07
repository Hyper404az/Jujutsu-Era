local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClanConfig = require(ReplicatedStorage.Shared.Config.ClanConfig)

local PITY_LIMITS = {
    Legendary = 150,
    Epic = 50,
}

local ClanService = {
    Name = "ClanService",
}

function ClanService:Init(services)
    self._services = services
    self._spinLocks = {}
    self._pendingSpinPreviews = {}
end

function ClanService:GetClanDefinition(clanName)
    return ClanConfig.Clans[clanName] or ClanConfig.Clans[ClanConfig.DefaultClan]
end

function ClanService:GetPlayerClanDefinition(player)
    return self:GetClanDefinition(player:GetAttribute("Clan"))
end

function ClanService:GetPlayerSubTechnique(player)
    return player:GetAttribute("SubTechnique") or ""
end

function ClanService:GetPlayerZeninType(player)
    return player:GetAttribute("ZeninType") or ""
end

function ClanService:GetStatModifiers(player)
    return self:GetPlayerClanDefinition(player).Modifiers
end

function ClanService:_rollZeninSubTechnique()
    return ClanConfig.ZeninSubTechniques[math.random(1, #ClanConfig.ZeninSubTechniques)]
end

function ClanService:RollClan()
    local totalWeight = 0
    for _, config in pairs(ClanConfig.Clans) do
        totalWeight = totalWeight + config.Weight
    end

    local roll = math.random() * totalWeight
    local cursor = 0

    for clanName, config in pairs(ClanConfig.Clans) do
        cursor = cursor + config.Weight
        if roll <= cursor then
            return clanName
        end
    end

    return ClanConfig.DefaultClan
end

function ClanService:_buildSpinPreview()
    local clanName = self:RollClan()
    local clanDefinition = self:GetClanDefinition(clanName)

    return {
        Clan = clanName,
        DisplayName = clanDefinition.DisplayName or clanName,
        Rarity = clanDefinition.Rarity,
        SubTechnique = clanName == "Zenin" and self:_rollZeninSubTechnique() or "",
    }
end

function ClanService:_assignZeninSubTechnique(player, subTechniqueOverride)
    local profile = self._services:Get("DataService"):GetProfile(player)
    if not profile then
        return ""
    end

    local subTechnique = type(subTechniqueOverride) == "string" and subTechniqueOverride or ""
    if subTechnique == "" then
        subTechnique = self:_rollZeninSubTechnique()
    end

    profile.SubTechnique = subTechnique
    profile.ZeninType = subTechnique
    player:SetAttribute("SubTechnique", subTechnique)
    player:SetAttribute("ZeninType", subTechnique)

    return subTechnique
end

function ClanService:_setPityAttributes(player, profile)
    player:SetAttribute("ClanLegendaryPity", profile.ClanLegendaryPity or 0)
    player:SetAttribute("ClanEpicPity", profile.ClanEpicPity or 0)
end

function ClanService:_applyPityProgress(profile, rarity)
    if rarity == "Legendary" then
        profile.ClanLegendaryPity = 0
    else
        profile.ClanLegendaryPity = math.clamp((profile.ClanLegendaryPity or 0) + 1, 0, PITY_LIMITS.Legendary)
    end

    if rarity == "Legendary" or rarity == "Epic" then
        profile.ClanEpicPity = 0
    else
        profile.ClanEpicPity = math.clamp((profile.ClanEpicPity or 0) + 1, 0, PITY_LIMITS.Epic)
    end
end

function ClanService:AssignClan(player, clanName, reason, subTechniqueOverride)
    local profile = self._services:Get("DataService"):GetProfile(player)
    if not profile then
        return ClanConfig.DefaultClan, ""
    end

    local resolvedClan = ClanConfig.Clans[clanName] and clanName or ClanConfig.DefaultClan
    profile.Clan = resolvedClan
    profile.SubTechnique = ""
    profile.ZeninType = ""

    player:SetAttribute("Clan", resolvedClan)
    player:SetAttribute("SubTechnique", "")
    player:SetAttribute("ZeninType", "")

    local assignedSubTechnique = ""
    if resolvedClan == "Zenin" then
        assignedSubTechnique = self:_assignZeninSubTechnique(player, subTechniqueOverride)
    end

    self._services:Get("DataService"):MarkDirty(player)

    local playerStateService = self._services:Get("PlayerStateService")
    if playerStateService then
        playerStateService:RefreshDerivedAttributes(player)
    end

    local domainService = self._services:Get("DomainService")
    if domainService then
        domainService:RefreshPlayerDomainState(player)
    end

    if reason and reason ~= "Spin" and reason ~= "SpinConfirm" then
        self._services:Get("RemoteService"):FireClient(player, "ServerMessage", {
            Type = "Info",
            Text = string.format("Clan updated to %s (%s).", resolvedClan, reason),
        })
    end

    return resolvedClan, assignedSubTechnique
end

function ClanService:HandleSpinRequest(player)
    if self._spinLocks[player] then
        return
    end

    self._spinLocks[player] = true

    local profile = self._services:Get("DataService"):GetProfile(player)
    if not profile then
        self._spinLocks[player] = nil
        return
    end

    if self._pendingSpinPreviews[player] then
        self._services:Get("RemoteService"):FireClient(player, "ServerMessage", {
            Type = "Error",
            Text = "Resolve the current clan preview before spinning again.",
        })
        self._spinLocks[player] = nil
        return
    end

    if (player:GetAttribute("Spins") or 0) <= 0 then
        self._services:Get("RemoteService"):FireClient(player, "ServerMessage", {
            Type = "Error",
            Text = "No spins available.",
        })
        self._spinLocks[player] = nil
        return
    end

    profile.Spins = math.max(0, (profile.Spins or 0) - 1)
    player:SetAttribute("Spins", profile.Spins)

    local preview = self:_buildSpinPreview()
    self._pendingSpinPreviews[player] = preview
    self:_applyPityProgress(profile, preview.Rarity)
    self:_setPityAttributes(player, profile)
    self._services:Get("DataService"):MarkDirty(player)

    self._services:Get("RemoteService"):FireClient(player, "ClanSpinPreview", {
        Clan = preview.Clan,
        DisplayName = preview.DisplayName,
        Spins = profile.Spins,
        SubTechnique = preview.SubTechnique,
        Rarity = preview.Rarity,
        ClanLegendaryPity = profile.ClanLegendaryPity or 0,
        ClanEpicPity = profile.ClanEpicPity or 0,
    })

    self._spinLocks[player] = nil
end

function ClanService:HandleSpinDecisionRequest(player, payload)
    if self._spinLocks[player] then
        return
    end

    self._spinLocks[player] = true

    local profile = self._services:Get("DataService"):GetProfile(player)
    local preview = self._pendingSpinPreviews[player]
    if not profile or not preview then
        self._services:Get("RemoteService"):FireClient(player, "ServerMessage", {
            Type = "Error",
            Text = "No clan preview is waiting for confirmation.",
        })
        self._spinLocks[player] = nil
        return
    end

    self._pendingSpinPreviews[player] = nil

    local accepted = type(payload) == "table" and payload.Accept == true
    local remoteService = self._services:Get("RemoteService")

    if accepted then
        local clanName, assignedSubTechnique = self:AssignClan(player, preview.Clan, "SpinConfirm", preview.SubTechnique)

        remoteService:FireClient(player, "ClanSpinResult", {
            Accepted = true,
            Clan = clanName,
            Spins = profile.Spins,
            SubTechnique = assignedSubTechnique,
            Rarity = self:GetClanDefinition(clanName).Rarity,
            ClanLegendaryPity = profile.ClanLegendaryPity or 0,
            ClanEpicPity = profile.ClanEpicPity or 0,
        })
    else
        remoteService:FireClient(player, "ClanSpinResult", {
            Accepted = false,
            KeptClan = true,
            Clan = player:GetAttribute("Clan"),
            Spins = profile.Spins,
            SubTechnique = player:GetAttribute("SubTechnique"),
            Rarity = self:GetPlayerClanDefinition(player).Rarity,
            PreviewClan = preview.Clan,
            PreviewSubTechnique = preview.SubTechnique,
            ClanLegendaryPity = profile.ClanLegendaryPity or 0,
            ClanEpicPity = profile.ClanEpicPity or 0,
        })
    end

    self._spinLocks[player] = nil
end

return ClanService
