-- LocalScript ? StarterPlayerScripts

local Players               = game:GetService("Players")
local ReplicatedStorage     = game:GetService("ReplicatedStorage")
local ContextActionService  = game:GetService("ContextActionService")
local UserInputService      = game:GetService("UserInputService")
local TweenService          = game:GetService("TweenService")

local player                = Players.LocalPlayer
local rsEvents              = ReplicatedStorage:WaitForChild("PlayerStatsEvents")
local deathEvent            = ReplicatedStorage:WaitForChild("DeathEvent")

-- UI Setup
local PlayerGui             = player:WaitForChild("PlayerGui")
local StaminaAndHealthBar   = PlayerGui:WaitForChild("StaminaAndHealthBar")
local Frame                 = StaminaAndHealthBar:WaitForChild("Frame")
local HealthBar             = Frame.HealthBar
local StaminaBar            = Frame.StaminaBar
local hurtGui               = PlayerGui:WaitForChild("HurtEffect")
local hurtFrame             = hurtGui:WaitForChild("HurtFrame")
local ScreenGui             = PlayerGui:WaitForChild("ScreenGui")
local DeathGui              = PlayerGui:WaitForChild("DeathGui")

-- Remote Events
local HealthUpdateEvent     = rsEvents:WaitForChild("HealthUpdate")
local MaxHealthUpdateEvent  = rsEvents:WaitForChild("MaxHealthUpdate")
local StaminaUpdateEvent    = rsEvents:WaitForChild("StaminaUpdate")
local SpeedUpdateEvent      = rsEvents:WaitForChild("SpeedUpdate")
local playerHurtEvent       = ReplicatedStorage:WaitForChild("PlayerHurt")
local reviveEvent           = ReplicatedStorage:WaitForChild("ReviveEvent")

-- Stamina/Sprint vars
local baseWalkSpeed         = 16
local baseSprintBonus       = 12
local walkSpeed             = baseWalkSpeed
local sprintBonus           = baseSprintBonus
local currentStamina        = 100
local maxStamina            = 100
local currentHealth         = 100
local maxHealth             = 100
local Running               = false

-- Death-freeze vars
local controlsDisabled      = false
local defaultWalkSpeed      = nil
local defaultJumpPower      = nil

-- Helper: show hurt flash
local function showHurtEffect()
	local fadeIn  = TweenService:Create(hurtFrame, TweenInfo.new(0.1), {BackgroundTransparency = 0.6})
	local fadeOut = TweenService:Create(hurtFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1})
	fadeIn:Play()
	fadeIn.Completed:Connect(function() fadeOut:Play() end)
end

-- Update UI & local vars from server
HealthUpdateEvent.OnClientEvent:Connect(function(newHealth)
	currentHealth = newHealth
	HealthBar.Bar:TweenSize(UDim2.new(currentHealth/maxHealth,0,1,0),"Out","Linear",0.2)
	HealthBar.TextLabel.Text = math.floor(currentHealth) .. "/" .. maxHealth
end)
MaxHealthUpdateEvent.OnClientEvent:Connect(function(newMax)
	maxHealth = newMax
	currentHealth = newMax
	HealthBar.Bar:TweenSize(UDim2.new(currentHealth/maxHealth,0,1,0),"Out","Linear",0.2)
	HealthBar.TextLabel.Text = math.floor(currentHealth) .. "/" .. maxHealth
end)
StaminaUpdateEvent.OnClientEvent:Connect(function(serverStam)
	maxStamina     = serverStam
	currentStamina = math.min(currentStamina, maxStamina)
	StaminaBar.Bar:TweenSize(UDim2.new(currentStamina/maxStamina,0,1,0),"Out","Linear",0.2)
end)
SpeedUpdateEvent.OnClientEvent:Connect(function(newMult)
	walkSpeed   = baseWalkSpeed * newMult
	sprintBonus = baseSprintBonus * newMult
end)
playerHurtEvent.OnClientEvent:Connect(showHurtEffect)

-- Sprint input handling
UserInputService.InputBegan:Connect(function(inp, processed)
	if processed then return end
	if inp.KeyCode==Enum.KeyCode.LeftShift and not Running then
		Running = true
		if not controlsDisabled then
			Humanoid.WalkSpeed = walkSpeed + sprintBonus
		end
		task.spawn(function()
			while Running and currentStamina>0 do
				currentStamina = math.max(0, currentStamina-1)
				StaminaBar.Bar:TweenSize(UDim2.new(currentStamina/maxStamina,0,1,0),"Out","Linear",0.05)
				if currentStamina==0 then
					Humanoid.WalkSpeed = walkSpeed
					break
				end
				task.wait(0.05)
			end
		end)
	end
end)
UserInputService.InputEnded:Connect(function(inp)
	if inp.KeyCode==Enum.KeyCode.LeftShift then
		Running = false
		Humanoid.WalkSpeed = walkSpeed
		task.spawn(function()
			while not Running and currentStamina<maxStamina do
				currentStamina = math.min(maxStamina, currentStamina+2)
				StaminaBar.Bar:TweenSize(UDim2.new(currentStamina/maxStamina,0,1,0),"Out","Linear",0.05)
				task.wait(0.2)
			end
		end)
	end
end)

-- On each spawn: cache speeds, hook death event
local function onCharacterAdded(char)
	-- re-init humanoid & UI
	Character = char
	Humanoid  = char:WaitForChild("Humanoid")
	Humanoid.WalkSpeed = walkSpeed

	-- capture “normal” speeds for restore later
	defaultWalkSpeed = Humanoid.WalkSpeed
	defaultJumpPower = Humanoid.JumpPower
	
end

-- hook
Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end
