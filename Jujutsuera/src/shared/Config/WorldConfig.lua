local WorldConfig = {}

WorldConfig.AreaOrigins = {
    TokyoHigh = Vector3.new(0, 0, 0),
    Shibuya = Vector3.new(1800, 0, 120),
    Kyoto = Vector3.new(-1750, 120, 850),
    CullingGame = Vector3.new(0, 0, 3950),
    Villages = {
        Vector3.new(-900, 0, 2300),
        Vector3.new(980, 0, 2280),
        Vector3.new(-2300, 0, -1350),
        Vector3.new(2320, 0, -1420),
    },
}

WorldConfig.PlayerSpawnCFrame = CFrame.new(0, 8, -126) * CFrame.Angles(0, math.rad(180), 0)

WorldConfig.FolderNames = {
    "Buildings_TokyoHigh",
    "Buildings_Shibuya",
    "Buildings_Kyoto",
    "Buildings_Villages",
    "Props_Decoration",
    "Lighting",
    "Spawns",
    "Mobs_Grade4",
    "Mobs_Grade3",
    "Mobs_Special",
    "Missions_NPCs",
    "Teleports",
    "Barriers",
}

WorldConfig.WetSurfaceReflectance = 0.08
WorldConfig.GlobalWind = Vector3.new(4.5, 0, 2.2)

WorldConfig.Palette = {
    SkyRed = Color3.fromRGB(110, 22, 28),
    SkyPurple = Color3.fromRGB(75, 34, 92),
    NeonBlue = Color3.fromRGB(68, 186, 255),
    NeonPink = Color3.fromRGB(255, 96, 186),
    NeonRed = Color3.fromRGB(255, 84, 104),
    NeonWhite = Color3.fromRGB(240, 241, 255),
    CurseBlue = Color3.fromRGB(39, 58, 140),
    CursePurple = Color3.fromRGB(111, 53, 168),
    CurseBlack = Color3.fromRGB(22, 18, 30),
    WetAsphalt = Color3.fromRGB(37, 38, 47),
    TokyoStone = Color3.fromRGB(81, 70, 63),
    KyotoWood = Color3.fromRGB(109, 72, 53),
    KyotoRoof = Color3.fromRGB(121, 32, 32),
    PaperGlow = Color3.fromRGB(255, 232, 188),
    FogGray = Color3.fromRGB(72, 64, 78),
}

return WorldConfig
