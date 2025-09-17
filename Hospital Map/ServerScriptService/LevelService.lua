-- LevelService.lua (in ServerScriptService)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Dependencies
local LevelConfig = require(game.ReplicatedStorage.LevelConfig)
local PlayerData = require(game.ReplicatedStorage.PlayerData)

-- Events
local LevelFeedback = ReplicatedStorage:WaitForChild("LevelFeedback")
local ShowXPFeedback = ReplicatedStorage:WaitForChild("ShowXPFeedback")
local XPUpdate = game.ReplicatedStorage.XPUpdate

-- The Module
local LevelService = {}

-- Shared Functions
function LevelService.AddXp(player, amount)
	if not player then
		warn("LevelService.AddXp called with nil player")
		return 0, 1, 0
	end

	-- Get current data
	local data = PlayerData.GetData(player)
	if not data then
		warn("No player data found for " .. player.Name)
	end

	local oldXp = data.xp or 0
	local oldLevel = LevelConfig.GetLevelFromXP(oldXp)

	-- Update Data Save
	PlayerData.AddXp(player, amount)

	-- Get updated data
	data = PlayerData.GetData(player)
	local newXp = data.xp
	local newLevel, leftOverXp = LevelConfig.GetLevelFromXP(newXp)

	-- Check if player leveled up
	if newLevel > oldLevel then
		LevelFeedback:FireClient(player, newLevel)
	end
	XPUpdate:FireClient(player, newXp)
	return newXp, newLevel, leftOverXp
end


-- Returns Player's Xp
function LevelService.GetXp(player)
	if not player then
		warn("LevelService.GetXp called with nil player")
		return 0
	end

	local data = PlayerData.GetData(player)
	if not data then
		warn("No player data found for " .. player.Name)
	end

	return data.xp or 0
end


-- Returns Player's Level
function LevelService.GetLevel(player)
	if not player then
		warn("LevelService.GetLevel called with nil player")
		return 1, 0  -- Default to level 1 with 0 progress
	end

	local data = PlayerData.GetData(player)
	if not data then
		warn("No player data found for " .. player.Name)
	end

	local xp = data.xp or 0
	local level, leftOverXp = LevelConfig.GetLevelFromXP(xp)

	return level, leftOverXp
end

return LevelService