local Players        = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local PLAYER_GROUP  = "Players"

local function setModelToGroup(model, groupName)
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.CollisionGroup = groupName
		end
	end
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		setModelToGroup(char, PLAYER_GROUP)
	end)
end)
