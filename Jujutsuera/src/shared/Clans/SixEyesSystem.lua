-- src/shared/Clans/SixEyesSystem.lua
local SixEyesSystem = {
    Fadiga = 0,
    MaxFadiga = 100,
    Maestria = 0,
    MaxMaestria = 100
}

function SixEyesSystem.UpdateFadiga(dt)
    SixEyesSystem.Fadiga = math.min(SixEyesSystem.Fadiga + (18 * dt), SixEyesSystem.MaxFadiga)
end

function SixEyesSystem.CanUseEyes()
    return SixEyesSystem.Fadiga < 85
end

function SixEyesSystem.AddMaestria(amount)
    SixEyesSystem.Maestria = math.min(SixEyesSystem.Maestria + amount, SixEyesSystem.MaxMaestria)
end

function SixEyesSystem.ResetFadiga()
    SixEyesSystem.Fadiga = 0
end

return SixEyesSystem 