local player = game.Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PerkUpdateEvent = ReplicatedStorage.PlayerStatsEvents:WaitForChild("PerkUpdate")

local Frame = player.PlayerGui:WaitForChild("ScreenGui"):WaitForChild("Perks")

PerkUpdateEvent.OnClientEvent:Connect(function(perks)
	for _, label in ipairs(Frame:GetChildren()) do
		if label:IsA("ImageLabel") then
			local perkName = label.Name
			local perkFound = false
			for _, perk in ipairs(perks) do
				if perk == perkName then
					perkFound = true
					break
				end
			end
			label.Visible = perkFound
		end
	end
end)


