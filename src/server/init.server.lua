--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Affogato")
local RemoteNames = require(shared.Remotes)
local Recipes = require(shared.Recipes)
local Economy = require(shared.Economy)
local ProfileService = require(script.ProfileService)
local WorldService = require(script.WorldService)
local DayService = require(script.DayService)
local OrderService = require(script.OrderService)
local PreparationService = require(script.PreparationService)
local EconomyService = require(script.EconomyService)
local StaffService = require(script.StaffService)

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
EconomyService.Start(ProfileService, WorldService)
PreparationService.Start(EconomyService, ProfileService)
DayService.Start()
OrderService.Start(WorldService, DayService)
StaffService.Start(ProfileService, EconomyService, PreparationService, OrderService)

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
	local inventory = {}
	for id, ingredient in Economy.Ingredients do
		table.insert(inventory, { id = id, name = ingredient.name, amount = profile.inventory[id], quality = profile.ingredientQuality[id] })
	end
	table.sort(inventory, function(a, b) return a.name < b.name end)
	local equipment = {}
	for id, item in Economy.Equipment do
		local tier = profile.equipment[id]
		local nextTier = item.tiers[tier + 1]
		table.insert(equipment, { id = id, name = item.name, tier = item.tiers[tier].name, nextName = nextTier and nextTier.name, cost = nextTier and nextTier.cost })
	end
	local staff = {}
	for id, candidate in Economy.Staff do
		local hired = profile.staff[id]
		table.insert(staff, { id = id, name = candidate.name, role = candidate.role, wage = candidate.wage, hireCost = candidate.hireCost, hired = hired ~= nil, training = hired and hired.training or 0, trainingCost = hired and Economy.Training.costs[hired.training + 1] })
	end
	local upgrades = {}
	for id, upgrade in Economy.PlayerUpgrades do
		local level = profile.playerUpgrades[id]
		table.insert(upgrades, { id = id, name = upgrade.name, level = level, cost = upgrade.costs[level + 1] })
	end
	local deliveries = {}
	for _, delivery in profile.pendingDeliveries do
		table.insert(deliveries, { name = Economy.Ingredients[delivery.ingredientId].name, arrivesIn = math.max(0, delivery.arrivesAt - os.time()) })
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
		inventory = inventory, equipment = equipment, staff = staff, upgrades = upgrades, deliveries = deliveries,
		interactionLevel = profile.playerUpgrades.Interaction,
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
	EconomyService.ApplyCharacter(player)
	pushState(player)
end)
Players.PlayerRemoving:Connect(PreparationService.Cleanup)
for _, player in Players:GetPlayers() do ProfileService.Load(player) EconomyService.ApplyCharacter(player) pushState(player) end

local wagesPaidForDay = DayService.Day
DayService.Changed.Event:Connect(function()
	if DayService.Day ~= wagesPaidForDay then
		wagesPaidForDay = DayService.Day
		for _, player in Players:GetPlayers() do
			local message = EconomyService.PayWages(player)
			if message then notifyRemote:FireClient(player, message, true) end
		end
	end
	pushAll()
end)
OrderService.Changed.Event:Connect(pushAll)
EconomyService.Changed.Event:Connect(function(player) if player then pushState(player) else pushAll() end end)
StaffService.CompletedOrder.Event:Connect(function(player, message, cash, xp)
	ProfileService.Award(player, cash, xp)
	notifyRemote:FireClient(player, `Staff: {message}`, true)
	pushAll()
end)

actionRemote.OnServerInvoke = function(player: Player, action: string, payload: any)
	if action == "GetState" then return true, serializeState(player) end
	if action == "Serve" then
		local profile = ProfileService.Get(player)
		local registerTier = profile and profile.equipment.Register or 1
		local registerSpeed = Economy.Equipment.Register.tiers[registerTier].speed
		local success, message, cash, xp = OrderService.TryComplete(PreparationService.GetPrepared(player), registerSpeed)
		if success then ProfileService.Award(player, cash, xp) end
		notifyRemote:FireClient(player, message, success)
		pushAll()
		return success, message
	end
	local success, message
	if action == "OrderSupply" and type(payload) == "table" then success, message = EconomyService.OrderSupply(player, tostring(payload.supplierId), tostring(payload.ingredientId))
	elseif action == "UpgradeEquipment" then success, message = EconomyService.UpgradeEquipment(player, tostring(payload))
	elseif action == "UpgradePlayer" then success, message = EconomyService.UpgradePlayer(player, tostring(payload))
	elseif action == "HireStaff" then success, message = EconomyService.HireStaff(player, tostring(payload))
	elseif action == "TrainStaff" then success, message = EconomyService.TrainStaff(player, tostring(payload))
	end
	if success ~= nil then
		notifyRemote:FireClient(player, message, success)
		pushState(player)
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
