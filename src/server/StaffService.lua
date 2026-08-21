--!strict

local Players = game:GetService("Players")

local Economy = require(game.ReplicatedStorage.Affogato.Economy)
local Recipes = require(game.ReplicatedStorage.Affogato.Recipes)

local StaffService = {}
StaffService.CompletedOrder = Instance.new("BindableEvent")

local profiles
local economy
local preparation
local orders
local lastWork: { [Player]: { [string]: number } } = {}

local function neededRecipe(player: Player, role: string): string?
	local order = orders.GetQueue()[1]
	if not order then return nil end
	local heldCounts = {}
	for _, item in preparation.GetPrepared(player) do heldCounts[item.recipeId] = (heldCounts[item.recipeId] or 0) + 1 end
	for _, id in order.items do
		local info = orders.GetItemInfo(id)
		local heldId = info and info.baseId or id
		if (heldCounts[heldId] or 0) > 0 then
			heldCounts[heldId] -= 1
		else
			local category = info and info.category
			if (role == "Barista" and category == "Drink") or (role == "Baker" and category == "Bakery") then return info.baseId end
		end
	end
	return nil
end

local function work(player: Player, staffId: string, employee, candidate)
	lastWork[player] = lastWork[player] or {}
	local now = os.clock()
	local interval = math.max(4, 16 - candidate.speed * 1.5 - employee.training)
	if now - (lastWork[player][staffId] or 0) < interval then return end
	lastWork[player][staffId] = now
	if candidate.role == "Server" then
		local profile = profiles.Get(player)
		local registerSpeed = Economy.Equipment.Register.tiers[profile.equipment.Register].speed
		local success, message, cash, xp, metrics = orders.TryComplete(preparation.GetPrepared(player), registerSpeed)
		if success then StaffService.CompletedOrder:Fire(player, message, cash, xp, metrics) end
		return
	end
	local recipeId = neededRecipe(player, candidate.role)
	if not recipeId then return end
	local success, _, ingredientQuality = economy.ConsumeRecipe(player, recipeId)
	if not success then return end
	local accuracy = math.clamp(0.72 + candidate.accuracy * 0.04 + employee.training * 0.035, 0, 0.98)
	if math.random() > accuracy then economy.RefundRecipe(player, recipeId) return end
	local quality = math.clamp(ingredientQuality * 0.65 + accuracy * 0.35, 0, 1)
	if not preparation.AddPrepared(player, recipeId, quality) then economy.RefundRecipe(player, recipeId) end
end

function StaffService.Start(profileService, economyService, preparationService, orderService)
	profiles, economy, preparation, orders = profileService, economyService, preparationService, orderService
	Players.PlayerRemoving:Connect(function(player) lastWork[player] = nil end)
	task.spawn(function()
		while task.wait(1) do
			for _, player in Players:GetPlayers() do
				local profile = profiles.Get(player)
				if profile then
					for staffId, employee in profile.staff do work(player, staffId, employee, Economy.Staff[staffId]) end
				end
			end
		end
	end)
end

return StaffService
