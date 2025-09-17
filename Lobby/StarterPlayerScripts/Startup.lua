--StartUp
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local gui = player:WaitForChild("PlayerGui")
local mainGui = gui:WaitForChild("MainGui")
local shopGui = gui:WaitForChild("ShopGui")
local settingsGui = gui:WaitForChild("SettingsGui")
local playGui = gui:WaitForChild("PlayGui")

local cameraParts = {
	Main = workspace:WaitForChild("GUI"):WaitForChild("CameraPart"),
	Settings = workspace:WaitForChild("SettingsCamera"),
	Shop = workspace:WaitForChild("ShopCamera")
}

local FIRST_CAMERA_MOVE_DURATION = 5
local SUBSEQUENT_CAMERA_MOVE_DURATION = 0.75
local CAMERA_EASE_STYLE = Enum.EasingStyle.Quart
local CAMERA_EASE_DIRECTION = Enum.EasingDirection.Out
local UI_FADE_DURATION = 1.5
local UI_FADE_STYLE = Enum.EasingStyle.Sine
local CAMERA_START_DISTANCE = 15
local ELEMENT_CASCADE_DELAY = 0.05

local mainUIFrame = mainGui:WaitForChild("BG")
local shopUIFrame = shopGui:WaitForChild("BG")
local settingsUIFrame = settingsGui:WaitForChild("BG")
local playUIFrame = playGui:WaitForChild("BG")
local camera = workspace.CurrentCamera

local ReplicateClient = require(script.Parent.ReplicateClient)

-- LOAD PLAYSCREEN MODULE
local PlayScreen = require(script.Parent.PlayScreen)

local playerState = {
	isFirstCameraSetup = true,
	currentGuiType = "Main",
	activeGui = nil,
	isInMenu = true
}

mainGui.Enabled = true
shopGui.Enabled = false
settingsGui.Enabled = false
playGui.Enabled = false

local function sortUIElementsByPosition(elements)
	table.sort(elements, function(a, b)
		return a.AbsolutePosition.Y < b.AbsolutePosition.Y
	end)
	return elements
end

local function initializeUITransparency(frame)
	frame.BackgroundTransparency = 1
	for _, child in ipairs(frame:GetDescendants()) do
		if child:IsA("GuiObject") then
			child.BackgroundTransparency = child:IsA("Frame") and 1 or 1
			if child:IsA("TextLabel") or child:IsA("TextButton") then
				child.TextTransparency = 1
				child.BackgroundTransparency = 1
			end
			if child:IsA("ImageLabel") or child:IsA("ImageButton") then
				child.ImageTransparency = 1
			end

			local stroke = child:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Transparency = 1
			end
		end
	end
end

initializeUITransparency(mainUIFrame)
initializeUITransparency(shopUIFrame)
initializeUITransparency(settingsUIFrame)
initializeUITransparency(playUIFrame)

----------------------------------------------------------------------------------------------------------------
local function fadeInUIElements(frame)
	local uiElements = {}
	for _, child in ipairs(frame:GetDescendants()) do
		if child:IsA("GuiObject") then
			table.insert(uiElements, child)
		end
	end
	local sortedElements = sortUIElementsByPosition(uiElements)
	for i, element in ipairs(sortedElements) do
		local delay = 0
		task.delay(delay, function()
			local tweenInfo = TweenInfo.new(UI_FADE_DURATION, UI_FADE_STYLE)
			local properties = {
				BackgroundTransparency = element:IsA("Frame") and 0 or 1
			}
			if element:IsA("TextLabel") then
				properties.TextTransparency = 0
				properties.BackgroundTransparency = 1
			end
			if element:IsA("TextButton") then
				properties.TextTransparency = 0
				properties.BackgroundTransparency = 0
			end
			if element:IsA("ImageLabel") or element:IsA("ImageButton") then
				properties.ImageTransparency = 0
			end
			local stroke = element:FindFirstChildOfClass("UIStroke")
			if stroke then
				TweenService:Create(stroke, tweenInfo, {Transparency = 0}):Play()
			end
			TweenService:Create(element, tweenInfo, properties):Play()
		end)
	end
end

local function fadeOutUIElements(frame, callback)
	local uiElements = {}
	for _, child in ipairs(frame:GetDescendants()) do
		if child:IsA("GuiObject") then
			table.insert(uiElements, child)
		end
	end
	local tweenInfo = TweenInfo.new(UI_FADE_DURATION / 2, UI_FADE_STYLE)
	local completedTweens = 0
	local totalTweens = #uiElements
	for _, element in ipairs(uiElements) do
		local properties = {
			BackgroundTransparency = 1
		}

		if element:IsA("TextLabel") or element:IsA("TextButton") then
			properties.TextTransparency = 1
		end

		if element:IsA("ImageLabel") or element:IsA("ImageButton") then
			properties.ImageTransparency = 1
		end

		local stroke = element:FindFirstChildOfClass("UIStroke")
		if stroke then
			TweenService:Create(stroke, tweenInfo, {Transparency = 1}):Play()
		end

		local tween = TweenService:Create(element, tweenInfo, properties)
		tween:Play()

		tween.Completed:Connect(function()
			completedTweens = completedTweens + 1
			if completedTweens >= totalTweens and callback then
				callback()
			end
		end)
	end
	if totalTweens == 0 and callback then
		callback()
	end
end


-----------------------------------------------------------------------------------------------------------------

local function moveCamera(cameraType, callback)
	local targetCFrame = workspace:WaitForChild(cameraType.."Camera").CFrame
	local duration = playerState.isFirstCameraSetup and FIRST_CAMERA_MOVE_DURATION or SUBSEQUENT_CAMERA_MOVE_DURATION

	if playerState.isFirstCameraSetup then
		playerState.isFirstCameraSetup = false
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = targetCFrame * CFrame.new(0, 0, -CAMERA_START_DISTANCE)
	end

	local tween = TweenService:Create(camera, TweenInfo.new(
		duration, 
		CAMERA_EASE_STYLE, 
		CAMERA_EASE_DIRECTION
		), {CFrame = targetCFrame})

	tween:Play()
	if callback then tween.Completed:Connect(callback) end
end

local function transitionToGui(guiType)
	if guiType == playerState.currentGuiType then return end

	local guiMap = {
		Main = mainGui,
		Shop = shopGui,
		Settings = settingsGui,
		Play = playGui
	}

	local oldGui = guiMap[playerState.currentGuiType]
	local newGui = guiMap[guiType]

	fadeOutUIElements(oldGui.BG, function()
		if guiType ~= "Play" then
			moveCamera(guiType, function()
				oldGui.Enabled = false
				newGui.Enabled = true
				fadeInUIElements(newGui.BG)
			end)
		else
			oldGui.Enabled = false
			newGui.Enabled = true
			fadeInUIElements(newGui.BG)
		end
		playerState.currentGuiType = guiType
	end)
end

local function setupMenuState()
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			if otherPlayer.Character then
				for _, part in ipairs(otherPlayer.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						part:SetAttribute("OriginalTransparency", part.Transparency)
						part:SetAttribute("OriginalCanCollide", part.CanCollide)

						part.Transparency = 1
						part.CanCollide = false
					elseif part:IsA("BillboardGui") then
						part:SetAttribute("OriginalEnabled", part.Enabled)
						part.Enabled = false
					end
				end
			end
		end
	end

	Players.PlayerAdded:Connect(function(newPlayer)
		if newPlayer ~= player then
			newPlayer.CharacterAdded:Connect(function(character)
				for _, part in ipairs(character:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 1
						part.CanCollide = false
					elseif part:IsA("BillboardGui") then
						part.Enabled = false
					end
				end
			end)
		end
	end)

	if player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		local rootPart = player.Character:FindFirstChild("HumanoidRootPart")

		if humanoid and rootPart then
			humanoid.AutoRotate = false

			rootPart.Anchored = true

			humanoid:ChangeState(Enum.HumanoidStateType.PlatformStanding)
		end
	end

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		local rootPart = character:WaitForChild("HumanoidRootPart")

		humanoid.AutoRotate = false
		rootPart.Anchored = true
		humanoid:ChangeState(Enum.HumanoidStateType.PlatformStanding)
	end)

	playerState.isInMenu = true
end

local TRANSITION_TIME = 0.5
local EASE_STYLE = Enum.EasingStyle.Quint

local guiProperties = {
	ShopGui = {
		Position = shopUIFrame.Position,
		Transparency = 0
	},
	SettingsGui = {
		Position = settingsUIFrame.Position,
		Transparency = 0
	},
	PlayGui = {
		Position = playUIFrame.Position,
		Transparency = 0
	}
}

local shopButton = mainGui.BG.MainUI.ShopFrame.ShopButton
local settingsButton = mainGui.BG.MainUI.SettingsFrame.SettingsButton
local playButton = mainGui.BG.MainUI.PlayFrame.PlayButton

settingsButton.Activated:Connect(function()
	transitionToGui("Settings")
end)

shopButton.Activated:Connect(function()
	transitionToGui("Shop")
end)

playButton.Activated:Connect(function()
	transitionToGui("Play")
end)

local xButton = player.PlayerGui.PlayGui.BG.MainMenuButton
local xButton1 = player.PlayerGui.SettingsGui.BG.MainUI.XbuttonF.Xbutton
local xButton2 = player.PlayerGui.ShopGui.BG.MainUI.MainMenuButton

xButton.Activated:Connect(function()
	transitionToGui("Main")
end)

xButton1.Activated:Connect(function()
	transitionToGui("Main")
end)

xButton2.Activated:Connect(function()
	transitionToGui("Main")
end)

setupMenuState()

moveCamera("Main", function()
	fadeInUIElements(mainUIFrame)
end)

local LobbyMusic = game.SoundService.StartScreen
LobbyMusic:Play()