local Players = game:GetService("Players")
local player = Players.LocalPlayer
local ReplicateClient = require(script.Parent.ReplicateClient)

-- Play Gui
local PlayGui = player:WaitForChild("PlayerGui"):WaitForChild("PlayGui")
local BG = PlayGui:WaitForChild("BG")
local LobbySelectionFrame = BG:WaitForChild("LobbySelectionFrame")
local LobbyFrame = LobbySelectionFrame:WaitForChild("LobbyFrame")
local ExampleLobbyButton = LobbyFrame:WaitForChild("ExampleLobbyButton")
local MapTitle = LobbySelectionFrame:WaitForChild("MapTitle")

-- Lobby Gui
local LobbyGui = player:WaitForChild("PlayerGui"):WaitForChild("LobbyGui")
local LobbyView = LobbyGui:WaitForChild("LobbyView")
local LobbyInside = LobbyView:WaitForChild("LobbyInside")
local PlayerList = LobbyInside:WaitForChild("PlayerList")
local LobbyName = LobbyInside:WaitForChild("LobbyName")
local ReadyButton = LobbyInside:WaitForChild("ReadyButton")

local PlayScreen = {}

local selectedMap = "Hospital"
local selectedLobbyId = nil
local playerIsReady = false

local JoinButton = LobbySelectionFrame:WaitForChild("JoinButton")

function PlayScreen.LobbyRefresh()
	local lobby = ReplicateClient.GetLobbyData(selectedLobbyId)
	if not lobby then return end

	LobbyName.Text = lobby.name

	-- Clear existing player cards first
	for _, child in pairs(PlayerList:GetChildren()) do
		if child.Name ~= "ExamplePlayerLobbyCard" and child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Add player cards
	local exampleCard = PlayerList:WaitForChild("ExamplePlayerLobbyCard")
	for _, playerData in pairs(lobby.players) do
		local PlayerFrame = exampleCard:Clone()
		PlayerFrame.Name = playerData.name .. "Card"
		PlayerFrame:WaitForChild("PlayerName").Text = playerData.name
		local ready = playerData:GetAttribute("Ready") and "Ready" or "Not Ready"
		PlayerFrame:WaitForChild("ReadyStatus").Text = ready
		PlayerFrame.Visible = true
		PlayerFrame.Parent = PlayerList
	end

	-- Make sure example card is hidden
	exampleCard.Visible = false
end

function PlayScreen.OpenLobbyScreen()
	PlayGui.Enabled = false
	LobbyGui.Enabled = true

	PlayScreen.LobbyRefresh()
end

function PlayScreen.CloseLobbyScreen()
	LobbyGui.Enabled = false
	PlayGui.Enabled = true

	-- Leave the lobby
	ReplicateClient.LeaveLobby()
	selectedLobbyId = nil
	playerIsReady = false
end

function PlayScreen.Refresh()
	MapTitle.Text = selectedMap .. " Lobbies"

	local lobbies = ReplicateClient.GetLobbiesOfMap(selectedMap)

	-- Clear existing lobby buttons first
	for _, child in pairs(LobbyFrame:GetChildren()) do
		if child ~= ExampleLobbyButton and child:IsA("TextButton") then
			child:Destroy()
		end
	end

	-- Create new lobby buttons
	for _, lobby in pairs(lobbies) do
		local button = ExampleLobbyButton:Clone()
		button.Name = "Lobby_" .. lobby.id
		button:WaitForChild("LobbyTitle").Text = lobby.name
		button:WaitForChild("LobbyPlayerCount").Text = #lobby.players .. "/" .. lobby.maxLobbySize
		button.Visible = true
		button.Parent = LobbyFrame

		if lobby.id == selectedLobbyId then
			button.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
		else
			button.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
		end

		button.MouseButton1Click:Connect(function()
			selectedLobbyId = lobby.id

			-- Update UI to show selection
			for _, otherButton in pairs(LobbyFrame:GetChildren()) do
				if otherButton:IsA("TextButton") and otherButton ~= ExampleLobbyButton then
					if otherButton == button then
						otherButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
					else
						otherButton.BackgroundColor3 = Color3.fromRGB(36, 36, 36)
					end
				end
			end
		end)
	end

	-- Make sure example button is hidden
	ExampleLobbyButton.Visible = false

	-- Update join button state based on whether player is in a lobby
	local playerLobbyId = player:GetAttribute("LobbyId")
	if playerLobbyId then
		selectedLobbyId = playerLobbyId
		JoinButton.Text = "Back to Lobby"
	else
		JoinButton.Text = "Join"
	end
end

-- SETUP MAP BUTTONS
local Maps = BG:WaitForChild("Maps")
for _, button in pairs(Maps:GetChildren()) do
	if button:IsA("TextButton") then
		button.MouseButton1Click:Connect(function()
			selectedMap = button.Name
			PlayScreen.Refresh()
		end)
	end
end

local function joinLobby()
	if not selectedMap then 
		warn("No map selected")
		return 
	end

	local isInLobby = player:GetAttribute("LobbyId") ~= nil

	if isInLobby then
		-- If already in a lobby, go to lobby screen
		PlayScreen.OpenLobbyScreen()
		return 
	end

	-- Join Logic
	if not selectedLobbyId then
		warn("No lobby selected")
		return
	end

	local success = ReplicateClient.JoinLobby(selectedLobbyId)
	if success then
		PlayScreen.OpenLobbyScreen()
	else
		warn("Failed to join lobby")
	end

	PlayScreen.Refresh()
end

-- SETUP JOIN Button
JoinButton.MouseButton1Click:Connect(function()
	joinLobby()
end)

-- SETUP REFRESH Button
local RefreshButton = LobbySelectionFrame:WaitForChild("RefreshButton")
RefreshButton.MouseButton1Click:Connect(function()
	PlayScreen.Refresh()
end)

-- SETUP Create Lobby Button
local CreateLobbyButton = LobbySelectionFrame:WaitForChild("CreateLobbyButton")
CreateLobbyButton.MouseButton1Click:Connect(function()
	if not selectedMap then 
		warn("No map selected")
		return 
	end

	if player:GetAttribute("LobbyId") then 
		warn("Already in a lobby")
		return 
	end

	local success, lobbyId = ReplicateClient.CreateLobby(selectedMap)
	if success then
		selectedLobbyId = lobbyId
		joinLobby()
	else
		warn("Failed to create lobby")
	end
end)

local ReadyButton = LobbyInside:WaitForChild("ReadyButton")
local playerIsReady = false
ReadyButton.MouseButton1Click:Connect(function()
	if playerIsReady then
		-- Unready Logic
		local success = ReplicateClient.Unready()
		if success then
			ReadyButton.Text = "Ready"
		end
	else
		-- Ready Logic
		local success = ReplicateClient.Ready()
		if success then
			ReadyButton.Text = "Unready"
		end
	end

	playerIsReady = not playerIsReady
	PlayScreen.LobbyRefresh()
end)

local LeaveButton = LobbyInside:WaitForChild("LeaveButton")
LeaveButton.MouseButton1Click:Connect(function()
	PlayScreen.CloseLobbyScreen()
	PlayScreen.Refresh()
end)

-- Initial refresh
PlayScreen.Refresh()

return PlayScreen