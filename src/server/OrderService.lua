--!strict

local Config = require(game.ReplicatedStorage.Affogato.Config)
local Recipes = require(game.ReplicatedStorage.Affogato.Recipes)
local Meta = require(game.ReplicatedStorage.Affogato.Meta)

local OrderService = {}
OrderService.Changed = Instance.new("BindableEvent")

export type Order = {
	id: number,
	items: { string },
	createdAt: number,
	patience: number,
	happiness: number,
	tipPotential: number,
	model: Model,
	customerType: string,
	spendingMultiplier: number,
}

local queue: { Order } = {}
local nextId = 1
local worldService
local dayService
local eventService
local profileService

local function serverReputation(): number
	local total, count = 0, 0
	for _, player in game:GetService("Players"):GetPlayers() do
		local profile = profileService and profileService.Get(player)
		if profile then total += profile.reputation count += 1 end
	end
	return count > 0 and total / count or 1
end

local function selectCustomerType()
	if eventService.Current and eventService.Current.id == "SchoolRush" and math.random() < 0.7 then return { id = "Student", data = Meta.CustomerTypes.Student } end
	if eventService.Current and eventService.Current.id == "BirthdayParty" and math.random() < 0.65 then return { id = "ParentChild", data = Meta.CustomerTypes.ParentChild } end
	local reputation = serverReputation()
	local choices = {}
	for id, customer in Meta.CustomerTypes do
		if reputation >= (customer.minReputation or 1) and (not customer.rare or math.random() < 0.08) then table.insert(choices, { id = id, data = customer }) end
	end
	return choices[math.random(1, #choices)]
end

local function selectItem(preferences: { string }, category: string?): string
	local choices = {}
	local enabled = {}
	for _, player in game:GetService("Players"):GetPlayers() do
		local profile = profileService and profileService.Get(player)
		if profile then for _, id in profile.menu do enabled[id] = true end end
	end
	for _, id in preferences do
		local recipe = Recipes.ById[id]
		if recipe and (next(enabled) == nil or enabled[id]) and (not category or recipe.category == category) then table.insert(choices, id) end
	end
	if #choices == 0 then
		for _, recipe in Recipes.List do
			if (next(enabled) == nil or enabled[recipe.id]) and (not category or recipe.category == category) then table.insert(choices, recipe.id) end
		end
	end
	if #choices == 0 then for _, recipe in Recipes.List do if not category or recipe.category == category then table.insert(choices, recipe.id) end end end
	return choices[math.random(1, #choices)]
end

local function refreshPositions()
	for index, order in queue do
		if order.model.PrimaryPart then
			order.model:PivotTo(CFrame.new(0, 3, 4 + index * 4))
		end
	end
end

function OrderService.GetQueue(): { Order }
	return queue
end

function OrderService.Spawn()
	if #queue >= Config.MaximumQueueSize then return end
	local period = dayService.GetPeriod()
	local customer = selectCustomerType()
	local preferences = period.preferences
	if eventService.Current and eventService.Current.id == "HeatWave" then preferences = { "IcedLatte", "ClassicAffogato", "ChocolateAffogato" }
	elseif eventService.Current and eventService.Current.id == "RainyDay" then preferences = { "Espresso", "Latte", "Croissant", "Cookie" } end
	local items = { selectItem(preferences) }
	if customer.id == "ParentChild" or math.random() < 0.38 then
		local first = Recipes.ById[items[1]]
		local secondCategory = first.category == "Bakery" and "Drink" or "Bakery"
		table.insert(items, selectItem(period.preferences, secondCategory))
	end
	local order: Order = {
		id = nextId,
		items = items,
		createdAt = workspace:GetServerTimeNow(),
		patience = Config.CustomerPatienceSeconds * customer.data.patience,
		happiness = 100,
		tipPotential = math.random(15, 30) / 100 * customer.data.tip,
		model = worldService.CreateCustomer(nextId, #queue + 1),
		customerType = customer.data.name,
		spendingMultiplier = customer.data.spending,
	}
	nextId += 1
	table.insert(queue, order)
	OrderService.Changed:Fire()
end

function OrderService.TryComplete(prepared: { any }, serviceSpeedMultiplier: number?): (boolean, string, number, number, any)
	local order = queue[1]
	if not order then return false, "There is no customer waiting.", 0, 0, nil end
	if #prepared < #order.items then return false, "Prepare every item on the ticket first.", 0, 0, nil end
	local used = {}
	local accuracy = 1
	local qualityTotal = 0
	for _, requested in order.items do
		local match
		for index, item in prepared do
			if not used[index] and item.recipeId == requested then match = index break end
		end
		if match then
			used[match] = true
			qualityTotal += prepared[match].quality
		else
			accuracy = 0
		end
	end
	if accuracy == 0 then return false, "That is not the next customer's order.", 0, 0, nil end
	local elapsed = (workspace:GetServerTimeNow() - order.createdAt) / (serviceSpeedMultiplier or 1)
	local speed = math.clamp(1 - elapsed / order.patience, 0, 1)
	local quality = qualityTotal / #order.items
	local subtotal = 0
	for _, id in order.items do subtotal += Recipes.ById[id].price end
	subtotal = math.floor(subtotal * order.spendingMultiplier + 0.5)
	local tip = math.floor(subtotal * order.tipPotential * (0.35 + 0.35 * speed + 0.3 * quality) + 0.5)
	local cash = subtotal + tip
	local xp = 10 * #order.items + (quality >= 0.9 and 5 or 0)
	for index = #prepared, 1, -1 do if used[index] then table.remove(prepared, index) end end
	table.remove(queue, 1)
	order.model:Destroy()
	refreshPositions()
	OrderService.Changed:Fire()
	local score = speed * 0.4 + quality * 0.6
	local reaction = score >= 0.9 and "This is SO good!" or score >= 0.6 and "Thank you!" or "I've been waiting forever!"
	return true, `{order.customerType}: “{reaction}” +${cash} (${tip} tip)`, cash, xp, { accuracy = accuracy, speed = speed, quality = quality, customerType = order.customerType }
end

function OrderService.Start(world, day, events, profiles)
	worldService = world
	dayService = day
	eventService = events
	profileService = profiles
	OrderService.Spawn()
	task.spawn(function()
		while true do
			task.wait(dayService.GetPeriod().spawnInterval * eventService.GetModifier("spawnMultiplier"))
			OrderService.Spawn()
		end
	end)
	task.spawn(function()
		while task.wait(1) do
			local changed = false
			for index = #queue, 1, -1 do
				local order = queue[index]
				local elapsed = workspace:GetServerTimeNow() - order.createdAt
				order.happiness = math.floor(math.clamp(100 * (1 - elapsed / order.patience), 0, 100))
				if elapsed >= order.patience then
					order.model:Destroy()
					table.remove(queue, index)
					changed = true
				end
			end
			if changed then refreshPositions() OrderService.Changed:Fire() end
		end
	end)
end

return OrderService
