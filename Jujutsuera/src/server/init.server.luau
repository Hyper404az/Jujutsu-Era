local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

Players.CharacterAutoLoads = false

local ServiceRegistry = require(ServerScriptService.Server.Core.ServiceRegistry)

local services = ServiceRegistry.new()

services:Register("RemoteService", require(ServerScriptService.Server.Services.RemoteService))
services:Register("DataService", require(ServerScriptService.Server.Services.DataService))
services:Register("SixEyesService", require(ServerScriptService.Server.Services.SixEyesService))
services:Register("ClanService", require(ServerScriptService.Server.Services.ClanService))
services:Register("MissionService", require(ServerScriptService.Server.Services.MissionService))
services:Register("MissionNpcService", require(ServerScriptService.Server.Services.MissionNpcService))
services:Register("ProgressionService", require(ServerScriptService.Server.Services.ProgressionService))
services:Register("PlayerStateService", require(ServerScriptService.Server.Services.PlayerStateService))
services:Register("DomainService", require(ServerScriptService.Server.DomainSystem.DomainService))
services:Register("CombatService", require(ServerScriptService.Server.Services.CombatService))
services:Register("EnchantedModeService", require(ServerScriptService.Server.Services.EnchantedModeService))
services:Register("TrainingService", require(ServerScriptService.Server.Services.TrainingService))
services:Register("AbilityService", require(ServerScriptService.Server.Services.AbilityService))
services:Register("StartService", require(ServerScriptService.Server.Services.StartService))

services:InitAll()
services:StartAll()
