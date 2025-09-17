local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = ReplicatedStorage.PlayerDataEvents

local PlayerDataTemplate = require(ReplicatedStorage.PlayerDataTemplate)
local ProfileStore = require(ServerScriptService.ProfileStore)

local DATA_STORE_KEY = "Production3"

--if RunService:IsStudio() then
--	DATA_STORE_KEY = "Test"
--end

local PlayerStore = ProfileStore.New(DATA_STORE_KEY, PlayerDataTemplate.DEFEAULT_PLAYER_DATA)
local Profiles: {[player]: typeof(PlayerStore:StartSessionAsync())} = {}

local Local = {}
local Shared = {}

function Local.OnStart()
	Remotes.Start.OnServerEvent:Connect(function(player: Player)
		local state = Shared.GetData(player)
		if state then
			Remotes.UpdateState:FireClient(player, state)
		end
	end)
	
	for _, player in Players:GetPlayers() do
		task.spawn(Local.LoadProfile, player)
	end
	
	Players.PlayerAdded:Connect(Local.LoadProfile)
	Players.PlayerRemoving:Connect(Local.RemoveProfile)
end

function Shared.GetState(player: Player)
	local profile = Profiles[player]
	if profile then
		return profile.Data
	end
end

function Local.LoadProfile(player: Player)
	local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	
	if profile == nil then
		return player:Kick("Profile load fail. Please rejoin.")
	end
	
	profile:AddUserId(player.UserId)
	profile:Reconcile()
	
	profile.OnSessionEnd:Connect(function()
		Profiles[player] = nil
		player:Kick("Profile session ended. Please rejoin.")
	end)
	
	local isInGame = player.Parent == Players
	if isInGame then
		Profiles[player] = profile
	else
		profile:EndSession()
	end
	
	Remotes.UpdateState:FireClient(player, profile.Data)
end

function Local.RemoveProfile(player: Player)
	local profile = Profiles[player]
	if profile ~= nil then
		profile:EndSession()
	end
end

-- Functions To Use --------------------------------------------

function Shared.GetData(player): PlayerDataTemplate.PlayerData?
	local profile = Profiles[player]
	if not profile then return end
	
	return profile.Data
end

function Shared.AddXp(player, amount)
	local profile = Profiles[player]
	if not profile then return end

	profile.Data.xp = profile.Data.xp + amount
end

-----------------------------------------------------------------

Local.OnStart()

return Shared
