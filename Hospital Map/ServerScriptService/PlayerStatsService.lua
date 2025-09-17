local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Remote events for communicating with the client
local HealthUpdateEvent = ReplicatedStorage.PlayerStatsEvents:WaitForChild("HealthUpdate")
local MaxHealthUpdateEvent = ReplicatedStorage.PlayerStatsEvents:WaitForChild("MaxHealthUpdate")
local StaminaUpdateEvent = ReplicatedStorage.PlayerStatsEvents:WaitForChild("StaminaUpdate")
local SpeedUpdateEvent = ReplicatedStorage.PlayerStatsEvents:WaitForChild("SpeedUpdate")
local PerkUpdateEvent = ReplicatedStorage.PlayerStatsEvents:WaitForChild("PerkUpdate")
local DeathEvent = ReplicatedStorage:WaitForChild("DeathEvent")
local ReviveEvent = ReplicatedStorage:WaitForChild("ReviveEvent")

local PlayerTracker = require(game.ServerScriptService.RoundSystem.PlayerTracker)

local PlayerStatsService = {}

-- Internal table to store player stats keyed by UserId.
local playerData = {}

----------------------------------------------
-- Default Data and Utility Functions
----------------------------------------------

local defaultPlayerData = {
	Guns = {},
	Perks = {},
	MaxHealth = 100,
	Health = 100,
	Stamina = 100,
	SpeedMult = 1,
	DamageMult = 1,
	IsAlive = true
}

-- Creates a fresh copy of the default player data.
local function CreateDefaultData()
	local data = {}
	for key, value in pairs(defaultPlayerData) do
		-- For tables (Guns, Perks), we want to create a new empty table.
		if type(value) == "table" then
			data[key] = {}
		else
			data[key] = value
		end
	end
	return data
end

local function playerDeath(player)
	local data = playerData[player.UserId]
	if data then
		data.IsAlive = false
	end
	PlayerTracker.OnPlayerDied(player)
	PlayerStatsService.RemoveAllPerks(player)
end

local function handleRevive(player)
	local data = playerData[player.UserId]
	if data then
		data.IsAlive = true
		-- Reset health to default value when revived
		data.Health = defaultPlayerData.Health
		-- Update client
		HealthUpdateEvent:FireClient(player, data.Health)
	end
end

----------------------------------------------
-- Player Data Setup and Cleanup
----------------------------------------------

-- Initializes a new player entry.
function PlayerStatsService.SetupPlayer(player)
	playerData[player.UserId] = CreateDefaultData()

	-- Initialize client with starting values
	local data = playerData[player.UserId]
	HealthUpdateEvent:FireClient(player, data.Health)
	MaxHealthUpdateEvent:FireClient(player, data.MaxHealth)
	StaminaUpdateEvent:FireClient(player, data.Stamina)
	SpeedUpdateEvent:FireClient(player, data.SpeedMult)
	PerkUpdateEvent:FireClient(player, data.Perks)
end

-- Cleanup player data when a player leaves.
Players.PlayerRemoving:Connect(function(player)
	playerData[player.UserId] = nil
end)

-- Automatically set up player data on join.
Players.PlayerAdded:Connect(function(player)
	PlayerStatsService.SetupPlayer(player)
end)

-- Set up revive event handler
ReviveEvent.OnServerEvent:Connect(function(player)
	handleRevive(player)
end)

-- Returns the entire player data table for a given player.
function PlayerStatsService.GetPlayerData(player)
	return playerData[player.UserId]
end

----------------------------------------------
-- Guns and Perks Functions
----------------------------------------------

-- Returns the table of guns for a player.
function PlayerStatsService.GetPlayerGuns(player)
	local data = playerData[player.UserId]
	return data and data.Guns
end

-- Returns the table of perks for a player.
function PlayerStatsService.GetPlayerPerks(player)
	local data = playerData[player.UserId]
	return data and data.Perks
end

-- Adds a gun to the player's data.
function PlayerStatsService.AddGun(player, gunName)
	local guns = PlayerStatsService.GetPlayerGuns(player)
	if guns and not guns[gunName] then
		guns[gunName] = true
	end
end

function PlayerStatsService.RemoveAllPerks(player)
	local data = playerData[player.UserId]
	if data then
		data.Perks = {}
		PlayerStatsService.UpdateStatsFromPerks(player)
		PerkUpdateEvent:FireClient(player, data.Perks)
	end
end

-- Adds a perk to the player's data.
function PlayerStatsService.AddPerk(player, perkName)
	local perks = PlayerStatsService.GetPlayerPerks(player)
	if perks then
		table.insert(perks, perkName)
		PlayerStatsService.UpdateStatsFromPerks(player)
		PerkUpdateEvent:FireClient(player, perks)
	end
end

-- Removes a gun.
function PlayerStatsService.RemoveGun(player, gunName)
	local guns = PlayerStatsService.GetPlayerGuns(player)
	if guns then
		guns[gunName] = nil
	end
end

-- Removes a perk.
function PlayerStatsService.RemovePerk(player, perkName)
	local perks = PlayerStatsService.GetPlayerPerks(player)
	if perks then
		local index = table.find(perks, perkName)
		if index then
			table.remove(perks, index)
			PlayerStatsService.UpdateStatsFromPerks(player)
			PerkUpdateEvent:FireClient(player, perks)
		end
	end
end

-- Returns true if player has a gun.
function PlayerStatsService.HasGun(player, gunName)
	local guns = PlayerStatsService.GetPlayerGuns(player)
	return guns and (guns[gunName] or false)
end

-- Returns true if player has a perk.
function PlayerStatsService.HasPerk(player, perkName)
	local perks = PlayerStatsService.GetPlayerPerks(player)
	return perks and table.find(perks, perkName) ~= nil
end

----------------------------------------------
-- Additional Stat Functions
----------------------------------------------

-- Sets the maximum health for a player.
function PlayerStatsService.SetMaxHealth(player, newMaxHealth)
	local data = playerData[player.UserId]
	if data then
		data.MaxHealth = newMaxHealth
		-- Ensure current health is capped by the new max.
		data.Health = math.min(data.Health, newMaxHealth)
		MaxHealthUpdateEvent:FireClient(player, data.MaxHealth)
		HealthUpdateEvent:FireClient(player, data.Health)
	end
end

-- Sets the current health for a player (clamped between 0 and MaxHealth).
function PlayerStatsService.SetHealth(player, newHealth)
	local data = playerData[player.UserId]
	if data then
		data.Health = math.clamp(newHealth, 0, data.MaxHealth)
		HealthUpdateEvent:FireClient(player, data.Health)

		if data.Health <= 0 and data.IsAlive then
			playerDeath(player)
		end
	end
end

-- Adjusts the player's health by a delta (positive or negative).
function PlayerStatsService.AdjustHealth(player, delta)
	local data = playerData[player.UserId]
	if data then
		data.Health = math.clamp(data.Health + delta, 0, data.MaxHealth)
		HealthUpdateEvent:FireClient(player, data.Health)

		if data.Health <= 0 and data.IsAlive then
			playerDeath(player)
		end
	end
end

-- Sets the player's stamina to a new value.
function PlayerStatsService.SetStamina(player, newStamina)
	local data = playerData[player.UserId]
	if data then
		data.Stamina = math.max(0, newStamina)
		StaminaUpdateEvent:FireClient(player, data.Stamina)
	end
end

-- Sets the player's speed multiplier.
function PlayerStatsService.SetSpeedMult(player, newMult)
	local data = playerData[player.UserId]
	if data then
		data.SpeedMult = newMult
		SpeedUpdateEvent:FireClient(player, data.SpeedMult)
	end
end

-- Sets the player's damage multiplier.
function PlayerStatsService.SetDamageMult(player, newMult)
	local data = playerData[player.UserId]
	if data then
		data.DamageMult = newMult
	end
end

function PlayerStatsService.IsAlive(player)
	local data = playerData[player.UserId]
	return data.IsAlive
end

----------------------------------------------
-- Getter Methods for Additional Stats
----------------------------------------------

-- Returns the player's maximum health.
function PlayerStatsService.GetMaxHealth(player)
	local data = playerData[player.UserId]
	return data and data.MaxHealth or 0
end

-- Returns the player's current health.
function PlayerStatsService.GetHealth(player)
	local data = playerData[player.UserId]
	return data and data.Health or 0
end

-- Returns the player's stamina.
function PlayerStatsService.GetStamina(player)
	local data = playerData[player.UserId]
	return data and data.Stamina or 0
end

-- Returns the player's speed multiplier.
function PlayerStatsService.GetSpeedMult(player)
	local data = playerData[player.UserId]
	return data and data.SpeedMult or 1
end

-- Returns the player's damage multiplier.
function PlayerStatsService.GetDamageMult(player)
	local data = playerData[player.UserId]
	return data and data.DamageMult or 1
end

-- Returns whether the player is alive.
function PlayerStatsService.IsPlayerAlive(player)
	local data = playerData[player.UserId]
	return data and data.IsAlive or false
end

-- Revive a player programmatically
function PlayerStatsService.RevivePlayer(player)
	handleRevive(player)
	local index = table.find(PlayerTracker.GetAlivePlayers(), player)
	if not index then
		table.insert(PlayerTracker.GetAlivePlayers(), player)
	end
end

----------------------------------------------
-- End of PlayerStatsService Module
----------------------------------------------

-- Updates all relevant stats for a player based on their current perks
function PlayerStatsService.UpdateStatsFromPerks(player)
	local data = playerData[player.UserId]
	if not data then return end

	-- Reset stats to default
	data.MaxHealth = defaultPlayerData.MaxHealth
	data.SpeedMult = defaultPlayerData.SpeedMult
	data.DamageMult = defaultPlayerData.DamageMult
	data.Stamina = defaultPlayerData.Stamina

	-- Apply perk effects
	for _, perk in ipairs(data.Perks) do
		-- Health Perk
		if perk == "Health" then
			data.MaxHealth = 150
			data.Health = math.min(data.Health, data.MaxHealth)
		end

		-- Damage Perk
		if perk == "Damage" then
			data.DamageMult = 1.5
		end

		-- Speed Perk
		if perk == "Speed" then
			data.SpeedMult = 1.4
		end

		-- Stamina Perk
		if perk == "Stamina" then
			data.Stamina = 150
		end
	end

	-- Fire update events
	MaxHealthUpdateEvent:FireClient(player, data.MaxHealth)
	HealthUpdateEvent:FireClient(player, data.Health)
	StaminaUpdateEvent:FireClient(player, data.Stamina)
	SpeedUpdateEvent:FireClient(player, data.SpeedMult)
end

return PlayerStatsService