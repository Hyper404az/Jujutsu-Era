local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "JEDomainUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local card = Instance.new("Frame")
card.Size = UDim2.new(0, 250, 0, 72)
card.Position = UDim2.new(1, -268, 0, 18)
card.BackgroundColor3 = Color3.fromRGB(15, 16, 24)
card.BackgroundTransparency = 0.12
card.BorderSizePixel = 0
card.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = card

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 22)
title.Position = UDim2.new(0, 10, 0, 10)
title.BackgroundTransparency = 1
title.Text = "Domain Expansion [T]"
title.TextColor3 = Color3.fromRGB(245, 241, 247)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = card

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -20, 0, 18)
status.Position = UDim2.new(0, 10, 0, 34)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.fromRGB(213, 208, 217)
status.TextSize = 13
status.Font = Enum.Font.Gotham
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = card

local detail = Instance.new("TextLabel")
detail.Size = UDim2.new(1, -20, 0, 16)
detail.Position = UDim2.new(0, 10, 0, 52)
detail.BackgroundTransparency = 1
detail.TextColor3 = Color3.fromRGB(173, 168, 180)
detail.TextSize = 12
detail.Font = Enum.Font.Gotham
detail.TextXAlignment = Enum.TextXAlignment.Left
detail.Parent = card

local function refresh()
    local hasDomain = player:GetAttribute("HasDomain") == true
    local active = player:GetAttribute("DomainActive") == true
    local cooldown = player:GetAttribute("DomainCooldown") or 0
    local clan = player:GetAttribute("Clan") or "Commoner"
    local zeninType = player:GetAttribute("ZeninType") or ""

    if not hasDomain then
        status.Text = "Indisponível"
        detail.Text = clan == "Zenin" and zeninType ~= "Ten Shadows" and "Apenas Zenin Ten Shadows possui Domain." or "Seu clã não possui Domain canônico."
        return
    end

    if active then
        status.Text = "Ativo"
        detail.Text = "Domain em execução."
        return
    end

    if cooldown > 0 then
        status.Text = "Em recarga"
        detail.Text = string.format("Cooldown restante: %ds", cooldown)
        return
    end

    status.Text = "Pronto"
    detail.Text = "Requer foco máximo e maestria 140."
end

for _, attributeName in ipairs({
    "HasDomain",
    "DomainActive",
    "DomainCooldown",
    "Clan",
    "ZeninType",
}) do
    player:GetAttributeChangedSignal(attributeName):Connect(refresh)
end

refresh()
