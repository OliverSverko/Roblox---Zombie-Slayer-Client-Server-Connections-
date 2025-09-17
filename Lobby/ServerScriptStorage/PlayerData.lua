local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = ReplicatedStorage.Remotes.PlayerData

local PlayerDataTemplate = require(ReplicatedStorage.PlayerDataTemplate)
local ProfileStore = require(ServerScriptService.ProfileStore)

local DATA_STORE_KEY = "Production5"

if RunService:IsStudio() then
	DATA_STORE_KEY = "Testing1"
end

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

-- unlocked classes

function Shared.GetUnlockedClasses(player): PlayerDataTemplate.PlayerData?
	local profile = Profiles[player]
	if not profile then return end

	return profile.Data.unlockedClasses
end

function Shared.HasClassUnlocked(player, class)
	local profile = Profiles[player]
	if not profile then return end
	
	return table.find(profile.Data.unlockedClasses, class)
end

function Shared.UnlockClass(player, class): PlayerDataTemplate.PlayerData?
	local profile = Profiles[player]
	if not profile then return end

	table.insert(profile.Data.unlockedClasses, class)
end

-- selected class

function Shared.GetClass(player): PlayerDataTemplate.PlayerData?
	local profile = Profiles[player]
	if not profile then return end

	return profile.Data.selectedClass
end

function Shared.SetClass(player, class): PlayerDataTemplate.PlayerData?
	local profile = Profiles[player]
	if not profile then return end
	profile.Data.selectedClass = class
end

-- revival alls

function Shared.UpdateReviveAll(player, amount): PlayerDataTemplate.PlayerData?
	local profile = Profiles[player]
	if not profile then return end
	profile.Data.reviveAlls += amount
end

function Shared.GetReviveAll(player): PlayerDataTemplate.PlayerData?
	local profile = Profiles[player]
	if not profile then return end
	return  profile.Data.reviveAlls
end

-- self revive

function Shared.UpdateSelfRevive(player, amount): PlayerDataTemplate.PlayerData?
	local profile = Profiles[player]
	if not profile then return end
	profile.Data.selfRevives += amount
end

function Shared.GetSelfRevives(player): PlayerDataTemplate.PlayerData?
	local profile = Profiles[player]
	if not profile then return end
	return profile.Data.selfRevives
end

-- xp

function Shared.GetXp(player)
	local profile = Profiles[player]
	if not profile then return end

	return profile.Data.xp
end

function Shared.AddXp(player, amount)
	local profile = Profiles[player]
	if not profile then return end

	profile.Data.xp = profile.Data.xp + amount
end

-- gems

function Shared.GetGems(player)
	local profile = Profiles[player]
	if not profile then return end

	return profile.Data.gems
end

function Shared.AddGems(player, amount)
	local profile = Profiles[player]
	if not profile then return end

	profile.Data.gems = profile.Data.gems + amount
end


-----------------------------------------------------------------

Local.OnStart()

return Shared
