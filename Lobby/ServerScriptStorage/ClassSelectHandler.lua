local ClassSelectHandler = {}

local ClassData = require(game.ReplicatedStorage.ClassData)
local PlayerData = require(game.ServerScriptService.PlayerData)

local ClassSelectEvent = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ClassSelectEvent")
local ClassAttemptPurchase = game.ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ClassAttemptPurchase")

ClassAttemptPurchase.OnServerEvent:Connect(function(player, className)
	if PlayerData.HasClassUnlocked(player, className) then return end
	if not table.find(ClassData, className) then return end
	
	local class = ClassData[className]
	local price = class.Price
	
	local playerGems = PlayerData.GetGems(player)
	if playerGems >= price then
		PlayerData.UnlockClass(player, className)
		PlayerData.SetClass(player, className)
	end
end)

ClassSelectEvent.OnServerEvent:Connect(function(player, className)
	if not PlayerData.HasClassUnlocked(player, className) then return end
	
	print(player.Name, "selected class:", className)
	PlayerData.SetClass(player, className)
end)

return ClassSelectHandler
