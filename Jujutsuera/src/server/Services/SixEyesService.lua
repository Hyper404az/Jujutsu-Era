local SixEyesService = {
    Name = "SixEyesService",
}

function SixEyesService:Init()
    self._states = {}
end

function SixEyesService:_getState(player)
    local state = self._states[player]
    if not state then
        state = {
            Fatigue = 0,
            Mastery = 0,
        }
        self._states[player] = state
    end

    return state
end

function SixEyesService:GetCostMultiplier(player)
    local state = self:_getState(player)
    if state.Fatigue >= 85 then
        return 0.6
    end

    return 0.3
end

function SixEyesService:GetRegenBonus(player)
    local state = self:_getState(player)
    if state.Fatigue >= 85 then
        return 1.25
    end

    return 1.75
end

function SixEyesService:OnAbilityUsed(player)
    local state = self:_getState(player)
    state.Fatigue = math.clamp(state.Fatigue + 8, 0, 100)
    state.Mastery = math.clamp(state.Mastery + 1, 0, 100)
end

function SixEyesService:TickRecovery()
    for _, state in pairs(self._states) do
        state.Fatigue = math.clamp(state.Fatigue - 4, 0, 100)
    end
end

return SixEyesService
