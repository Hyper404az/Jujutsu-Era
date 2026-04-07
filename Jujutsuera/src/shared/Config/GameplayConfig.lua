local GameplayConfig = {
    BaseHealth = 100,
    BaseFocus = 100,
    HealthRegenPerTick = 2,
    FocusRegenPerTick = 5,
    RegenTick = 1,
    DamageToFocusRatio = 0.1,
    EnchantedDuration = 15,
    EnchantedCooldown = 30,
    EnchantedDamageMultiplier = 1.3,
    EnchantedFocusCostMultiplier = 0.7,
    DomainMasteryRequirement = 140,
    TrainingHitDistance = 15,
    TrainingHitCooldown = 0.35,
    StrengthHitsPerPoint = 10,
    MissionNpcTag = "MissionNPC",
    TargetAcquireDistance = 80,
    HudAbilitySlots = 5,
    HudClockRefreshRate = 1,
    ControlHints = {
        { Key = "Q", Action = "Correr / Esquivar" },
        { Key = "E", Action = "Super Corrida" },
        { Key = "G", Action = "Bloqueio" },
        { Key = "CTRL", Action = "Shift Lock" },
        { Key = "M", Action = "Mapa" },
    },
}

return GameplayConfig
