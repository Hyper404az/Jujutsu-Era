local CurseConfig = {}

CurseConfig.RegionDefaults = {
    MaxAlive = 3,
    RespawnDelay = 14,
    AggroRadius = 110,
    LeashRadius = 180,
    AttackRange = 5.5,
    AttackInterval = 1.4,
}

CurseConfig.Grades = {
    Grade4 = {
        DisplayName = "Curse Grade 4",
        FolderName = "Mobs_Grade4",
        MaxHealth = 70,
        WalkSpeed = 11,
        Damage = 7,
        XPReward = 160,
        YenReward = 180,
        FragmentsReward = 0,
        BodyColor = Color3.fromRGB(44, 40, 62),
        AuraColor = Color3.fromRGB(48, 74, 168),
        SizeScale = 0.95,
    },
    Grade3 = {
        DisplayName = "Curse Grade 3",
        FolderName = "Mobs_Grade3",
        MaxHealth = 110,
        WalkSpeed = 12,
        Damage = 12,
        XPReward = 260,
        YenReward = 260,
        FragmentsReward = 0,
        BodyColor = Color3.fromRGB(54, 44, 76),
        AuraColor = Color3.fromRGB(112, 74, 201),
        SizeScale = 1.05,
    },
    Grade2 = {
        DisplayName = "Curse Grade 2",
        FolderName = "Mobs_Special",
        MaxHealth = 180,
        WalkSpeed = 13,
        Damage = 18,
        XPReward = 440,
        YenReward = 420,
        FragmentsReward = 0,
        BodyColor = Color3.fromRGB(60, 46, 85),
        AuraColor = Color3.fromRGB(148, 74, 225),
        SizeScale = 1.12,
    },
    Grade1 = {
        DisplayName = "Curse Grade 1",
        FolderName = "Mobs_Special",
        MaxHealth = 280,
        WalkSpeed = 14,
        Damage = 24,
        XPReward = 720,
        YenReward = 720,
        FragmentsReward = 1,
        BodyColor = Color3.fromRGB(79, 58, 110),
        AuraColor = Color3.fromRGB(78, 114, 255),
        SizeScale = 1.2,
    },
    SemiSpecial = {
        DisplayName = "Semi-Special Curse",
        FolderName = "Mobs_Special",
        MaxHealth = 430,
        WalkSpeed = 15,
        Damage = 32,
        XPReward = 1250,
        YenReward = 1100,
        FragmentsReward = 1,
        BodyColor = Color3.fromRGB(92, 63, 122),
        AuraColor = Color3.fromRGB(195, 94, 255),
        SizeScale = 1.32,
    },
    Special = {
        DisplayName = "Special Grade Curse",
        FolderName = "Mobs_Special",
        MaxHealth = 650,
        WalkSpeed = 16,
        Damage = 42,
        XPReward = 2200,
        YenReward = 1750,
        FragmentsReward = 2,
        BodyColor = Color3.fromRGB(112, 73, 145),
        AuraColor = Color3.fromRGB(91, 157, 255),
        SizeScale = 1.48,
    },
}

function CurseConfig.GetGrade(key)
    return CurseConfig.Grades[key]
end

return CurseConfig
