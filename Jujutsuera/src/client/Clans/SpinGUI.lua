local player = game.Players.LocalPlayer

local replicated = game:WaitForChild("ReplicatedStorage", 5)
if not replicated then
    warn("ReplicatedStorage nao encontrado.")
    return
end

local remotes = replicated:WaitForChild("Remotes", 5)
if not remotes then
    warn("Pasta Remotes nao encontrada.")
    return
end

local events = remotes:WaitForChild("Events", 5)
if not events then
    warn("Pasta Events nao encontrada.")
    return
end

local requestSpin = events:WaitForChild("ClanSpinRequest", 5)
if not requestSpin then
    warn("RemoteEvent 'ClanSpinRequest' nao encontrado.")
    return
end

print("SpinGUI conectado aos remotes atuais.")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LegacySpinGUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.3, 0, 0.2, 0)
frame.Position = UDim2.new(0.35, 0, 0.7, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.Parent = screenGui

local button = Instance.new("TextButton")
button.Size = UDim2.new(0.9, 0, 0.7, 0)
button.Position = UDim2.new(0.05, 0, 0.15, 0)
button.BackgroundColor3 = Color3.fromRGB(0, 162, 255)
button.Text = "Girar Clan (1 Spin)"
button.TextScaled = true
button.Parent = frame

button.MouseButton1Click:Connect(function()
    print("Botao clicado - enviando pedido de spin.")
    requestSpin:FireServer()
end)
