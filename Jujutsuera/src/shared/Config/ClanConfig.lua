local ClanConfig = {}

ClanConfig.DefaultClan = "Commoner"
ClanConfig.RarityOrder = {
    "Common",
    "Rare",
    "Epic",
    "Legendary",
}

ClanConfig.RarityLabels = {
    Common = "Comum",
    Rare = "Raro",
    Epic = "Épico",
    Legendary = "Lendário",
}

ClanConfig.ZeninSubTechniques = {
    "Ten Shadows",
    "Projection Sorcery",
    "Heavenly Restriction",
}

ClanConfig.Clans = {
    Gojo = {
        Weight = 3,
        Rarity = "Legendary",
        DisplayName = "Gojo",
        BuffSummary = {
            "+60% de foco máximo",
            "-70% custo de foco",
            "Regeneração extrema",
            "Integra Seis Olhos",
        },
        Modifiers = {
            MaxHealthMultiplier = 1,
            MaxFocusMultiplier = 1.6,
            FocusCostMultiplier = 0.3,
            RegenMultiplier = 2.5,
            DamageMultipliers = {
                Physical = 1,
                Cursed = 1.15,
                Domain = 1.15,
                Special = 1.1,
            },
            ResistanceMultiplier = 1,
            SixEyes = true,
        },
    },
    Zenin = {
        Weight = 10,
        Rarity = "Epic",
        DisplayName = "Zenin",
        BuffSummary = {
            "+50% dano físico",
            "Suporte a sub-técnicas",
            "Pressão forte em combate",
        },
        Modifiers = {
            MaxHealthMultiplier = 1,
            MaxFocusMultiplier = 1,
            FocusCostMultiplier = 1,
            RegenMultiplier = 1,
            DamageMultipliers = {
                Physical = 1.5,
                Cursed = 1,
                Domain = 1,
                Special = 1.05,
            },
            ResistanceMultiplier = 1,
            HasSubTechniques = true,
        },
    },
    Itadori = {
        Weight = 8,
        Rarity = "Legendary",
        DisplayName = "Itadori",
        BuffSummary = {
            "+50% de vida máxima",
            "Maior resistência",
            "Black Flash manual",
        },
        Modifiers = {
            MaxHealthMultiplier = 1.5,
            MaxFocusMultiplier = 1,
            FocusCostMultiplier = 1,
            RegenMultiplier = 1.1,
            DamageMultipliers = {
                Physical = 1.15,
                Cursed = 1,
                Domain = 1,
                Special = 1.15,
            },
            ResistanceMultiplier = 0.85,
            BlackFlash = true,
        },
    },
    Fushiguro = {
        Weight = 15,
        Rarity = "Rare",
        DisplayName = "Fushiguro",
        BuffSummary = {
            "+60% regeneração",
            "Domínio com foco em invocação",
        },
        Modifiers = {
            MaxHealthMultiplier = 1,
            MaxFocusMultiplier = 1.1,
            FocusCostMultiplier = 1,
            RegenMultiplier = 1.6,
            DamageMultipliers = {
                Physical = 1,
                Cursed = 1.05,
                Domain = 1.1,
                Special = 1,
            },
            ResistanceMultiplier = 1,
        },
    },
    Kamo = {
        Weight = 20,
        Rarity = "Rare",
        DisplayName = "Kamo",
        BuffSummary = {
            "Técnicas avançadas gastam vida",
            "Maior dano amaldiçoado",
        },
        Modifiers = {
            MaxHealthMultiplier = 1,
            MaxFocusMultiplier = 1.05,
            FocusCostMultiplier = 1,
            RegenMultiplier = 1,
            DamageMultipliers = {
                Physical = 1,
                Cursed = 1.1,
                Domain = 1,
                Special = 1.05,
            },
            ResistanceMultiplier = 1,
            UsesHealthCost = true,
        },
    },
    Commoner = {
        Weight = 44,
        Rarity = "Common",
        DisplayName = "Plebeu",
        BuffSummary = {
            "Sem bônus especiais",
            "Base equilibrada",
        },
        Modifiers = {
            MaxHealthMultiplier = 1,
            MaxFocusMultiplier = 1,
            FocusCostMultiplier = 1,
            RegenMultiplier = 1,
            DamageMultipliers = {
                Physical = 1,
                Cursed = 1,
                Domain = 1,
                Special = 1,
            },
            ResistanceMultiplier = 1,
        },
    },
}

return ClanConfig
