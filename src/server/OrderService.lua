--!strict

local Config = require(game.ReplicatedStorage.Affogato.Config)
local Recipes = require(game.ReplicatedStorage.Affogato.Recipes)

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
}

local queue: { Order } = {}
local nextId = 1
local worldService
local dayService

local function selectItem(preferences: { string }, category: string?): string
	local choices = {}
	for _, id in preferences do
		local recipe = Recipes.ById[id]
		if recipe and (not category or recipe.category == category) then table.insert(choices, id) end
	end
	if #choices == 0 then
		for _, recipe in Recipes.List do
			if not category or recipe.category == category then table.insert(choices, recipe.id) end
		end
	end
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
	local items = { selectItem(period.preferences) }
	if math.random() < 0.38 then
		local first = Recipes.ById[items[1]]
		local secondCategory = first.category == "Bakery" and "Drink" or "Bakery"
		table.insert(items, selectItem(period.preferences, secondCategory))
	end
	local order: Order = {
		id = nextId,
		items = items,
		createdAt = workspace:GetServerTimeNow(),
		patience = Config.CustomerPatienceSeconds,
		happiness = 100,
		tipPotential = math.random(15, 30) / 100,
		model = worldService.CreateCustomer(nextId, #queue + 1),
	}
	nextId += 1
	table.insert(queue, order)
	OrderService.Changed:Fire()
end

function OrderService.TryComplete(prepared: { any }, serviceSpeedMultiplier: number?): (boolean, string, number, number)
	local order = queue[1]
	if not order then return false, "There is no customer waiting.", 0, 0 end
	if #prepared < #order.items then return false, "Prepare every item on the ticket first.", 0, 0 end
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
	if accuracy == 0 then return false, "That is not the next customer's order.", 0, 0 end
	local elapsed = (workspace:GetServerTimeNow() - order.createdAt) / (serviceSpeedMultiplier or 1)
	local speed = math.clamp(1 - elapsed / order.patience, 0, 1)
	local quality = qualityTotal / #order.items
	local subtotal = 0
	for _, id in order.items do subtotal += Recipes.ById[id].price end
	local tip = math.floor(subtotal * order.tipPotential * (0.35 + 0.35 * speed + 0.3 * quality) + 0.5)
	local cash = subtotal + tip
	local xp = 10 * #order.items + (quality >= 0.9 and 5 or 0)
	for index = #prepared, 1, -1 do if used[index] then table.remove(prepared, index) end end
	table.remove(queue, 1)
	order.model:Destroy()
	refreshPositions()
	OrderService.Changed:Fire()
	return true, `Order #{order.id} complete! +${cash} (${tip} tip)`, cash, xp
end

function OrderService.Start(world, day)
	worldService = world
	dayService = day
	OrderService.Spawn()
	task.spawn(function()
		while true do
			task.wait(dayService.GetPeriod().spawnInterval)
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
