local Players = game:GetService("Players")
local MainMenu = require(script.Parent.MainMenu)
local ClanMenu = require(script.Parent.ClanMenu)
local SlotsMenu = require(script.Parent.SlotsMenu)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "JujutsuEraUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

-- Instancia as telas
local mainMenu = MainMenu.new(ScreenGui)
local clanMenu = ClanMenu.new(ScreenGui)
local slotsMenu = SlotsMenu.new(ScreenGui)

local MenuController = {}

-- FUNÇÃO QUE REALMENTE MOSTRA O MENU
function MenuController.OpenMainMenu()
    -- Esconde tudo primeiro para resetar
    mainMenu._root.Visible = true
    clanMenu._root.Visible = false
    slotsMenu._root.Visible = false
    
    print("📢 MainMenu visível!")
end

-- Configura os botões para trocar de tela
mainMenu.OnClanClicked = function()
    mainMenu._root.Visible = false
    clanMenu._root.Visible = true
end

clanMenu.OnBackClicked = function()
    clanMenu._root.Visible = false
    mainMenu._root.Visible = true
end

return MenuController
