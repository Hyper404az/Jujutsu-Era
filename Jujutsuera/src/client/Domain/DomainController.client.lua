local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local events = remotes:WaitForChild("Events")
local requestDomainActivation = events:WaitForChild("RequestDomainActivation")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end

    if input.KeyCode == Enum.KeyCode.T then
        requestDomainActivation:FireServer()
    end
end)
