--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Affogato")
local RemoteNames = require(shared.Remotes)
local Recipes = require(shared.Recipes)
local Economy = require(shared.Economy)
local Meta = require(shared.Meta)
local ProfileService = require(script.ProfileService)
local WorldService = require(script.WorldService)
local DayService = require(script.DayService)
local OrderService = require(script.OrderService)
local PreparationService = require(script.PreparationService)
local EconomyService = require(script.EconomyService)
local StaffService = require(script.StaffService)
local BuildService = require(script.BuildService)
local EventService = require(script.EventService)
local ReputationService = require(script.ReputationService)
local ProgressionService = require(script.ProgressionService)
local MonetizationService = require(script.MonetizationService)
local SignatureService = require(script.SignatureService)

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
EventService.Start()
BuildService.Start(ProfileService, WorldService)
ReputationService.Start(ProfileService, BuildService)
ProgressionService.Start(ProfileService)
MonetizationService.Start(ProfileService, WorldService)
SignatureService.Start(ProfileService, OrderService)
EconomyService.Start(ProfileService, WorldService, EventService)
PreparationService.Start(EconomyService, ProfileService)
DayService.Start()
OrderService.Start(WorldService, DayService, EventService, ProfileService)
StaffService.Start(ProfileService, EconomyService, PreparationService, OrderService)

local function serializeState(player: Player)
	local profile = ProfileService.Get(player)
	if not profile then return nil end
	local orders = {}
	for _, order in OrderService.GetQueue() do
		local names = {}
		for _, id in order.items do
			local info = OrderService.GetItemInfo(id)
			local prep = info and info.signature and Recipes.ById[info.baseId]
			table.insert(names, info and (prep and `{info.displayName} (prepare {prep.displayName})` or info.displayName) or "Unavailable item")
		end
		table.insert(orders, { id = order.id, items = names, happiness = order.happiness, customerType = order.customerType })
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
	local furniture = {}
	for id, item in Meta.Furniture do table.insert(furniture, { id = id, name = item.name, theme = item.theme, cost = item.cost, ambience = item.ambience, owned = profile.furnitureOwned[id] or 0, locked = item.gamepass and not profile.purchasedGamepasses[item.gamepass] }) end
	local placements = {}
	for _, placement in profile.furniturePlacements do
		local item = Meta.Furniture[placement.itemId]
		table.insert(placements, { id = placement.id, itemId = placement.itemId, name = item.name, x = placement.x, z = placement.z, rotation = placement.rotation })
	end
	local challenges = {}
	for _, progress in profile.dailyChallenges do
		for _, challenge in Meta.Challenges do if challenge.id == progress.id then table.insert(challenges, { id = progress.id, description = challenge.description, progress = progress.progress, target = progress.target, claimed = progress.claimed, rewardCash = challenge.rewardCash, rewardXP = challenge.rewardXP }) break end end
	end
	local activeEvent = EventService.Current
	local nextExpansion = Meta.Expansions[profile.expansion + 1]
	local nextUnlock
	for _, unlock in Meta.LevelUnlocks do if unlock.level > profile.level then nextUnlock = unlock break end end
	local achievements = {}
	for id, achievement in Meta.Achievements do
		local progress = achievement.kind == "Orders" and profile.completedOrders or achievement.kind == "Affogatos" and profile.stats.Affogatos or achievement.kind == "Reputation" and profile.reputation or achievement.kind == "Ambience" and BuildService.GetAmbience(player) or achievement.kind == "Expansion" and profile.expansion or 0
		table.insert(achievements, { id = id, name = achievement.name, description = achievement.description, progress = math.min(progress, achievement.target), target = achievement.target, unlocked = profile.achievements[id] == true })
	end
	local signatures = {}
	for _, recipe in profile.signatureDrinks do table.insert(signatures, { id = recipe.id, name = recipe.name, baseId = recipe.baseId, prepId = recipe.prepId, flavor = recipe.flavor, topping = recipe.topping, price = recipe.price, sold = recipe.sold }) end
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
		reputation = profile.reputation, fame = ReputationService.GetFame(profile.reputation), ambience = BuildService.GetAmbience(player),
		furniture = furniture, placements = placements, expansion = Meta.Expansions[profile.expansion].name,
		nextExpansion = nextExpansion and { name = nextExpansion.name, cost = nextExpansion.cost } or nil,
		challenges = challenges, loginStreak = profile.loginStreak, settings = profile.settings, menu = profile.menu,
		event = activeEvent and { name = activeEvent.name, description = activeEvent.description, endsIn = math.max(0, activeEvent.endsAt - os.time()) } or nil,
		gamepasses = profile.purchasedGamepasses,
		nextUnlock = nextUnlock,
		achievements = achievements, loginRewards = Meta.LoginRewards,
		signatures = signatures,
		store = { gamepasses = Meta.Gamepasses, products = Meta.DeveloperProducts },
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
	BuildService.LoadPlayer(player)
	MonetizationService.RefreshPasses(player)
	local dailyMessage = ProgressionService.OnLoad(player)
	if dailyMessage then notifyRemote:FireClient(player, dailyMessage, true) end
	pushState(player)
end)
Players.PlayerRemoving:Connect(function(player)
	PreparationService.Cleanup(player)
	ProfileService.Save(player)
	ProfileService.Release(player)
end)
for _, player in Players:GetPlayers() do ProfileService.Load(player) EconomyService.ApplyCharacter(player) BuildService.LoadPlayer(player) ProgressionService.OnLoad(player) pushState(player) end

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
BuildService.Changed.Event:Connect(function(player)
	local profile = ProfileService.Get(player)
	if profile then
		local unlocked = ProgressionService.CheckAchievements(player, { ambience = BuildService.GetAmbience(player), expansion = profile.expansion })
		for _, text in unlocked do notifyRemote:FireClient(player, `Achievement unlocked — {text}`, true) end
	end
	pushState(player)
end)
ProgressionService.Changed.Event:Connect(function(player) pushState(player) end)
MonetizationService.Changed.Event:Connect(function(player) pushState(player) end)
SignatureService.Changed.Event:Connect(function(player) pushState(player) end)
EventService.Changed.Event:Connect(function(event)
	for _, player in Players:GetPlayers() do notifyRemote:FireClient(player, event and `{event.name}: {event.description}` or "The café event has ended.", true) end
	pushAll()
end)
local function completeOrder(player, message, cash, xp, metrics, staff: boolean?)
	local ambienceMultiplier = 1 + math.min(BuildService.GetAmbience(player), 100) * 0.001
	local finalCash = math.floor(cash * MonetizationService.GetEarningsMultiplier(player) * ambienceMultiplier + 0.5)
	ProfileService.Award(player, finalCash, xp)
	ReputationService.RecordOrder(player, metrics)
	ProgressionService.Record(player, "ServeOrders", 1)
	ProgressionService.Record(player, "EarnCash", finalCash)
	if metrics.quality >= 0.9 and metrics.speed >= 0.75 then ProgressionService.Record(player, "PerfectOrders", 1) end
	if DayService.GetPeriod().name:find("Rush") then ProgressionService.Record(player, "RushOrders", 1) end
	if metrics.customerType == "Influencer" and metrics.quality >= 0.85 then EventService.StartEvent("ViralPost") end
	local profile = ProfileService.Get(player)
	local unlocked = ProgressionService.CheckAchievements(player, { reputation = profile and profile.reputation or 1, ambience = BuildService.GetAmbience(player), expansion = profile and profile.expansion or 1 })
	for _, text in unlocked do notifyRemote:FireClient(player, `Achievement unlocked — {text}`, true) end
	notifyRemote:FireClient(player, staff and `Staff: {message}` or message, true)
	pushAll()
end
StaffService.CompletedOrder.Event:Connect(function(player, message, cash, xp, metrics)
	completeOrder(player, message, cash, xp, metrics, true)
end)

actionRemote.OnServerInvoke = function(player: Player, action: string, payload: any)
	if action == "GetState" then return true, serializeState(player) end
	if action == "Serve" then
		local profile = ProfileService.Get(player)
		local registerTier = profile and profile.equipment.Register or 1
		local registerSpeed = Economy.Equipment.Register.tiers[registerTier].speed
		local success, message, cash, xp, metrics = OrderService.TryComplete(PreparationService.GetPrepared(player), registerSpeed)
		if success then completeOrder(player, message, cash, xp, metrics) else notifyRemote:FireClient(player, message, false) end
		return success, message
	end
	local success, message
	if action == "OrderSupply" and type(payload) == "table" then success, message = EconomyService.OrderSupply(player, tostring(payload.supplierId), tostring(payload.ingredientId))
	elseif action == "UpgradeEquipment" then success, message = EconomyService.UpgradeEquipment(player, tostring(payload))
	elseif action == "UpgradePlayer" then success, message = EconomyService.UpgradePlayer(player, tostring(payload))
	elseif action == "HireStaff" then success, message = EconomyService.HireStaff(player, tostring(payload))
	elseif action == "TrainStaff" then success, message = EconomyService.TrainStaff(player, tostring(payload))
	elseif action == "BuyFurniture" then success, message = BuildService.Buy(player, tostring(payload))
	elseif action == "PlaceFurniture" and type(payload) == "table" then success, message = BuildService.Place(player, tostring(payload.itemId), tonumber(payload.x) or 0, tonumber(payload.z) or 0, tonumber(payload.rotation))
	elseif action == "EditFurniture" and type(payload) == "table" then success, message = BuildService.Edit(player, tostring(payload.edit), tostring(payload.placementId), tonumber(payload.x), tonumber(payload.z))
	elseif action == "ExpandCafe" then success, message = BuildService.Expand(player)
	elseif action == "ClaimChallenge" then success, message = ProgressionService.Claim(player, tostring(payload))
	elseif action == "CreateSignature" then success, message = SignatureService.Create(player, payload)
	elseif action == "DeleteSignature" then success, message = SignatureService.Delete(player, tostring(payload))
	elseif action == "UpdateSetting" and type(payload) == "table" then
		local profile = ProfileService.Get(player)
		if profile and profile.settings[payload.key] ~= nil and type(payload.value) == "boolean" then profile.settings[payload.key] = payload.value success, message = true, "Setting updated." end
	elseif action == "ToggleMenuItem" then
		local profile = ProfileService.Get(player)
		local recipeId = tostring(payload)
		local recipe = Recipes.ById[recipeId]
		local signatureValid = false
		if profile then for _, signature in profile.signatureDrinks do if signature.id == recipeId then signatureValid = true break end end end
		if profile and ((recipe and profile.level >= (recipe.unlockLevel or 1)) or signatureValid) then
			local found
			for index, id in profile.menu do if id == recipeId then found = index break end end
			if found then
				if #profile.menu <= 1 then success, message = false, "Your menu needs at least one item." else table.remove(profile.menu, found) success, message = true, "Item removed from your menu." end
			else table.insert(profile.menu, recipeId) success, message = true, "Item added to your menu." end
		end
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
			if Recipes.ById[result.recipeId].category == "Affogato" then ProgressionService.Record(player, "MakeAffogato", 1) end
			local profile = ProfileService.Get(player)
			local category = Recipes.ById[result.recipeId].category
			if profile and category == "Affogato" then profile.stats.Affogatos += 1 end
			if profile and category == "Bakery" then profile.stats.BakedItems += 1 ProgressionService.Record(player, "BakeItems", 1) end
			if profile then
				local unlocked = ProgressionService.CheckAchievements(player, { reputation = profile.reputation, ambience = BuildService.GetAmbience(player), expansion = profile.expansion })
				for _, text in unlocked do notifyRemote:FireClient(player, `Achievement unlocked — {text}`, true) end
			end
		end
		return success, result
	elseif action == "Cancel" then
		PreparationService.Cancel(player)
		return true
	end
	return false, "Unknown preparation action."
end
