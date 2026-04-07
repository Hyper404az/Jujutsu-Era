-- src/shared/Progression/MissionSystem.lua
local MissionSystem = {}

MissionSystem.Missions = {}

-- Exemplo de missões por Grade
function MissionSystem.GetMissionsForGrade(grade)
    if grade == "Grau 4" then
        return {
            {Id = 1, Name = "Exorcizar 5 Maldições", Type = "Kill", Amount = 5, RewardXP = 100, RewardYen = 200},
            {Id = 2, Name = "Investigar Incidente", Type = "Explore", Amount = 1, RewardXP = 80, RewardYen = 150}
        }
    elseif grade == "Especial" then
        return {
            {Id = 101, Name = "Derrotar Maldição Especial", Type = "Boss", Amount = 1, RewardXP = 2000, RewardYen = 4000},
        }
    end
    return {}
end

-- Função para completar missão
function MissionSystem.CompleteMission(player, missionId)
    print(player.Name .. " completou a missão ID: " .. missionId)
    -- Aqui você dará XP, Yen, etc.
end

return MissionSystem