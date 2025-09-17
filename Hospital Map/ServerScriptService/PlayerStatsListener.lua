-- PlayerStatsListener script
-- This script acts as a bridge between PlayerTracker and PlayerStatsService
-- to avoid circular dependencies

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Wait for the ReviveServerEvent to be created by PlayerTracker
local reviveServerEvent = ReplicatedStorage:WaitForChild("ReviveServerEvent")

-- Get the PlayerStatsService
local PlayerStatsService = require(ServerScriptService.PlayerStatsService)

-- Listen for revive events from PlayerTracker and update PlayerStatsService
reviveServerEvent.Event:Connect(function(player)
	-- Update player stats when a player is revived
	print("PlayerStatsListener: Handling revive for " .. player.Name)
	PlayerStatsService.RevivePlayer(player)
end)
