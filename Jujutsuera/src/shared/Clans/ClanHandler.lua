-- src/shared/Clans/ClanHandler.lua
local ClanData = require(script.Parent.ClanData)

local ClanHandler = {}

function ClanHandler.EquipClan(player, clanName)
    local data = ClanData.Clans[clanName]
    if not data then return end
    
    player:SetAttribute("Clan", clanName)
    print(player.Name .. " equipou o clã: " .. clanName)
end

return ClanHandler