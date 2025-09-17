-- Services
local Players = game:GetService("Players")

local STARTING_COINS = 2000

-- Data Table for Coin Data
local CoinData = {}

-- Coin Update Event (RemoteEvent)
local CoinUpdate = game.ReplicatedStorage:WaitForChild("CoinUpdate")

-- Initialize coin data when players join
Players.PlayerAdded:Connect(function(player)
	CoinData[player.UserId] = STARTING_COINS
	print(player.Name .. " Coins Intiallized")
	CoinUpdate:FireClient(player, STARTING_COINS)
end)

-- Cleanup on leave (good practice)
Players.PlayerRemoving:Connect(function(player)
	CoinData[player.UserId] = nil
end)

-- Module Class
local CoinService = {}

-- Change functions to use dot syntax
function CoinService.GetCoins(player)
	return CoinData[player.UserId] or 0
end

function CoinService.IncrementCoins(player, amount)
	CoinData[player.UserId] = (CoinData[player.UserId] or 0) + amount
	CoinUpdate:FireClient(player, CoinData[player.UserId])
end

function CoinService.DecrementCoins(player, amount)
	CoinData[player.UserId] = math.max(0, (CoinData[player.UserId] or 0) - amount)
	CoinUpdate:FireClient(player, CoinData[player.UserId])
end

return CoinService
