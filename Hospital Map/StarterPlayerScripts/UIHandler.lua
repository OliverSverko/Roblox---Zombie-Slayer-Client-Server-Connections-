local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local LevelConfig = require(game.ReplicatedStorage:WaitForChild("LevelConfig"))
local TweenService = game:GetService("TweenService")

-- Remote Events
local ShowXPFeedback = ReplicatedStorage:WaitForChild("ShowXPFeedback")
local LevelFeedback = ReplicatedStorage:WaitForChild("LevelFeedback")
local showCoinFeedback = ReplicatedStorage:WaitForChild("showCoinFeedback")
local CoinUpdate = ReplicatedStorage:WaitForChild("CoinUpdate")
local XPUpdate = game.ReplicatedStorage:WaitForChild("XPUpdate")

-- Sounds
local XPsound = SoundService:WaitForChild("XP")
local coinSound = SoundService:WaitForChild("CoinSound")

-- Player references
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Tracks xp from client side
local xp = 0

-- XP Bar updates
local StaminaAndHealthBar = playerGui:WaitForChild("StaminaAndHealthBar")
local Frame = StaminaAndHealthBar:WaitForChild("Frame")
local LevelBar = Frame:WaitForChild("LevelBar")
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
XPUpdate.OnClientEvent:Connect(function(newXP)
	xp = newXP
	updateXpBar()
end)

-- Xp Popup
local function showXPFeedback(amount)
	local gui = playerGui
	local screenGui = gui:WaitForChild("ScreenGui")
	local CurrencySide = gui:WaitForChild("StaminaAndHealthBar"):WaitForChild("Frame"):WaitForChild("LevelBar")
	local NewPopup = screenGui.Popup:Clone()
	NewPopup.XPAmount.Visible = true
	NewPopup.XPAmount.Transparency = 0
	NewPopup.XPAmount.BackgroundTransparency = 1
	NewPopup.Size = UDim2.new(0, 0, 0, 0)
	NewPopup.XPAmount.Text = "+" .. amount .. "XP"
	NewPopup.Position = UDim2.new(math.random(30, 70)/100, 0, math.random(30, 70)/100, 0)
	NewPopup.Parent = screenGui.Popups
	NewPopup:TweenSize(UDim2.new(0.176, 0, 0.105, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5)
	XPsound:Play()
	task.wait(1)
	local absoluteSize = screenGui.AbsoluteSize
	local absolutePos = CurrencySide.AbsolutePosition
	local relativePos = UDim2.new(absolutePos.X / absoluteSize.X, 0,absolutePos.Y / absoluteSize.Y, 0)
	NewPopup:TweenPosition(relativePos, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 2)
	NewPopup:TweenSize(UDim2.new(0.1, 0, 0.05, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 2)
	task.wait(1.4)
	NewPopup:Destroy()
end

-- Level Up Popup
local function showLevelFeedback(levelVal)
	local player = game.Players.LocalPlayer
	local gui = player:WaitForChild("PlayerGui")
	local levelText = Instance.new("TextLabel")
	levelText.Name = "LevelUpText"
	levelText.AnchorPoint = Vector2.new(0.5, 0.5)
	levelText.Visible = true
	levelText.ZIndex = 10
	levelText.Text = "Level Up! Level: " .. levelVal .. "!"
	levelText.Size = UDim2.new(0.15, 0, 0.08, 0)
	levelText.Position = UDim2.new(0.5, 0, 0.85, 0)
	levelText.BackgroundTransparency = 1
	levelText.TextColor3 = Color3.new(0, 1, 0)
	levelText.TextScaled = true
	levelText.Font = Enum.Font.GothamBold
	levelText.Parent = gui.ScreenGui
	local tweenService = game:GetService("TweenService")
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local goal = {Position = levelText.Position - UDim2.new(0, 0, 0.1, 0), TextTransparency = 0}
	XPsound:Play()
	tweenService:Create(levelText, tweenInfo, goal):Play()
	task.delay(3.5, function() levelText:Destroy() end)
end

-- Coin Popup 
local function showCoinFeedback1(text)
	local gui = player.PlayerGui:WaitForChild("StaminaAndHealthBar")
	local gui2 = player.PlayerGui:WaitForChild("ScreenGui")
	local CurrencySide = gui:WaitForChild("Frame"):WaitForChild("MoneyFrame"):WaitForChild("Money")
	local NewPopup = gui2:WaitForChild("Popup"):Clone()
	NewPopup.Currency.Visible = true
	NewPopup.Amount.Visible = true
	NewPopup.Currency.Transparency = 0
	NewPopup.Currency.BackgroundTransparency = 1
	NewPopup.Amount.Transparency = 0
	NewPopup.Amount.BackgroundTransparency = 1
	NewPopup.Size = UDim2.new(0, 0, 0, 0)
	NewPopup.Currency.Image = CurrencySide.MoneyImage.Image
	NewPopup.Amount.Text = "+" .. text
	NewPopup.Position = UDim2.new(math.random(30, 70)/100, 0, math.random(30, 70)/100, 0)
	NewPopup.Parent = player.PlayerGui.ScreenGui.Popups
	NewPopup:TweenSize(UDim2.new(0.13, 0, 0.14, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5)
	coinSound:Play()
	task.wait(1)
	local screenGui = CurrencySide:FindFirstAncestorOfClass("ScreenGui")
	local absoluteSize = screenGui.AbsoluteSize
	local absolutePos = CurrencySide.AbsolutePosition
	local relativePos = UDim2.new(absolutePos.X / absoluteSize.X, 0,absolutePos.Y / absoluteSize.Y, 0)
	NewPopup:TweenPosition(relativePos, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 2)
	NewPopup:TweenSize(UDim2.new(0.05, 0, 0.0525, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 2)
	task.wait(1.4)
	NewPopup:Destroy()
end

-- Update coin display
local function showCoinFeedback2(text)
	local gui = player.PlayerGui
	local CoinsAmount = gui:WaitForChild("StaminaAndHealthBar"):WaitForChild("Frame"):WaitForChild("MoneyFrame"):WaitForChild("Money"):WaitForChild("Money")
	CoinsAmount.Text = tostring(text)
end

-- Connect events
ShowXPFeedback.OnClientEvent:Connect(showXPFeedback)
LevelFeedback.OnClientEvent:Connect(showLevelFeedback)
showCoinFeedback.OnClientEvent:Connect(showCoinFeedback1)
CoinUpdate.OnClientEvent:Connect(showCoinFeedback2)

local yesss = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("ScreenGui"):WaitForChild("Zombers")
local NumberRound = game.ReplicatedStorage:WaitForChild("NumberRound")
local ZombieDied = game.ReplicatedStorage:WaitForChild("ZombieDied")

-- Track state with variables
local currentRound = 0
local zombiesLeft = 0

local function updateDisplay()
	yesss.Text = "Zombies Left: " .. zombiesLeft .. "/" .. (4 + (2 * currentRound))
end

NumberRound.OnClientEvent:Connect(function(roundNumber)
	currentRound = roundNumber - 1
	zombiesLeft = 4 + (2 * currentRound)  -- Reset count for new round
	updateDisplay()
end)

ZombieDied.OnClientEvent:Connect(function()
	if zombiesLeft > 0 then
		zombiesLeft -= 1  -- Correct decrement operator
		updateDisplay()
	end
end)