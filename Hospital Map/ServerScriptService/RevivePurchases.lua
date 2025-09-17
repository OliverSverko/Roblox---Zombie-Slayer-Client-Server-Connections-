-- Server Script (ServerScriptService)
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerTracker = require(game.ServerScriptService.RoundSystem.PlayerTracker)

local processReceiptFunction = ReplicatedStorage:WaitForChild("ProcessReceipt") -- RemoteFunction

local reviveAllIDs = {
	3274682730, 3274682875, 3274683015, 3274683145,
	3274683340, 3274683474, 3274683577, 3274683674
}

local pendingPurchases = {}

local reviveAllCount = 1

-- Attempt to Revive Button Events
local AttemptSelfRevive = ReplicatedStorage:WaitForChild("AttemptSelfRevive")
local AttemptReviveAll = ReplicatedStorage:WaitForChild("AttemptReviveAll")

local PlayerData = require(game.ReplicatedStorage.PlayerData)

AttemptSelfRevive.OnServerEvent:Connect(function(player)
	local data = PlayerData.GetData(player)
	local selfRevives = data.selfRevives
	if selfRevives > 0 then
		data.selfRevives = data.selfRevives - 1
		PlayerTracker.Revive(player)
	else
		-- Prompt Player to buy self revive!
	end
end)

AttemptReviveAll.OnServerEvent:Connect(function(player)
	local data = PlayerData.GetData(player)
	local reviveAlls = data.reviveAlls
	if reviveAlls > 0 then
		data.reviveAlls = data.reviveAlls - 1
		PlayerTracker.ReviveAllPlayers()
	else
		-- Prompt Player to buy revive all!
	end
end)

-- When the client asks for the next product ID
processReceiptFunction.OnServerInvoke = function(player)
	if reviveAllCount > #reviveAllIDs then
		return false, "Maximum revives reached"
	end
	local productId = reviveAllIDs[reviveAllCount]
	pendingPurchases[player.UserId] = productId
	
	reviveAllCount = reviveAllCount + 1
	return true, productId
end

-- Process the purchase receipt
local function processReceipt(receiptInfo)
	local player = game:GetService("Players"):GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local expectedProduct = pendingPurchases[player.UserId]
	if not expectedProduct then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if receiptInfo.ProductId ~= expectedProduct then
		pendingPurchases[player.UserId] = nil
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local success, err = pcall(function()
	end)

	if success then
		PlayerTracker.ReviveAllPlayers()
		pendingPurchases[player.UserId] = nil
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		warn("Failed to update revive count:", err)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

MarketplaceService.ProcessReceipt = processReceipt
