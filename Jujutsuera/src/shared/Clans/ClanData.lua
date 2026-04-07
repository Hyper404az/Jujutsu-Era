-- src/shared/Clans/ClanData.lua
local ClanData = {
    Rarities = { Comum = 40, Incomum = 25, Raro = 15, Epico = 10, Lendario = 6, Mitico = 3, Divine = 1 },
    
    Clans = {
        ["Gojo"] = {
            ItemName = "Venda Especial",
            Rarity = "Lendario",
            -- Buffs mantidos no SixEyesSystem e EnergySystem
            Skills = {
                [1] = {Name = "Azul", ReqMaestria = 0, Energy = 20, Key = Enum.KeyCode.Q},
                [2] = {Name = "Vermelho", ReqMaestria = 50, Energy = 40, Key = Enum.KeyCode.E},
                [3] = {Name = "Vazio Roxo", ReqMaestria = 120, Energy = 80, Key = Enum.KeyCode.F},
                ["Domain"] = {Name = "Vazio Infinito", ReqMaestria = 140, NeedsDomainVision = true, Energy = 150}
            }
        },
        ["Zenin"] = {
            ItemName = "Pergaminho de Herança",
            Rarity = "Epico",
            HasSubTechniques = true,
            -- As sub-técnicas serão sorteadas no ClanHandler quando o jogador tirar Zenin
            SubTechniques = {
                ["Dez Sombras"] = {
                    [1] = {Name = "Cães Divinos", ReqMaestria = 0, Energy = 15, Key = Enum.KeyCode.Q},
                    [2] = {Name = "Nue", ReqMaestria = 30, Energy = 25, Key = Enum.KeyCode.E},
                    ["Domain"] = {Name = "Jardim das Sombras", ReqMaestria = 140, NeedsDomainVision = true}
                },
                ["Projeção"] = {
                    [1] = {Name = "Ativar 24 Frames", ReqMaestria = 0, Energy = 10, Key = Enum.KeyCode.Q},
                    [2] = {Name = "Selo de Quadro", ReqMaestria = 40, Energy = 30, Key = Enum.KeyCode.E}
                },
                ["Restrição Celestial"] = {
                    -- Não usa CE, buff extremo em status físicos
                    [1] = {Name = "Avanço Sônico", ReqMaestria = 0, Energy = 0, Key = Enum.KeyCode.Q},
                    [2] = {Name = "Esmagar", ReqMaestria = 50, Energy = 0, Key = Enum.KeyCode.E}
                }
            }
        },
        ["Kamo"] = {
            ItemName = "Bolsa de Sangue",
            Rarity = "Raro",
            Skills = {
                [1] = {Name = "Sangue Perfurante", ReqMaestria = 0, Energy = 10, HealthCost = 5, Key = Enum.KeyCode.Q},
                [2] = {Name = "Escama Vermelha", ReqMaestria = 40, Energy = 20, HealthCost = 10, Key = Enum.KeyCode.E},
                [3] = {Name = "Supernova", ReqMaestria = 80, Energy = 40, HealthCost = 25, Key = Enum.KeyCode.F}
            }
        },
        ["Inumaki"] = {
            ItemName = "Megafone Escolar",
            Rarity = "Raro",
            Skills = {
                [1] = {Name = "Pare!", ReqMaestria = 0, Energy = 15, Key = Enum.KeyCode.Q},
                [2] = {Name = "Esmague!", ReqMaestria = 60, Energy = 35, Key = Enum.KeyCode.E}
            }
            -- O recuo de dano na garganta será calculado no CombatHandler baseado no HP do inimigo
        },
        ["Itadori"] = {
            ItemName = "Dedo Seco",
            Rarity = "Lendario",
            Skills = {
                [1] = {Name = "Punho Divergente", ReqMaestria = 0, Energy = 10, Key = Enum.KeyCode.Q},
                [2] = {Name = "Reforço Corporal", ReqMaestria = 40, Energy = 25, Key = Enum.KeyCode.E},
                [3] = {Name = "Black Flash", ReqMaestria = 100, Energy = 50, TimingRequired = true, Key = Enum.KeyCode.F}
            }
        }
    }
}
return ClanData