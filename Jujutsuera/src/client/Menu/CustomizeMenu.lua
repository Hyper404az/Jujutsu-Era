local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RemoteEvents = Remotes:WaitForChild("Events")
local RequestSpin = RemoteEvents:WaitForChild("ClanSpinRequest")
local SpinResult = RemoteEvents:WaitForChild("ClanSpinResult")

local CustomizeMenu = {}

local gui = nil
local spinsLabel = nil
local resultLabel = nil
local button = nil
local spinConnection = nil
local currentSpins = 0
local isOpen = false
local isSpinning = false

local function ensureGui()
    if gui then
        return
    end

    gui = Instance.new("ScreenGui")
    gui.Name = "JJE_CustomizeMenu"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Name = "Panel"
    frame.Size = UDim2.new(0, 420, 0, 220)
    frame.Position = UDim2.new(0.5, -210, 0.5, -110)
    frame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -24, 0, 32)
    title.Position = UDim2.new(0, 12, 0, 12)
    title.BackgroundTransparency = 1
    title.Text = "Customize"
    title.TextColor3 = Color3.fromRGB(245, 245, 250)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 22
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame

    spinsLabel = Instance.new("TextLabel")
    spinsLabel.Size = UDim2.new(1, -24, 0, 24)
    spinsLabel.Position = UDim2.new(0, 12, 0, 56)
    spinsLabel.BackgroundTransparency = 1
    spinsLabel.TextColor3 = Color3.fromRGB(212, 212, 220)
    spinsLabel.Font = Enum.Font.Gotham
    spinsLabel.TextSize = 14
    spinsLabel.TextXAlignment = Enum.TextXAlignment.Left
    spinsLabel.Parent = frame

    button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -24, 0, 52)
    button.Position = UDim2.new(0, 12, 0, 96)
    button.BackgroundColor3 = Color3.fromRGB(190, 42, 42)
    button.Text = "Spin Innate"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.GothamBlack
    button.TextSize = 20
    button.BorderSizePixel = 0
    button.Parent = frame

    resultLabel = Instance.new("TextLabel")
    resultLabel.Size = UDim2.new(1, -24, 0, 44)
    resultLabel.Position = UDim2.new(0, 12, 0, 164)
    resultLabel.BackgroundTransparency = 1
    resultLabel.Text = ""
    resultLabel.TextColor3 = Color3.fromRGB(255, 214, 102)
    resultLabel.Font = Enum.Font.GothamBold
    resultLabel.TextSize = 16
    resultLabel.TextWrapped = true
    resultLabel.Parent = frame

    button.MouseButton1Click:Connect(function()
        if isSpinning or currentSpins <= 0 then
            return
        end

        isSpinning = true
        button.Active = false
        button.Text = "Girando..."
        RequestSpin:FireServer()
    end)
end

function CustomizeMenu.updateData(data)
    currentSpins = data and data.spins or currentSpins
    if spinsLabel then
        spinsLabel.Text = string.format("Spins disponiveis: %d", currentSpins)
    end
end

function CustomizeMenu.open(playerData)
    if isOpen then
        CustomizeMenu.updateData(playerData or {})
        return
    end

    isOpen = true
    currentSpins = playerData and playerData.spins or currentSpins
    ensureGui()
    CustomizeMenu.updateData({ spins = currentSpins })

    if spinConnection then
        spinConnection:Disconnect()
        spinConnection = nil
    end

    spinConnection = SpinResult.OnClientEvent:Connect(function(payload)
        local clanName = type(payload) == "table" and (payload.Clan or payload.Rarity) or "Clan"
        currentSpins = type(payload) == "table" and (payload.Spins or currentSpins) or currentSpins
        CustomizeMenu.updateData({ spins = currentSpins })

        if resultLabel then
            resultLabel.Text = string.format("%s obtido.", clanName)
        end

        if button then
            button.Active = true
            button.Text = "Spin Innate"
        end

        isSpinning = false
    end)
end

function CustomizeMenu.close()
    isOpen = false
    isSpinning = false

    if spinConnection then
        spinConnection:Disconnect()
        spinConnection = nil
    end

    if gui then
        gui:Destroy()
        gui = nil
        spinsLabel = nil
        resultLabel = nil
        button = nil
    end
end

return CustomizeMenu
