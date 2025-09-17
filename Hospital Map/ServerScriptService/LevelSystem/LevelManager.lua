local LevelConfig = require(script.Parent.LevelConfig)
local feedbackEvent = game.ReplicatedStorage:WaitForChild("LevelFeedback")
local LevelManager = {}

function LevelManager.AddXP(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local xp = leaderstats:FindFirstChild("XP")
	local level = leaderstats:FindFirstChild("Level")

	if xp and level then
		xp.Value += amount

		while xp.Value >= LevelConfig.GetRequiredXP(level.Value) do
			xp.Value -= LevelConfig.GetRequiredXP(level.Value)
			level.Value += 1

			print(player.Name .. " leveled up to " .. level.Value .. "!")
			local levelVal = level.value
			feedbackEvent:FireClient(player, levelVal)
		end
	end
end

return LevelManager