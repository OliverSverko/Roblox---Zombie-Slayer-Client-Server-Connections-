local PlayerStatsService = require(game.ServerScriptService.PlayerStatsService)
local Players = game:GetService("Players")

while true do 
	task.wait(1)
	-- Process each player individually
	for _, player in ipairs(Players:GetPlayers()) do
		local maxHealth = PlayerStatsService.GetMaxHealth(player)
		local currentHealth = PlayerStatsService.GetHealth(player)

		if currentHealth < maxHealth and PlayerStatsService.IsAlive(player) then
			PlayerStatsService.AdjustHealth(player, 1)
		end
	end
end