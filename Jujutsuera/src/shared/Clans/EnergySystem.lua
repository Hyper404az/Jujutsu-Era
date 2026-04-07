local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClanData = require(ReplicatedStorage.Shared.Clans.ClanData)
local SixEyes = require(ReplicatedStorage.Shared.Clans.SixEyesSystem)

local EnergySystem = {}

function EnergySystem.Regenerate(player, dt)
    local clan = player:GetAttribute("Clan") or "Commoner"
    local clanData = ClanData.Clans[clan]
    local regenMult = clan == "Gojo" and 2 or 1
    local current = player:GetAttribute("Focus") or 0
    local maxFocus = player:GetAttribute("MaxFocus") or 100

    if clanData and clanData.ItemName == "Venda Especial" then
        regenMult = regenMult * 1.1
    end

    player:SetAttribute("Focus", math.min(current + (15 * regenMult * dt), maxFocus))
end

function EnergySystem.Consume(player, amount)
    local current = player:GetAttribute("Focus") or 0
    local clan = player:GetAttribute("Clan")
    local finalCost = amount

    if clan == "Gojo" and SixEyes.CanUseEyes() then
        finalCost = amount * 0.3
        SixEyes.AddMaestria(0.1)
    end

    if current >= finalCost then
        player:SetAttribute("Focus", current - finalCost)
        return true
    end

    return false
end

return EnergySystem
