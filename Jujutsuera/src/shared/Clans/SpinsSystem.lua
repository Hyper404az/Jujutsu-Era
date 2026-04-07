-- src/shared/Clans/SpinSystem.lua
local ClanData = require(script.Parent.ClanData)

local SpinSystem = {}

function SpinSystem.GetRandomClan()
    local rand = math.random(1, 100)
    local sum = 0

    for clanName, data in pairs(ClanData.Clans) do
        local chance = ClanData.Rarities[data.Rarity] or 10
        sum += chance
        if rand <= sum then
            return clanName
        end
    end
    return "Zenin"
end

return SpinSystem