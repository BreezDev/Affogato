--!strict

local Players = game:GetService("Players")

local Config = require(game.ReplicatedStorage.Affogato.Config)
local Economy = require(game.ReplicatedStorage.Affogato.Economy)
local Recipes = require(game.ReplicatedStorage.Affogato.Recipes)

local EconomyService = {}
EconomyService.Changed = Instance.new("BindableEvent")
local profiles
local worldService
local eventService

local function profileFor(player: Player)
	return profiles.Get(player)
end

function EconomyService.Spend(player: Player, amount: number): boolean
	local profile = profileFor(player)
	if not profile or profile.cash < amount then return false end
	profile.cash -= amount
	return true
end

function EconomyService.OrderSupply(player: Player, supplierId: string, ingredientId: string): (boolean, string)
	local profile = profileFor(player)
	local supplier = Economy.Suppliers[supplierId]
	local product = supplier and supplier.products[ingredientId]
	if not profile or not supplier or not product then return false, "That supplier item does not exist." end
	if profile.level < supplier.unlockLevel then return false, `Reach level {supplier.unlockLevel} to use this supplier.` end
	local cost = math.floor(product.cost * (eventService and eventService.GetModifier("supplierDiscount") or 1) + 0.5)
	if not EconomyService.Spend(player, cost) then return false, "You do not have enough cash." end
	table.insert(profile.pendingDeliveries, {
		ingredientId = ingredientId, amount = product.amount, quality = supplier.quality,
		arrivesAt = os.time() + supplier.deliverySeconds * (eventService and eventService.GetModifier("deliveryMultiplier") or 1), supplier = supplier.name,
	})
	EconomyService.Changed:Fire(player)
	return true, `{Economy.Ingredients[ingredientId].name} ordered from {supplier.name}.`
end

function EconomyService.ProcessDeliveries(player: Player): { string }
	local profile = profileFor(player)
	local messages = {}
	if not profile then return messages end
	for index = #profile.pendingDeliveries, 1, -1 do
		local delivery = profile.pendingDeliveries[index]
		local arrivesAt = tonumber(delivery.arrivesAt)
		if arrivesAt and arrivesAt <= os.time() and Economy.Ingredients[delivery.ingredientId] then
			local id = delivery.ingredientId
			local oldAmount = profile.inventory[id]
			local newAmount = oldAmount + delivery.amount
			profile.ingredientQuality[id] = ((profile.ingredientQuality[id] * oldAmount) + (delivery.quality * delivery.amount)) / math.max(newAmount, 1)
			profile.inventory[id] = newAmount
			table.remove(profile.pendingDeliveries, index)
			table.insert(messages, `{Economy.Ingredients[id].name} delivery arrived (+{delivery.amount}).`)
			if worldService then worldService.ShowDelivery(player, Economy.Ingredients[id].name) end
		end
	end
	if #messages > 0 then EconomyService.Changed:Fire(player) end
	return messages
end

function EconomyService.ConsumeRecipe(player: Player, recipeId: string): (boolean, string, number)
	local profile = profileFor(player)
	local recipe = Recipes.ById[recipeId]
	if not profile or not recipe then return false, "Unknown recipe.", 0 end
	for id, amount in recipe.ingredients do
		if (profile.inventory[id] or 0) < amount then return false, `Out of {Economy.Ingredients[id].name}.`, 0 end
	end
	local totalQuality, units = 0, 0
	for id, amount in recipe.ingredients do
		profile.inventory[id] -= amount
		totalQuality += profile.ingredientQuality[id] * amount
		units += amount
	end
	EconomyService.Changed:Fire(player)
	return true, "Ingredients reserved.", totalQuality / math.max(units, 1)
end

function EconomyService.RefundRecipe(player: Player, recipeId: string)
	local profile = profileFor(player)
	local recipe = Recipes.ById[recipeId]
	if not profile or not recipe then return end
	for id, amount in recipe.ingredients do profile.inventory[id] += amount end
	EconomyService.Changed:Fire(player)
end

function EconomyService.UpgradeEquipment(player: Player, equipmentId: string): (boolean, string)
	local profile = profileFor(player)
	local equipment = Economy.Equipment[equipmentId]
	if not profile or not equipment then return false, "Unknown equipment." end
	local current = profile.equipment[equipmentId] or 1
	local nextTier = equipment.tiers[current + 1]
	if not nextTier then return false, "That equipment is already maxed." end
	if not EconomyService.Spend(player, nextTier.cost) then return false, "You do not have enough cash." end
	profile.equipment[equipmentId] = current + 1
	EconomyService.Changed:Fire(player)
	return true, `{equipment.name} upgraded to {nextTier.name}!`
end

function EconomyService.UpgradePlayer(player: Player, upgradeId: string): (boolean, string)
	local profile = profileFor(player)
	local upgrade = Economy.PlayerUpgrades[upgradeId]
	if not profile or not upgrade then return false, "Unknown player upgrade." end
	local level = profile.playerUpgrades[upgradeId] or 0
	if level >= upgrade.maxLevel then return false, "That skill is already maxed." end
	local cost = upgrade.costs[level + 1]
	if not EconomyService.Spend(player, cost) then return false, "You do not have enough cash." end
	profile.playerUpgrades[upgradeId] = level + 1
	EconomyService.ApplyCharacter(player)
	EconomyService.Changed:Fire(player)
	return true, `{upgrade.name} upgraded to level {level + 1}!`
end

function EconomyService.HireStaff(player: Player, staffId: string): (boolean, string)
	local profile = profileFor(player)
	local candidate = Economy.Staff[staffId]
	if not profile or not candidate then return false, "Unknown employee." end
	if profile.staff[staffId] then return false, "That employee already works here." end
	local count = 0
	for _ in profile.staff do count += 1 end
	local slots = Config.BaseStaffSlots + (profile.purchasedGamepasses.ExtraEmployeeSlot and 1 or 0)
	if count >= slots then return false, "All employee slots are full." end
	if not EconomyService.Spend(player, candidate.hireCost) then return false, "You do not have enough cash." end
	profile.staff[staffId] = { training = 0 }
	EconomyService.Changed:Fire(player)
	return true, `{candidate.name} joined as your {candidate.role}!`
end

function EconomyService.TrainStaff(player: Player, staffId: string): (boolean, string)
	local profile = profileFor(player)
	local employee = profile and profile.staff[staffId]
	local candidate = Economy.Staff[staffId]
	if not profile or not employee or not candidate then return false, "Hire that employee first." end
	if employee.training >= Economy.Training.maxLevel then return false, "That employee is fully trained." end
	local cost = Economy.Training.costs[employee.training + 1]
	if not EconomyService.Spend(player, cost) then return false, "You do not have enough cash." end
	employee.training += 1
	EconomyService.Changed:Fire(player)
	return true, `{candidate.name} completed training level {employee.training}!`
end

function EconomyService.PayWages(player: Player): string?
	local profile = profileFor(player)
	if not profile then return nil end
	local wages = 0
	for id in profile.staff do wages += Economy.Staff[id].wage end
	if wages == 0 then return nil end
	local paid = math.min(wages, profile.cash)
	profile.cash -= paid
	EconomyService.Changed:Fire(player)
	return paid == wages and `Staff wages paid: ${wages}.` or `Only ${paid} of ${wages} in staff wages could be paid.`
end

function EconomyService.ApplyCharacter(player: Player)
	local profile = profileFor(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if profile and humanoid then humanoid.WalkSpeed = Config.BaseWalkSpeed * (1 + 0.05 * profile.playerUpgrades.Movement) end
end

function EconomyService.Start(profileService, world, events)
	profiles = profileService
	worldService = world
	eventService = events
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function() task.wait() EconomyService.ApplyCharacter(player) end)
	end)
	task.spawn(function()
		while task.wait(1) do
			for _, player in Players:GetPlayers() do EconomyService.ProcessDeliveries(player) end
		end
	end)
end

return EconomyService
