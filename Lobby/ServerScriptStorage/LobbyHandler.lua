local LobbyHandler = {}
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local remotes = game.ReplicatedStorage.Remotes.Lobby

-- Info
local mapIds = {
	Hospital = 136806204501870
}

local defaultLobby = {
	players = {},
	name = "",
	mapName = "Hospital",
	maxLobbySize = 4
}

local Lobbies = {}

---------------------------------------------------------------------------------
-- Send Lobby info to players
---------------------------------------------------------------------------------
local LobbyInfoUpdate = remotes.LobbyInfoUpdate
local function InformAllClients()
	LobbyInfoUpdate:FireAllClients(Lobbies)
end

---------------------------------------------------------------------------------
-- Lobby Control
---------------------------------------------------------------------------------
function LobbyHandler.createLobby(nameOfLobby, nameOfMap)
	local newLobby = table.clone(defaultLobby)
	newLobby.name = nameOfLobby
	newLobby.mapName = nameOfMap
	local id = HttpService:GenerateGUID(true)
	Lobbies[id] = newLobby

	InformAllClients()

	return newLobby, id
end

local function deleteLobby(id)
	Lobbies[id] = nil

	InformAllClients()
end

local function joinLobby(id, player)
	local lobby = Lobbies[id]
	if lobby and lobby.maxLobbySize > #lobby.players then
		table.insert(lobby.players, player)
		InformAllClients()
		return true
	end
	return false
end

local function leaveLobby(id, player)
	local lobby = Lobbies[id]
	if lobby and table.find(lobby.players, player) then
		table.remove(lobby.players, table.find(lobby.players, player))
		InformAllClients()

		-- Auto-delete empty lobbies
		if #lobby.players == 0 then
			deleteLobby(id)
		end
	end
end

---------------------------------------------------------------------------------
-- Send Lobby of Players to Game
---------------------------------------------------------------------------------
local function allPlayersReady(lobbyId)
	local lobby = Lobbies[lobbyId]
	if not lobby then return false end

	local players = lobby.players
	if #players <= 0 then
		return false
	end

	for _, player in ipairs(players) do
		if not player:GetAttribute("Ready") then
			return false
		end
	end

	return true
end

function LobbyHandler.sendLobbyToMap(lobbyId)
	local lobby = Lobbies[lobbyId]
	if not lobby then
		warn("Invalid lobbyId provided to sendLobbyToMap")
		return false
	end

	local mapName = lobby.mapName
	local placeId = mapIds[mapName]

	if not placeId then
		warn("Invalid mapName in lobby")
		return false
	end

	if not allPlayersReady(lobbyId) then
		warn("Not all players are ready")
		return false
	end

	-- Get player instances for teleport
	local playersToTeleport = {}
	for _, player in ipairs(lobby.players) do
		-- This should be Players:GetPlayerByUserId(player.UserId) if player is a Player object
		-- or just use the player directly if it's already a Player instance
		table.insert(playersToTeleport, player)
	end

	if #playersToTeleport == 0 then
		warn("No valid players to teleport")
		return false
	end

	-- Create teleport options with custom data if needed
	local teleportOptions = Instance.new("TeleportOptions")
	teleportOptions.ShouldReserveServer = true

	-- You can pass any data to the target place using this
	local teleportData = {
		lobbyName = lobby.name,
		lobbyId = lobbyId,
		mapName = mapName,
		players = {} -- Add any player data you want to send here
	}

	-- Add player data to teleportData
	for _, player in ipairs(lobby.players) do
		table.insert(teleportData.players, {
			userId = player.UserId,
			name = player.Name
		})
	end

	teleportOptions:SetTeleportData(teleportData)

	-- Create and teleport to reserved server
	local success, reservedServerCode

	success, reservedServerCode = pcall(function()
		return TeleportService:ReserveServer(placeId)
	end)

	if success and reservedServerCode then
		-- Log the teleport attempt
		print("Teleporting lobby " .. lobbyId .. " to map " .. mapName)

		-- Teleport the players
		success = pcall(function()
			TeleportService:TeleportToPrivateServer(placeId, reservedServerCode, playersToTeleport, nil, teleportOptions)
		end)

		if success then
			-- Delete the lobby after successful teleport
			deleteLobby(lobbyId)
			return true
		else
			warn("Failed to teleport players to private server")
		end
	else
		warn("Failed to reserve server: " .. tostring(reservedServerCode))
	end

	return false
end

---------------------------------------------------------------------------------
-- Player Events
---------------------------------------------------------------------------------
local JoinLobby = remotes.JoinLobby
JoinLobby.OnServerEvent:Connect(function(player, lobbyId)
	if joinLobby(lobbyId, player) then
		player:SetAttribute("LobbyId", lobbyId)
	end
end)

local LeaveLobby = remotes.LeaveLobby
LeaveLobby.OnServerEvent:Connect(function(player, lobbyId)
	leaveLobby(lobbyId, player)
	player:SetAttribute("LobbyId", "")
end)

local Ready = remotes.Ready
Ready.OnServerEvent:Connect(function(player, lobbyId)
	player:SetAttribute("Ready", true)

	-- Auto-start game if all players are ready
	if allPlayersReady(lobbyId) then
		LobbyHandler.sendLobbyToMap(lobbyId)
	end
end)

local Unready = remotes.Unready
Unready.OnServerEvent:Connect(function(player, lobbyId)
	player:SetAttribute("Ready", false)
end)

local CreateLobby = remotes.CreateLobby
-- FIX: Changed this from direct assignment to proper remote event connection
CreateLobby.OnServerInvoke = function(player, mapName)
	-- FIX: Fixed this check, it was inverted and checking if player was already in a lobby
	if player:GetAttribute("LobbyId") and player:GetAttribute("LobbyId") ~= "" then 
		return false -- Player is already in a lobby
	end

	local lobby, id = LobbyHandler.createLobby(player.Name.. "'s Lobby", mapName)
	if joinLobby(id, player) then
		player:SetAttribute("LobbyId", id)
		return true, id
	end
	return false
end

-- Handle player leaving game
Players.PlayerRemoving:Connect(function(player)
	local lobbyId = player:GetAttribute("LobbyId")
	if lobbyId and lobbyId ~= "" then
		leaveLobby(lobbyId, player)
	end
end)

-- Good addition to update clients when a new player joins the game
Players.PlayerAdded:Connect(function(player)
	wait(3)
	InformAllClients()
end)

return LobbyHandler