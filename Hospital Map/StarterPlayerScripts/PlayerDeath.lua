
	-- Combined DeathGUI and Camera Control Script with Fixed Dead Camera and Hidden Mouse
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
	local starterPlayer = game:GetService("StarterPlayer")
	local UserInputService = game:GetService("UserInputService")
	local Workspace = game:GetService("Workspace")

	-- Camera settings
	local FORCE_MIN_ZOOM = 0.5
	local FORCE_MAX_ZOOM = 0.5
	local FORCE_MODE = Enum.CameraMode.LockFirstPerson

	-- Get local player
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- Find the DeathGui in PlayerGui (not StarterGui)
	local deathGui = playerGui:WaitForChild("DeathGui")
	local deathFrame = deathGui:WaitForChild("DeathFrame")
	local playerCounterFrame = deathFrame:WaitForChild("PlayerCounterFrame")
	local playersAliveAmount = playerCounterFrame:WaitForChild("PlayersAliveAmount")
	local playersAliveText = playerCounterFrame:WaitForChild("PlayersAliveText")
	local selfRevive = deathFrame:WaitForChild("SelfRevive")
	local deadText = deathFrame:WaitForChild("DeadText")

	-- Game Over Screen
	local GameOverCountDown = deathGui:WaitForChild("GameOverCountDown")


	-- Rewards Screen
	local BackToLobbyButton = GameOverCountDown:WaitForChild("ExitFrame"):WaitForChild("ExitButton")

	-- Get remote events
	local deathEvent = ReplicatedStorage:WaitForChild("DeathEvent")
	local reviveEvent = ReplicatedStorage:WaitForChild("ReviveEvent")
	local GameOver = ReplicatedStorage:WaitForChild("GameOver")

	-- Get player stats events
	local playerStatsEvents = ReplicatedStorage:WaitForChild("PlayerStatsEvents")
	local healthUpdateEvent = playerStatsEvents:WaitForChild("HealthUpdate")

	-- Get player count events
	local updatePlayersAliveCount = ReplicatedStorage:WaitForChild("UpdatePlayersAliveCount")
	local requestPlayersAliveCount = ReplicatedStorage:WaitForChild("RequestPlayersAliveCount")
	local allPlayersDeadEvent = ReplicatedStorage:WaitForChild("AllPlayersDead")

	-- Variables
	local isDead = false
	local selfReviveButton = selfRevive -- The button to self-revive
	local selfReviveEnabled = true -- Always enabled now
	local cameraControlConnection = nil
	local originalCameraSubject = nil
	local deadCameraConnection = nil
	local characterControlConnection = nil
	local toolsConnection = nil
	local originalWalkSpeed = 16
	local originalJumpPower = 50
	local originalBackpackEnabled = nil
	local inventoryConnection = nil
	local originalMouseIcon = ""
	local originalMouseBehavior = Enum.MouseBehavior.Default
	local isHoldingGun = false -- Track if player is holding a gun

	-- Initial GUI setup
	deathGui.Enabled = true -- DeathGui always enabled
	deathFrame.Visible = false -- DeathFrame initially hidden
	deathFrame.BackgroundTransparency = 1 -- Fully transparent initially

	-- Setup mouse interaction properties
	deathFrame.Active = false
	deathFrame.Selectable = false


	-- Only make the self revive button interactive
	selfRevive.Active = true
	selfRevive.Selectable = true

	-- Function to check if a tool is part of the FE Gun Kit
	local function isGunKitTool(tool)
		-- Check if the tool has components that are typical for FE Gun Kit
		-- You may need to adjust this based on your specific FE Gun Kit implementation
		return tool:FindFirstChild("GunScript") ~= nil or 
			tool:FindFirstChild("GunSettings") ~= nil or
			tool:FindFirstChild("Crosshair") ~= nil
	end

	-- Function to hide mouse cursor when alive and not using GUI elements
	local function hideMouseForAliveState()
		-- Hide the mouse cursor by setting MouseIconEnabled to false
		UserInputService.MouseIconEnabled = false

		-- Lock the mouse in center of screen (first-person camera control)
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end

	-- Function to show mouse cursor when dead
	local function setMouseForDeadState()
		-- Store the original icon and behavior
		originalMouseIcon = UserInputService.MouseIcon
		originalMouseBehavior = UserInputService.MouseBehavior

		-- Set a blank or default cursor
		UserInputService.MouseIcon = ""

		-- Show the cursor and allow free movement
		UserInputService.MouseIconEnabled = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	-- Function to restore normal mouse functionality
	local function restoreMouseState()
		-- Restore original mouse icon and behavior
		UserInputService.MouseIcon = originalMouseIcon
		UserInputService.MouseBehavior = originalMouseBehavior

		-- Make sure cursor is visible for GUI interactions
		pcall(function()
			game:GetService("StarterGui"):SetCore("CursorVisibility", true)
		end)

		-- Then immediately hide it again if alive
		if not isDead then
			hideMouseForAliveState()
		else
			UserInputService.MouseIconEnabled = true
		end
	end

	-- Function to disable player inventory
	local function disableInventory()
		-- Store original backpack visibility
		originalBackpackEnabled = player.PlayerGui:FindFirstChild("Backpack") and 
			player.PlayerGui.Backpack.Enabled or false

		-- Disable backpack GUI
		if player.PlayerGui:FindFirstChild("Backpack") then
			player.PlayerGui.Backpack.Enabled = false
		end

		-- Disable the core inventory if available through StarterGui
		pcall(function()
			game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)

		-- Move any equipped tools to the backpack
		local character = player.Character
		if character then
			for _, tool in pairs(character:GetChildren()) do
				if tool:IsA("Tool") then
					tool.Parent = player.Backpack
				end
			end
		end

		-- Prevent equipping tools while dead
		inventoryConnection = player.Backpack.ChildAdded:Connect(function(item)
			if item:IsA("Tool") and isDead then
				-- If someone tries to give the player a tool or script tries to equip it
				-- Ensure it stays in backpack and doesn't get equipped
				task.wait()
				if item.Parent == player.Character then
					item.Parent = player.Backpack
				end
			end
		end)
	end

	-- Function to restore player inventory
	local function restoreInventory()
		-- Disconnect inventory blocking
		if inventoryConnection then
			inventoryConnection:Disconnect()
			inventoryConnection = nil
		end

		-- Restore backpack GUI
		if player.PlayerGui:FindFirstChild("Backpack") and originalBackpackEnabled ~= nil then
			player.PlayerGui.Backpack.Enabled = originalBackpackEnabled
		end

		-- Re-enable the core inventory
		pcall(function()
			game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
		end)
	end

	-- Function to handle tool equipped/unequipped to check for guns
	local function setupToolEquippedListener()
		local character = player.Character
		if character then
			-- Check initially equipped tools
			for _, item in pairs(character:GetChildren()) do
				if item:IsA("Tool") then
					isHoldingGun = isGunKitTool(item)
				end
			end

			-- Listen for newly equipped tools
			character.ChildAdded:Connect(function(child)
				if child:IsA("Tool") and not isDead then
					isHoldingGun = isGunKitTool(child)
				end
			end)

			-- Listen for unequipped tools
			character.ChildRemoved:Connect(function(child)
				if child:IsA("Tool") and not isDead then
					isHoldingGun = false

					-- Check if any other tool is equipped
					for _, item in pairs(character:GetChildren()) do
						if item:IsA("Tool") then
							isHoldingGun = isGunKitTool(item)
							if isHoldingGun then break end
						end
					end
				end
			end)
		end
	end

	-- Function to disable character control
	local function disableCharacterControl()
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				-- Store original values
				originalWalkSpeed = humanoid.WalkSpeed
				originalJumpPower = humanoid.JumpPower

				-- Disable movement and jumping
				humanoid.WalkSpeed = 0
				humanoid.JumpPower = 0

				-- Unequip any tools
				if humanoid:GetState() ~= Enum.HumanoidStateType.Dead then
					humanoid:UnequipTools()
				end
			end

			-- Prevent tool usage
			toolsConnection = character.ChildAdded:Connect(function(child)
				if child:IsA("Tool") and isDead then
					task.wait() -- Wait a frame
					child.Parent = player.Backpack
				end
			end)
		end

		-- Disable inventory
		disableInventory()

		-- Set mouse state for dead mode
		setMouseForDeadState()
	end

	-- Function to restore character control
	local function restoreCharacterControl()
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				-- Restore original values
				humanoid.WalkSpeed = originalWalkSpeed
				humanoid.JumpPower = originalJumpPower
			end
		end

		-- Disconnect tool prevention
		if toolsConnection then
			toolsConnection:Disconnect()
			toolsConnection = nil
		end

		-- Restore inventory
		restoreInventory()

		-- Setup tool equipped listener for gun detection
		setupToolEquippedListener()

		-- Hide mouse for alive state (instead of restoring)
		hideMouseForAliveState()
	end

	-- Camera and mouse control functions
	local function setFirstPersonMode()
		-- Restore original camera subject (player's character)
		local character = player.Character
		if character then
			workspace.CurrentCamera.CameraSubject = character:FindFirstChildOfClass("Humanoid") or character.PrimaryPart
		end

		-- Force camera mode
		player.CameraMode = FORCE_MODE
		-- Clamp zoom distances
		starterPlayer.CameraMinZoomDistance = FORCE_MIN_ZOOM
		starterPlayer.CameraMaxZoomDistance = FORCE_MAX_ZOOM

		-- Hide mouse and lock to center when alive
		hideMouseForAliveState()

		-- Enable camera movement
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	end

	local function setDeadCamera()
		-- Save original camera subject if not already saved
		if not originalCameraSubject and workspace.CurrentCamera.CameraSubject then
			originalCameraSubject = workspace.CurrentCamera.CameraSubject
		end

		-- Find the DeadCamera object in workspace
		local deadCamera = Workspace:FindFirstChild("DeadCamera")
		if deadCamera then
			-- Set camera to DeadCamera object
			workspace.CurrentCamera.CameraSubject = deadCamera

			-- Lock camera position but allow mouse movement
			player.CameraMode = Enum.CameraMode.Classic
			workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

			-- Set camera to the position of the DeadCamera
			workspace.CurrentCamera.CFrame = deadCamera.CFrame
		else
			warn("DeadCamera object not found in Workspace")
			-- Fallback to a scriptable camera if no DeadCamera is found
			workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
		end

		-- Show and free mouse cursor for dead state
		setMouseForDeadState()
	end

	-- Function to disable all other GUIs except DeathGui
	local function toggleOtherGuis(shouldDisable)
		local otherGuis = {"HurtEffect","ScreenGui","StaminaAndHealthBar"}
		for _, guiName in pairs(otherGuis) do
			local gui = playerGui:FindFirstChild(guiName)
			if gui and gui:IsA("ScreenGui") and gui ~= deathGui then
				gui.Enabled = not shouldDisable
			end
		end
	end

	-- Local functions
	local playersAliveCount = 0
	local function updatePlayersAliveCounter(count)
		playersAliveCount = count
		playersAliveAmount.Text = tostring(count)
		playersAliveText.Text = count == 1 and "Player Alive" or "Players Alive"
	end

	-- Inside the showDeathGui() function, replace the tween section with this:
	local function showDeathGui()
		isDead = true

		-- Disable all other GUIs
		toggleOtherGuis(true)

		-- Disable character control, inventory, and set mouse state
		disableCharacterControl()

		-- Watch for the DeadCamera if it doesn't exist yet
		if not Workspace:FindFirstChild("DeadCamera") then
			deadCameraConnection = Workspace.ChildAdded:Connect(function(child)
				if child.Name == "DeadCamera" and isDead then
					-- Don't immediately set camera - will happen after fade
					if deadCameraConnection then
						deadCameraConnection:Disconnect()
						deadCameraConnection = nil
					end
				end
			end)
		end
		setDeadCamera()

		deathFrame.Visible = true

		-- Request latest player count from server
		requestPlayersAliveCount:FireServer()

		-- Disconnect any existing camera control
		if cameraControlConnection then
			cameraControlConnection:Disconnect()
			cameraControlConnection = nil
		end

		-- Only set up fixed camera control after camera has been switched
		characterControlConnection = RunService:BindToRenderStep(
			"FixDeadCamera",
			Enum.RenderPriority.Last.Value,
			function()
				if isDead and workspace.CurrentCamera.CameraSubject and
					workspace.CurrentCamera.CameraSubject.Name == "DeadCamera" then
					local deadCamera = Workspace:FindFirstChild("DeadCamera")
					if deadCamera then
						-- Keep the camera position fixed but allow rotation
						local currentCFrame = workspace.CurrentCamera.CFrame
						workspace.CurrentCamera.CFrame = CFrame.new(deadCamera.Position)
							* CFrame.Angles(currentCFrame:ToEulerAnglesXYZ())
					end
				end
			end
		)
	end

	local function hideDeathGui()
		isDead = false

		-- Disconnect any watching for DeadCamera
		if deadCameraConnection then
			deadCameraConnection:Disconnect()
			deadCameraConnection = nil
		end

		-- Disconnect fixed camera position
		if characterControlConnection then
			RunService:UnbindFromRenderStep("FixDeadCamera")
			characterControlConnection = nil
		end

		-- Restore character control (and inventory and mouse state)
		restoreCharacterControl()

		deathFrame.Visible      = false

		-- Set back to first person when alive
		setFirstPersonMode()

		toggleOtherGuis(false)

		-- Re-apply first person every frame
		if not cameraControlConnection then
			cameraControlConnection = RunService:BindToRenderStep(
				"ForceFirstPerson",
				Enum.RenderPriority.Last.Value + 1,
				function()
					if not isDead then
						setFirstPersonMode()
						if not isHoldingGun then
							hideMouseForAliveState()
						end
					end
				end
			)
		end
	end


	-- Event handlers
	deathEvent.OnClientEvent:Connect(function()
		showDeathGui()
		GameOverCountDown.Visible = false
	end)

	reviveEvent.OnClientEvent:Connect(function()
		hideDeathGui()
		GameOverCountDown.Visible = false
	end)

	allPlayersDeadEvent.OnClientEvent:Connect(function(timeLeft)
		--ADD IMPLEMENTATION
		deathFrame.Visible = false
		GameOverCountDown.Visible = true
	end)

	GameOver.OnClientEvent:Connect(function()
		-- ADD IMPLEMENTATION
		deathFrame.Visible = false
		GameOverCountDown.Visible = false
	end)

	-- Handler for receiving player alive count updates
	updatePlayersAliveCount.OnClientEvent:Connect(function(count)
		updatePlayersAliveCounter(count)
	end)

	----------------------------------------------------------------------------------------------------
	-- Self Revive and Revive All Buttons
	----------------------------------------------------------------------------------------------------

	-- Self-revive button click handler
	local AttemptSelfRevive = ReplicatedStorage:WaitForChild("AttemptSelfRevive")
	selfRevive.MouseButton1Click:Connect(function()
		if isDead then
			AttemptSelfRevive:FireServer()
		end
	end)

	local reviveAllButton = player:WaitForChild("PlayerGui"):WaitForChild("DeathGui"):WaitForChild("GameOverCountDown"):WaitForChild("ReviveAll")
	local AttemptReviveAll = ReplicatedStorage:WaitForChild("AttemptReviveAll")
	reviveAllButton.MouseButton1Click:Connect(function()
		if isDead and playersAliveCount == 0 then
			AttemptReviveAll:FireServer()
		end
	end)

	----------------------------------------------------------------------------------------------------

	-- Handle character respawning
	player.CharacterAdded:Connect(function(character)
		if isDead then
			-- If player respawns while marked as dead, disable control immediately
			disableCharacterControl()
		else
			-- Ensure character has proper controls if alive
			restoreCharacterControl()
			-- Setup tool equipped listener for gun detection
			setupToolEquippedListener()
		end
	end)

	-- Handle GUI interaction showing cursor temporarily
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not isDead and not gameProcessed then
			if input.KeyCode == Enum.KeyCode.Tab or 
				input.KeyCode == Enum.KeyCode.I or -- Changed from Backpack to I key (inventory)
				input.KeyCode == Enum.KeyCode.Escape then
				-- Temporarily show cursor for inventory/menu
				UserInputService.MouseIconEnabled = true
				UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if not isDead and not gameProcessed then
			if input.KeyCode == Enum.KeyCode.Tab or 
				input.KeyCode == Enum.KeyCode.I or 
				input.KeyCode == Enum.KeyCode.Escape then
				-- Hide cursor again after inventory/menu closes
				task.wait(0.1) -- Small delay to ensure menu has closed
				if not isHoldingGun then
					hideMouseForAliveState()
				end
			end
		end
	end)

	-- Set initial camera state (first person) and hide mouse
	setFirstPersonMode()

	-- Setup tool equipped listener for gun detection
	setupToolEquippedListener()

	-- Initial binding of camera controls
	cameraControlConnection = RunService:BindToRenderStep(
		"ForceFirstPerson", 
		Enum.RenderPriority.Last.Value + 1, 
		function()
			if not isDead then
				setFirstPersonMode()

				-- Keep mouse hidden but allow FE Gun Kit crosshairs to work
				if not isHoldingGun then
					hideMouseForAliveState()
				end
			end
		end
	)

	-- Request initial player count
	requestPlayersAliveCount:FireServer()

	-- Listen for health updates to sync with server health system
	healthUpdateEvent.OnClientEvent:Connect(function(newHealth)
		-- If we get back to positive health while marked as dead, we should hide the death GUI
		if isDead and newHealth > 0 then
			hideDeathGui()
		end
	end)