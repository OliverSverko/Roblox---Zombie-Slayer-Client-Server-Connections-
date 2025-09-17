local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Events = ReplicatedStorage:WaitForChild("Events")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local viewmodelEvent = Events.viewmodelEvent
local viewmodelFunction = Events.viewmodelFunction

local LoadViewmodelAppearance = Remotes.LoadViewmodelAppearance

local ViewmodelHandler = require(Modules.ViewmodelHandler)
local Utilities = require(Modules.Utilities)
local Thread = Utilities.Thread

viewmodelEvent.Event:Connect(function(EventName, ...)
	if EventName == "RecoilViewmodel" then
		ViewmodelHandler:RecoilViewmodel(...)
	elseif EventName == "SetAimEnabled" then
		ViewmodelHandler:SetAimEnabled(...)
	elseif EventName == "SetViewmodelTransparent" then
		ViewmodelHandler:SetViewmodelTransparent(...)
	elseif EventName == "CullViewmodel" then
		ViewmodelHandler:CullViewmodel(...)
	end
end)

viewmodelFunction.OnInvoke = function(EventName, ...)
	if EventName == "SetUpViewmodel" then
		return ViewmodelHandler.SetUpViewmodel(...)
	end
end

LoadViewmodelAppearance.OnClientEvent:Connect(function()
	ViewmodelHandler:LoadAppearance()
end)