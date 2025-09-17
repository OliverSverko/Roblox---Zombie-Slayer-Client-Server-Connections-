-- ServerScriptService > DoorPromptHandler

local DoorService = require(script.DoorService)

local doorsData = DoorService:DoorData()

-- Function to create proximity prompt
local function createPrompt(doorName, doorPart)
	local prompt = Instance.new("ProximityPrompt")
	
	prompt.ActionText = "Unlock " .. doorName
	prompt.ObjectText = tostring(doorsData[doorName].Cost) .. " Coins"

	prompt.HoldDuration = 1.5
	prompt.MaxActivationDistance = 10
	prompt.ClickablePrompt = false
	prompt.Name = "UnlockPrompt"
	prompt.Parent = doorPart
	prompt.ClickablePrompt = false
	prompt.RequiresLineOfSight = false

	prompt.Triggered:Connect(function(player)
		DoorService:AttemptToUnlock(player, doorName)
	end)
end

-- Loop through doors and parts to add prompts
for doorName, doorInfo in pairs(doorsData) do
	for _, part in ipairs(doorInfo.Parts) do
		-- Prevent adding multiple prompts if the script is re-run
		if not part:FindFirstChild("UnlockPrompt") then
			createPrompt(doorName, part)
		end
	end
end
