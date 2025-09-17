local Players = game:GetService("Players")

local LevelService = require(game.ServerScriptService.LevelService)
local XPUpdate = game.ReplicatedStorage.XPUpdate
Players.PlayerAdded:Connect(function(player)
	wait(2)
	XPUpdate:FireClient(player,LevelService.GetXp(player))
end)