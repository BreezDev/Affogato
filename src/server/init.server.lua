--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Affogato")
local RemoteNames = require(shared.Remotes)
local Recipes = require(shared.Recipes)
local ProfileService = require(script.ProfileService)
local WorldService = require(script.WorldService)
local DayService = require(script.DayService)
local OrderService = require(script.OrderService)
local PreparationService = require(script.PreparationService)

local remoteFolder = Instance.new("Folder")
remoteFolder.Name = RemoteNames.Folder
remoteFolder.Parent = ReplicatedStorage

local stateRemote = Instance.new("RemoteEvent")
stateRemote.Name = RemoteNames.State
stateRemote.Parent = remoteFolder
local actionRemote = Instance.new("RemoteFunction")
actionRemote.Name = RemoteNames.Action
actionRemote.Parent = remoteFolder
local preparationRemote = Instance.new("RemoteFunction")
preparationRemote.Name = RemoteNames.Preparation
preparationRemote.Parent = remoteFolder
local notifyRemote = Instance.new("RemoteEvent")
notifyRemote.Name = RemoteNames.Notify
notifyRemote.Parent = remoteFolder

WorldService.Build()
ProfileService.Start()
DayService.Start()
OrderService.Start(WorldService, DayService)

local function serializeState(player: Player)
	local profile = ProfileService.Get(player)
	if not profile then return nil end
	local orders = {}
	for _, order in OrderService.GetQueue() do
		local names = {}
		for _, id in order.items do table.insert(names, Recipes.ById[id].displayName) end
		table.insert(orders, { id = order.id, items = names, happiness = order.happiness })
	end
	local held = {}
	for _, item in PreparationService.GetPrepared(player) do
		table.insert(held, { name = Recipes.ById[item.recipeId].displayName, quality = item.quality })
	end
	return {
		cash = profile.cash,
		xp = profile.xp,
		level = profile.level,
		day = DayService.Day,
		period = DayService.GetPeriod().name,
		timeLeft = DayService.TimeLeft,
		orders = orders,
		held = held,
	}
end

local function pushState(player: Player)
	local state = serializeState(player)
	if state then stateRemote:FireClient(player, state) end
end

local function pushAll()
	for _, player in Players:GetPlayers() do pushState(player) end
end

Players.PlayerAdded:Connect(function(player)
	ProfileService.Load(player)
	pushState(player)
end)
Players.PlayerRemoving:Connect(PreparationService.Cleanup)
for _, player in Players:GetPlayers() do ProfileService.Load(player) pushState(player) end

DayService.Changed.Event:Connect(pushAll)
OrderService.Changed.Event:Connect(pushAll)

actionRemote.OnServerInvoke = function(player: Player, action: string)
	if action == "GetState" then return true, serializeState(player) end
	if action == "Serve" then
		local success, message, cash, xp = OrderService.TryComplete(PreparationService.GetPrepared(player))
		if success then ProfileService.Award(player, cash, xp) end
		notifyRemote:FireClient(player, message, success)
		pushAll()
		return success, message
	end
	return false, "Unknown action."
end

preparationRemote.OnServerInvoke = function(player: Player, action: string, payload: any)
	if action == "Start" and type(payload) == "table" then
		return PreparationService.StartRecipe(player, tostring(payload.recipeId), tostring(payload.station))
	elseif action == "Step" then
		local success, result = PreparationService.CompleteStep(player, tonumber(payload) or 0)
		if success and type(result) == "table" and result.completed then
			notifyRemote:FireClient(player, `{result.displayName} ready!`, true)
			pushState(player)
		end
		return success, result
	elseif action == "Cancel" then
		PreparationService.Cancel(player)
		return true
	end
	return false, "Unknown preparation action."
end
