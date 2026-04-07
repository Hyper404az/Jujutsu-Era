local FactionConfig = {}

FactionConfig.DefaultFaction = "Unaffiliated"
FactionConfig.UnlockLevel = 30

FactionConfig.Factions = {
    Tokyo = {
        DisplayName = "Tokyo Jujutsu High",
        Base = "Tokyo",
        Bonus = "+10% mission XP",
        Enemy = "Kyoto Jujutsu High",
    },
    Kyoto = {
        DisplayName = "Kyoto Jujutsu High",
        Base = "Kyoto",
        Bonus = "+10% mission Yen",
        Enemy = "Tokyo Jujutsu High",
    },
    Renegades = {
        DisplayName = "Renegados",
        Base = "Zona Neutra",
        Bonus = "+15% PvP damage",
        Enemy = "Ambas as escolas",
    },
}

return FactionConfig
