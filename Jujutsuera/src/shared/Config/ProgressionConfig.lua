local ProgressionConfig = {}

ProgressionConfig.MaxLevel = 150
ProgressionConfig.FactionUnlockLevel = 30

ProgressionConfig.Phases = {
    {
        Key = "Beginner",
        Name = "Iniciante",
        Rank = "Grade 4",
        StoryArc = "O Despertar",
        MinLevel = 1,
        MaxLevel = 20,
        XPMin = 500,
        XPMax = 2000,
    },
    {
        Key = "Student",
        Name = "Estudante",
        Rank = "Grade 3",
        StoryArc = "O Despertar",
        MinLevel = 21,
        MaxLevel = 50,
        XPMin = 2000,
        XPMax = 8000,
    },
    {
        Key = "Veteran",
        Name = "Veterano",
        Rank = "Grade 2",
        StoryArc = "A Conspiracao",
        MinLevel = 51,
        MaxLevel = 80,
        XPMin = 8000,
        XPMax = 20000,
    },
    {
        Key = "Elite",
        Name = "Elite",
        Rank = "Grade 1",
        StoryArc = "A Conspiracao",
        MinLevel = 81,
        MaxLevel = 110,
        XPMin = 20000,
        XPMax = 50000,
    },
    {
        Key = "Legendary",
        Name = "Lendario",
        Rank = "Semi-Special",
        StoryArc = "A Nova Culling Game",
        MinLevel = 111,
        MaxLevel = 130,
        XPMin = 50000,
        XPMax = 120000,
    },
    {
        Key = "Transcendent",
        Name = "Transcendente",
        Rank = "Special Grade",
        StoryArc = "A Nova Culling Game",
        MinLevel = 131,
        MaxLevel = 150,
        XPMin = 120000,
        XPMax = 300000,
    },
}

local function clampLevel(level)
    local resolvedLevel = math.floor(tonumber(level) or 1)
    return math.clamp(resolvedLevel, 1, ProgressionConfig.MaxLevel)
end

local function lerpNumber(startValue, endValue, alpha)
    return startValue + ((endValue - startValue) * alpha)
end

function ProgressionConfig.GetPhaseForLevel(level)
    local resolvedLevel = clampLevel(level)

    for _, phase in ipairs(ProgressionConfig.Phases) do
        if resolvedLevel >= phase.MinLevel and resolvedLevel <= phase.MaxLevel then
            return phase
        end
    end

    return ProgressionConfig.Phases[#ProgressionConfig.Phases]
end

function ProgressionConfig.GetXPToNextLevel(level)
    local resolvedLevel = clampLevel(level)
    if resolvedLevel >= ProgressionConfig.MaxLevel then
        return 0
    end

    local phase = ProgressionConfig.GetPhaseForLevel(resolvedLevel)
    local span = math.max(1, phase.MaxLevel - phase.MinLevel)
    local alpha = (resolvedLevel - phase.MinLevel) / span

    return math.floor(lerpNumber(phase.XPMin, phase.XPMax, alpha) + 0.5)
end

function ProgressionConfig.CanChooseFaction(level)
    return clampLevel(level) >= ProgressionConfig.FactionUnlockLevel
end

return ProgressionConfig
