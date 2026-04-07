-- src/shared/Progression/TrainingSystem.lua
local TrainingSystem = {}

-- Treino de Força
function TrainingSystem.TrainStrength(player, hits)
    if hits >= 100 then
        local current = player:GetAttribute("Strength") or 0
        player:SetAttribute("Strength", current + 1)
        print(player.Name .. " ganhou +1 Força")
        return true
    end
    return false
end

-- Treino de Resistência (exemplo simples)
function TrainingSystem.StartResistanceTraining(player)
    print(player.Name .. " começou treino de Resistência (Banheira Gelada)")
    -- Lógica completa será feita depois com Part + Touch
end

return TrainingSystem