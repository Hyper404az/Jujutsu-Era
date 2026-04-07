local PlayerStats = {}
local GameplayConfig = require(game.ReplicatedStorage.Shared.Config.GameplayConfig)

function PlayerStats.Initialize(player)
    player:SetAttribute("MaxHealth", GameplayConfig.BaseHealth)
    player:SetAttribute("Health", GameplayConfig.BaseHealth)
    player:SetAttribute("MaxFocus", GameplayConfig.BaseFocus)
    player:SetAttribute("Focus", GameplayConfig.BaseFocus)
    player:SetAttribute("HasStarted", false)
end

function PlayerStats.UpdateStat(player, stat, amount, maxStat)
    local current = player:GetAttribute(stat) or 0
    local max = player:GetAttribute(maxStat) or 100
    player:SetAttribute(stat, math.clamp(current + amount, 0, max))
end

return PlayerStats
