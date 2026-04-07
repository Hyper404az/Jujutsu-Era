local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameplayConfig = require(ReplicatedStorage.Shared.Config.GameplayConfig)

local EnchantedModeService = {
    Name = "EnchantedModeService",
}

function EnchantedModeService:Init(services)
    self._services = services
    self._cooldowns = {}
end

function EnchantedModeService:IsOnCooldown(player)
    local cooldownEnd = self._cooldowns[player] or 0
    return os.clock() < cooldownEnd
end

function EnchantedModeService:Activate(player)
    local playerState = self._services:Get("PlayerStateService")
    if player:GetAttribute("EnchantedMode") then
        return false, "Enchanted Mode already active."
    end

    if self:IsOnCooldown(player) then
        return false, "Enchanted Mode is on cooldown."
    end

    local focus = player:GetAttribute("Focus") or 0
    local maxFocus = player:GetAttribute("MaxFocus") or 0
    if focus < maxFocus then
        return false, "Focus must be full."
    end

    playerState:SetFocus(player, 0)
    player:SetAttribute("EnchantedMode", true)
    self._cooldowns[player] = os.clock() + GameplayConfig.EnchantedCooldown

    task.delay(GameplayConfig.EnchantedDuration, function()
        if player.Parent then
            player:SetAttribute("EnchantedMode", false)
        end
    end)

    return true
end

return EnchantedModeService
