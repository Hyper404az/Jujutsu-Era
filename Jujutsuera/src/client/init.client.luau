local Players = game:GetService("Players")

local NetworkController = require(script.Controllers.NetworkController)
local MenuController = require(script.Controllers.MenuController)
local HUDController = require(script.Controllers.HUDController)
local AbilityController = require(script.Controllers.AbilityController)
local CombatController = require(script.Controllers.CombatController)

local player = Players.LocalPlayer
local network = NetworkController.new()

local menuController = MenuController.new(network)
local hudController = HUDController.new(network)
local abilityController = AbilityController.new(network)
local combatController = CombatController.new(network)

player.CharacterAdded:Connect(function()
    workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end)

if not player:GetAttribute("HasStarted") then
    workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
end
