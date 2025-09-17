local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local gui = player:WaitForChild("PlayerGui"):WaitForChild("ScreenGui")

local roundText = gui:WaitForChild("RoundText")
local timerText = gui:WaitForChild("TimerText")
roundText.Visible = true
timerText.Visible = false

-- Get the remote events directly from ReplicatedStorage
local RoundStarted = ReplicatedStorage:WaitForChild("RoundStarted")
local RoundEnded = ReplicatedStorage:WaitForChild("RoundEnded")

local timeY = 0

local TweenService = game:GetService("TweenService")
local NumberRound = game.ReplicatedStorage.NumberRound

local roundText = gui:WaitForChild("RoundText") -- adjust if needed

-- Save original position and size
local originalSize = roundText.Size
local originalPosition = roundText.Position

-- Define center position and zoomed-in size
local zoomedSize = UDim2.new(0.5, 0, 0.2, 0) -- larger text size
local centerPosition = UDim2.new(0.5, 0, 0.2, 0) -- center of screen

-- Tween info
local tweenInfo = TweenInfo.new(
	1,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out
)

local tweenInfoIn = TweenInfo.new(
	1,
	Enum.EasingStyle.Cubic,
	Enum.EasingDirection.In
)

-- Tween properties for fading in and out
local fadeOutGoal = { TextTransparency = 1, TextStrokeTransparency = 1 }
local fadeInGoal = { TextTransparency = 0, TextStrokeTransparency = 0 }
local function showRoundFeedBack(text)
	-- Zoom in
	local zoomInTween = TweenService:Create(roundText, tweenInfoIn, {
		Size = zoomedSize,
		Position = centerPosition
	})
	zoomInTween:Play()
	zoomInTween.Completed:Wait()

	-- Change text after zoom

	local fadeInTween = TweenService:Create(roundText, tweenInfo, fadeInGoal)
	fadeInTween:Play()

	-- Change text
	task.wait(1)
	roundText.Text = "Round: " .. text
	task.wait(1)

	local zoomOutTween = TweenService:Create(roundText, tweenInfo, {
		Size = originalSize,
		Position = originalPosition
	})
	zoomOutTween:Play()
end

-- Listen for round number updates
NumberRound.OnClientEvent:Connect(showRoundFeedBack)

