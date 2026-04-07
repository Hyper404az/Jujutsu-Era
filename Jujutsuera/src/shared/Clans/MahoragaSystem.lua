-- src/shared/Clans/MahoragaSystem.lua
local MahoragaSystem = {
    Summoned = false,
    AdaptationLevel = 0
}

function MahoragaSystem.Summon(player)
    if MahoragaSystem.Summoned then return false end
    MahoragaSystem.Summoned = true
    print(player.Name .. " invocou Mahoraga!")
    -- Aqui você vai spawnar o modelo de Mahoraga depois
    return true
end

function MahoragaSystem.Adapt(attackType)
    MahoragaSystem.AdaptationLevel += 1
    print("Mahoraga se adaptou a: " .. attackType)
end

return MahoragaSystem