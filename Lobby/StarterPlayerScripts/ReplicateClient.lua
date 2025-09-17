local ReplicateClient = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local PlayerDataRemotes = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("PlayerData")
local LobbyRemotes  = ReplicatedStorage.Remotes:WaitForChild("Lobby")

local ClassData = require(ReplicatedStorage.ClassData)

local bindables = ReplicatedStorage:WaitForChild("BindableEvents"):WaitForChild("Client")

----------------------------------------------------------------------------
-- KEEP DATA UP TO DATE
----------------------------------------------------------------------------

-- Data from this script
local XPUpdate = bindables:WaitForChild("XPUpdate")

-- Data from Server
local Data = {
	unlockedClasses = {},
	selectedClass = nil,
	reviveAlls = 0,
	selfRevives = 0,
	xp = 0,
	gems = 0
}

local UpdateState = PlayerDataRemotes:WaitForChild("UpdateState")
UpdateState.OnClientEvent:Connect(function(incomingData)
	Data = incomingData
	-- Call Bindables
	XPUpdate:Fire()
end)

local Start = PlayerDataRemotes:WaitForChild("Start")
Start:FireServer()

----------------------------------------------------------------------------
-- GET DATA METHODS
----------------------------------------------------------------------------

function ReplicateClient.GetData(player)
	return Data
end

-- unlocked classes

function ReplicateClient.GetUnlockedClasses(player)
	return Data.unlockedClasses
end

function ReplicateClient.HasClassUnlocked(player, class)
	return table.find(Data.unlockedClasses, class)
end

-- selected class

function ReplicateClient.GetClass(player)
	return Data.selectedClass
end

-- revive all

function ReplicateClient.GetReviveAll(player)
	return  Data.reviveAlls
end

-- self revive

function ReplicateClient.GetSelfRevives()
	return Data.selfRevives
end

-- xp

function ReplicateClient.GetXp()
	return Data.xp
end

-- gems

function ReplicateClient.GetGems()
	return Data.gems
end

----------------------------------------------------------------------------
-- CLASS ACTIONS
----------------------------------------------------------------------------

local ClassAttemptPurchase = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ClassAttemptPurchase")

function ReplicateClient.PurchaseClass(className)
	if ReplicateClient.HasClassUnlocked(LocalPlayer, className) then return end
	if not table.find(ClassData, className) then return end
	if ReplicateClient.GetGems() < ClassData[className].Price then return end
	
	ClassAttemptPurchase:FireServer(className)
end

local ClassSelectEvent = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ClassSelectEvent")

function ReplicateClient.SelectClass(className)
	if not ReplicateClient.HasClassUnlocked(LocalPlayer, className) then return end
	if not table.find(ClassData, className) then return end

	ClassSelectEvent:FireServer(className)
end

----------------------------------------------------------------------------
-- KEEP LOBBY DATA UP TO DATE
----------------------------------------------------------------------------

-- Cache for lobby data received from server
local LobbyData = {}
local CurrentLobbyId = nil

-- Initialize event listeners
local LobbyInfoUpdate = LobbyRemotes:WaitForChild("LobbyInfoUpdate")
LobbyInfoUpdate.OnClientEvent:Connect(function(lobbiesData)
	LobbyData = lobbiesData
end)

-- Update CurrentLobbyId when the player's attribute changes
LocalPlayer:GetAttributeChangedSignal("LobbyId"):Connect(function()
	CurrentLobbyId = LocalPlayer:GetAttribute("LobbyId")
end)

-- Initialize current lobby ID
CurrentLobbyId = LocalPlayer:GetAttribute("LobbyId")

----------------------------------------------------------------------------
-- GET LOBBY DATA
----------------------------------------------------------------------------

function ReplicateClient.GetAllLobbyData()
	return LobbyData
end

function ReplicateClient.GetLobbiesOfMap(mapName)
	local listOfLobbies = {}
	for id, lobby in pairs(LobbyData) do
		if lobby.mapName == mapName then
			-- Include the ID with the lobby data
			local lobbyWithId = table.clone(lobby)
			lobbyWithId.id = id
			table.insert(listOfLobbies, lobbyWithId)
		end
	end
	return listOfLobbies
end

function ReplicateClient.GetLobbyData(id)
	if not id or not LobbyData[id] then return nil end
	return LobbyData[id]
end

function ReplicateClient.GetLobbyPlayerCount(id)
	if not id or not LobbyData[id] then return 0 end
	return #LobbyData[id].players
end

function ReplicateClient.GetLobbyMaxLobbySize(id)
	if not id or not LobbyData[id] then return 0 end
	return LobbyData[id].maxLobbySize
end

function ReplicateClient.GetLobbyMap(id)
	if not id or not LobbyData[id] then return nil end
	return LobbyData[id].mapName -- Changed to return mapName string instead of whole lobby
end

function ReplicateClient.IsPlayerInLobby()
	return CurrentLobbyId ~= nil and CurrentLobbyId ~= ""
end

function ReplicateClient.GetCurrentLobbyId()
	return CurrentLobbyId
end

function ReplicateClient.IsPlayerReady()
	return LocalPlayer:GetAttribute("Ready") == true
end

----------------------------------------------------------------------------
-- LOBBY ACTIONS
----------------------------------------------------------------------------
local JoinLobby = LobbyRemotes:WaitForChild("JoinLobby")
function ReplicateClient.JoinLobby(lobbyId)
	if CurrentLobbyId then 
		-- Already in a lobby, leave first
		ReplicateClient.LeaveLobby()
	end

	JoinLobby:FireServer(lobbyId)
	return true
end

local LeaveLobby = LobbyRemotes:WaitForChild("LeaveLobby")
function ReplicateClient.LeaveLobby()
	if not CurrentLobbyId then return false end

	LeaveLobby:FireServer(CurrentLobbyId)
	return true
end

local Ready = LobbyRemotes:WaitForChild("Ready")
function ReplicateClient.Ready()
	if not CurrentLobbyId then return false end

	Ready:FireServer(CurrentLobbyId)
	return true
end

local Unready = LobbyRemotes:WaitForChild("Unready")
function ReplicateClient.Unready()
	if not CurrentLobbyId then return false end
	
	Unready:FireServer(CurrentLobbyId)
	return true
end

local CreateLobby = LobbyRemotes:WaitForChild("CreateLobby")
function ReplicateClient.CreateLobby(mapName)
	if CurrentLobbyId then return false end

	local result, id = CreateLobby:InvokeServer(mapName)
	return result, id
end

-- New function to check if all players in the current lobby are ready
function ReplicateClient.AreAllPlayersReady()
	if not CurrentLobbyId or not LobbyData[CurrentLobbyId] then 
		return false 
	end

	local lobby = LobbyData[CurrentLobbyId]
	if #lobby.players == 0 then
		return false
	end

	for _, player in ipairs(lobby.players) do
		if not player:GetAttribute("Ready") then
			return false
		end
	end

	return true
end

--
return ReplicateClient
