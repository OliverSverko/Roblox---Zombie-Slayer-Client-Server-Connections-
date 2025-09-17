local BarricadeFolder = workspace:WaitForChild("Barricades")
local barricades = BarricadeFolder:GetChildren()
local PhysicsService = game:GetService("PhysicsService")

local ZOMBIE_BREAK_COOLDOWN = 3
local TIME_TO_PLACE = 1

local BarricadeService = {}

-- Adds one bar by making the first fully transparent bar opaque (active).
local function addBar(barricade)
	local bars = barricade:WaitForChild("Bars"):GetChildren()
	for i = 1, #bars do
		if bars[i].Transparency == 1 then
			bars[i].Transparency = 0
			break  -- exit after adding one bar
		end
	end
end

-- Removes one bar by setting the first opaque (active) bar to fully transparent.
local function removeBar(barricade)
	local bars = barricade:WaitForChild("Bars"):GetChildren()
	for i = 1, #bars do
		if bars[i].Transparency == 0 then
			bars[i].Transparency = 1
			break  -- exit after removing one bar
		end
	end
end

-- Returns the number of active bars (bars with Transparency = 0) on the barricade.
local function numberOfActiveBars(barricade)
	local bars = barricade:WaitForChild("Bars"):GetChildren()
	local count = 0
	for i = 1, #bars do
		if bars[i].Transparency == 0 then
			count = count + 1
		end
	end
	return count
end

-- Returns true if the ProximityPrompt should be enabled (i.e. not all bars are active).
local function checkProximityStatus(barricade)
	local bars = barricade:WaitForChild("Bars"):GetChildren()
	local barsActive = numberOfActiveBars(barricade)
	return barsActive < #bars
end

-- Returns true if the Invisible Wall (using hitbox CanCollide) should be active (i.e. at least one bar is active).
local function checkInvisibleWall(barricade)
	local bars = barricade:WaitForChild("Bars"):GetChildren()
	local barsActive = numberOfActiveBars(barricade)
	return barsActive > 0
end

-- Setsup InvisibleWalls
local function setupInvisibleWalls()	
	for i = 1, #barricades do
		local barricade = barricades[i]
		local invisWall = barricade:WaitForChild("InvisibleWall")
		invisWall.CollisionGroup = "BarricadeWall"
		invisWall.CanCollide = checkInvisibleWall(barricade)
	end
end

-- Sets up ProximityPrompts to add a bar when triggered.
local function setupProximityParts()
	for i = 1, #barricades do
		local barricade = barricades[i]
		local promptPart = barricade:WaitForChild("PromptPart")
		promptPart.CollisionGroup = "BarricadeWall"
		local prox = Instance.new("ProximityPrompt")
		local invisWall = barricade:WaitForChild("InvisibleWall")
		prox.Parent = promptPart
		prox.ActionText = "Place"
		prox.ObjectText = "Barricade"
		prox.HoldDuration = TIME_TO_PLACE
		prox.MaxActivationDistance = 6
		prox.RequiresLineOfSight = false
		prox.ClickablePrompt = false

		prox.Enabled = checkProximityStatus(barricade)
		prox.Triggered:Connect(function()
			addBar(barricade)
			prox.Enabled = checkProximityStatus(barricade)
			invisWall.CanCollide = checkInvisibleWall(barricade)
		end)
	end
end

-- Sets up continuous detection for zombies. Instead of relying on Touched events, we
-- use a loop that checks whether any enemy (i.e. part in the Enemies folder) is overlapping.
local function setupZombieHitBoxes()
	local enemiesFolder = workspace:FindFirstChild("Enemies")
	if not enemiesFolder then
		warn("Enemies folder not found in workspace!")
		return
	end

	for i = 1, #barricades do
		local barricade = barricades[i]
		local hitbox = barricade:WaitForChild("ZombieHitbox")
		hitbox.CollisionGroup = "BarricadeWall"
		local canBreak = true
		local invisWall = barricade:WaitForChild("InvisibleWall")
		-- Cache the proximity prompt reference if needed later.
		local prox = barricade:WaitForChild("PromptPart"):WaitForChild("ProximityPrompt")
		-- Use a spawned loop to continuously check for enemies inside the hitbox.
		task.spawn(function()
			while hitbox and hitbox.Parent do
				-- GetTouchingParts returns a table of parts currently touching the hitbox.
				local touching = hitbox:GetTouchingParts()
				local enemyFound = false

				-- Loop through touching parts to see if any is part of the Enemies folder.
				for _, part in ipairs(touching) do
					if part:IsDescendantOf(enemiesFolder) then
						enemyFound = true
						break
					end
				end

				-- If an enemy is detected and the cooldown flag is not active, remove a bar.
				if enemyFound and canBreak then
					removeBar(barricade)
					canBreak = false
					task.delay(ZOMBIE_BREAK_COOLDOWN, function()
						canBreak = true
					end)
				end

				hitbox.CanCollide = checkInvisibleWall(barricade)
				invisWall.CanCollide = checkInvisibleWall(barricade)
				prox.Enabled = checkProximityStatus(barricade)
				task.wait(0.1)  -- Check every 0.1 seconds
			end
		end)
	end
end

-- Initialization function to set up both proximity prompts and zombie hitboxes.
function BarricadeService.Init()
	setupProximityParts()
	setupZombieHitBoxes()
	setupInvisibleWalls()
end

return BarricadeService
