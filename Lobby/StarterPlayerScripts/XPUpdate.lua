local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LevelConfig = require(game.ReplicatedStorage:WaitForChild("LevelConfig"))
local TweenService = game:GetService("TweenService")

-- Player references
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ReplicateClient = require(script.Parent.ReplicateClient)

-- Tracks xp from client side
local xp = 0

-- XP Bar updates
local StaminaAndHealthBar = playerGui:WaitForChild("StaminaAndHealthBar")
local LevelBar = StaminaAndHealthBar:WaitForChild("LevelBar")
local Bar = LevelBar:WaitForChild("Bar")
local MiddleLabel = LevelBar:WaitForChild("MiddleLabel")
local LeftLabel = LevelBar:WaitForChild("LeftLabel")
local RightLabel = LevelBar:WaitForChild("RightLabel")

local TWEEN_TIME = 0.5
local TWEEN_INFO = TweenInfo.new(TWEEN_TIME,Enum.EasingStyle.Quad,Enum.EasingDirection.Out)
local function updateXpBar()
	local level, leftOverXP = LevelConfig.GetLevelFromXP(xp)
	LeftLabel.Text   = "Lv. ".. level
	RightLabel.Text  = "Lv. ".. (level + 1)
	MiddleLabel.Text = leftOverXP .."/1000"
	local targetScale = leftOverXP / 1000
	local targetSize = UDim2.new(targetScale, 0, 1, 0)
	local tween = TweenService:Create(Bar, TWEEN_INFO, { Size = targetSize })
	tween:Play()
end

-- XP update event listener
local XPUpdate = ReplicatedStorage:WaitForChild("BindableEvents"):WaitForChild("Client"):WaitForChild("XPUpdate")
XPUpdate.Event:Connect(function()
	xp = ReplicateClient.GetXp()
	updateXpBar()
end)

