local PlayerVisibilityHandler = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToggleLobbyEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ToggleLobbyEvent")

local function togglePlayerVisibility(player, makeVisible)
	if player.Character then
		for _, part in ipairs(player.Character:GetDescendants()) do
			if part:IsA("BasePart") then
				if makeVisible then
					part.Transparency = part:GetAttribute("OriginalTransparency") or 0
					part.CanCollide = part:GetAttribute("OriginalCanCollide") or true
				else
					part:SetAttribute("OriginalTransparency", part.Transparency)
					part:SetAttribute("OriginalCanCollide", part.CanCollide)
					part.Transparency = 1
					part.CanCollide = false
				end
			end
		end
	end
end

ToggleLobbyEvent.OnServerEvent:Connect(function(player, lobbyState)
	-- Handle visibility for all other players
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= player then
			togglePlayerVisibility(otherPlayer, not lobbyState)
		end
	end
end)

return PlayerVisibilityHandler
