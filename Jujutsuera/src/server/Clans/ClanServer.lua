local DomainManager = require(script.Parent.Combat.DomainManager)

local ClanServer = {}

function ClanServer.HandleSkillRequest(player, skillName)
    local mastery = player:GetAttribute("Mastery") or 0
    local witnessed = player:GetAttribute("WitnessedDomain") or false

    if skillName ~= "Vazio Infinito" then
        return false, "Skill not handled by ClanServer."
    end

    if mastery < 140 or not witnessed then
        warn(player.Name .. " tentou usar dominio sem requisitos.")
        return false, "Requirements not met."
    end

    DomainManager.CastDomain(player, skillName)
    return true
end

return ClanServer
