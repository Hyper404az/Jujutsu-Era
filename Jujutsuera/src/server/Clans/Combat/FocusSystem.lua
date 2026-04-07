local FocusSystem = {}

local MAX_FOCUS = 100
local ENCHANT_DURATION = 15
local ENCHANT_COOLDOWN = 45

function FocusSystem.AddFocusOnHit(player, damageDealt)
    if player:GetAttribute("EnchantedMode") then
        return
    end

    local currentFocus = player:GetAttribute("Focus") or 0
    local maxFocus = player:GetAttribute("MaxFocus") or MAX_FOCUS
    local focusGain = damageDealt * 0.1

    player:SetAttribute("Focus", math.clamp(currentFocus + focusGain, 0, maxFocus))
end

function FocusSystem.ActivateEnchantment(player)
    local currentFocus = player:GetAttribute("Focus") or 0
    local maxFocus = player:GetAttribute("MaxFocus") or MAX_FOCUS
    local lastUsed = player:GetAttribute("LastEnchantedTime") or 0

    if currentFocus < maxFocus or (os.time() - lastUsed) < ENCHANT_COOLDOWN then
        return false
    end

    player:SetAttribute("Focus", 0)
    player:SetAttribute("EnchantedMode", true)
    player:SetAttribute("LastEnchantedTime", os.time())

    task.delay(ENCHANT_DURATION, function()
        if player and player.Parent then
            player:SetAttribute("EnchantedMode", false)
        end
    end)

    return true
end

return FocusSystem
