-- StarterGui/ScreenGui/Medals/LocalScript.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local medalRemoteEvent = ReplicatedStorage:WaitForChild("MedalRemoteEvent")
local medalsFolder = playerGui:WaitForChild("ScreenGui"):WaitForChild("Medals")
local ThreeConsKills = game:GetService("SoundService").Medal
-- Preload medal templates
local medalTemplates = {
	ThreeConsKills = medalsFolder:WaitForChild("ThreeConsKills")
}

medalRemoteEvent.OnClientEvent:Connect(function(medalName)
	local template = medalTemplates[medalName]
	if not template then return end

	local medalClone = template:Clone()
	medalClone.Visible = true
	medalClone.BackgroundTransparency = 1
	medalClone.Parent = medalsFolder
	medalClone.ZIndex = 10  -- Ensure it appears on top

	-- Initial hidden state
	medalClone.Position = UDim2.new(0.5, 0, 0.3, 0)
	medalClone.Size = UDim2.new(0, 0, 0, 0)
	medalClone.BackgroundTransparency = 1

	-- Animate entrance
	local entranceTween = game:GetService("TweenService"):Create(
		medalClone,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			Size = UDim2.new(0, 150, 0, 150),
			BackgroundTransparency = 1
		}
	)
	ThreeConsKills:Play()
	entranceTween:Play()

	wait(1.5)  -- Display duration

	-- Animate exit
	local exitTween = game:GetService("TweenService"):Create(
		medalClone,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1
		}
	)

	exitTween.Completed:Connect(function()
		medalClone:Destroy()
	end)
	exitTween:Play()
end)