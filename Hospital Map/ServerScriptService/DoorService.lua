local ServerScriptService = game:GetService("ServerScriptService")
local ZombieTracker = require(game.ServerScriptService.RoundSystem.ZombieTracker)
ZombieTracker.UpdateActiveSpawnPoints("START")

-- Initialize your Doors folder (ensure your workspace has a child called "Doors").
local DoorsFolder = workspace:WaitForChild("Doors")
local doors = {
	BackRoom = {
		Parts = {
			DoorsFolder:WaitForChild("BackRoom1"),
			DoorsFolder:WaitForChild("BackRoom2")
		},
		Cost = 100
	},
	DrugLab = {
		Parts = {
			DoorsFolder:WaitForChild("DrugLab")
		},
		Cost = 250
	},
	HospitalArea = {
		Parts = {
			DoorsFolder:WaitForChild("HospitalArea")
		},
		Cost = 750
	},
	LongHallway = {
		Parts = {
			DoorsFolder:WaitForChild("LongHallway")
		},
		Cost = 1000
	},
	SideRoom = {
		Parts = {
			DoorsFolder:WaitForChild("SideRoom")
		},
		Cost = 1500
	},
	SurgeryRoom = {
		Parts = {
			DoorsFolder:WaitForChild("SurgeryRoom")
		},
		Cost = 2000
	}
}

local CoinService = require(game.ServerScriptService.CoinService)
local DoorService = {}

-- Helper: Disables and visually unlocks the door parts.
local function UnlockDoor(doorName)
	if not doors[doorName] then return end

	for _, part in ipairs(doors[doorName].Parts) do
		part.CanCollide = false
		part.CanQuery = false
		part.Transparency = 1
		part.CastShadow = false
	
		local prompt = part:FindFirstChild("UnlockPrompt")
		if prompt then
			prompt:Destroy()
		end
	end
end

-- Returns door configuration data.
function DoorService:DoorData()
	return doors
end

--- Attempts to unlock a door for the player.
-- If successful, removes coins, updates spawn points, and unlocks the door visually.
function DoorService:AttemptToUnlock(player, doorName)
	if not doors[doorName] then
		warn("[DoorService] Door '" .. doorName .. "' does not exist.")
		return
	end

	local playerCoins = CoinService.GetCoins(player)
	local doorCost = doors[doorName].Cost

	if playerCoins >= doorCost then
		CoinService.DecrementCoins(player, doorCost)
		-- Update active monster spawn points to the new area.
		ZombieTracker.UpdateActiveSpawnPoints(doorName)
		UnlockDoor(doorName)
	else
		print("[DoorService] Insufficient coins to unlock door: " .. doorName)
	end
end

return DoorService
