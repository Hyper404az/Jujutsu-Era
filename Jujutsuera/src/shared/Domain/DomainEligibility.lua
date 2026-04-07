local DomainConfig = require(script.Parent.DomainConfig)

local DomainEligibility = {}

function DomainEligibility.ResolveDomainKey(player)
    local clan = player:GetAttribute("Clan")
    local zeninType = player:GetAttribute("ZeninType")

    if clan == "Gojo" then
        return "Gojo"
    end

    if clan == "Zenin" and zeninType == "Ten Shadows" then
        return "Zenin_TenShadows"
    end

    return nil
end

function DomainEligibility.HasDomainAccess(player)
    return DomainEligibility.ResolveDomainKey(player) ~= nil
end

function DomainEligibility.GetDomainData(player)
    local key = DomainEligibility.ResolveDomainKey(player)
    if not key then
        return nil, nil
    end

    return key, DomainConfig[key]
end

function DomainEligibility.CanActivate(player)
    local domainKey, config = DomainEligibility.GetDomainData(player)
    if not domainKey or not config then
        return false, "Domain not available for this clan.", nil, nil
    end

    if player:GetAttribute("HasStarted") ~= true then
        return false, "Player has not started.", nil, nil
    end

    if player:GetAttribute("IsAlive") ~= true then
        return false, "Player is not alive.", nil, nil
    end

    if player:GetAttribute("DomainActive") == true then
        return false, "Domain already active.", nil, nil
    end

    if (player:GetAttribute("DomainCooldown") or 0) > 0 then
        return false, "Domain is on cooldown.", nil, nil
    end

    if (player:GetAttribute("Mastery") or 0) < 140 then
        return false, "Insufficient mastery.", nil, nil
    end

    local focus = player:GetAttribute("Focus") or 0
    local maxFocus = player:GetAttribute("MaxFocus") or 0
    if focus < maxFocus then
        return false, "Focus must be full.", nil, nil
    end

    if config.RequiresWitness and player:GetAttribute("WitnessedDomain") ~= true then
        return false, "Witness requirement not met.", nil, nil
    end

    if domainKey == "Zenin_TenShadows" and player:GetAttribute("ZeninType") ~= "Ten Shadows" then
        return false, "Invalid Zenin subtype.", nil, nil
    end

    return true, nil, domainKey, config
end

return DomainEligibility
