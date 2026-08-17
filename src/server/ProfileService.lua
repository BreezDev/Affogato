--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Config = require(game.ReplicatedStorage.Affogato.Config)
local Economy = require(game.ReplicatedStorage.Affogato.Economy)

export type Profile = {
	cash: number,
	xp: number,
	level: number,
	completedOrders: number,
	inventory: { [string]: number },
	ingredientQuality: { [string]: number },
	equipment: { [string]: number },
	playerUpgrades: { [string]: number },
	staff: { [string]: { training: number } },
	pendingDeliveries: { any },
}

local ProfileService = {}
local store = DataStoreService:GetDataStore(Config.DataStoreName)
local profiles: { [Player]: Profile } = {}

local function startingInventory()
	local result = {}
	local quality = {}
	for id, ingredient in Economy.Ingredients do
		result[id] = ingredient.starting
		quality[id] = 0.82
	end
	return result, quality
end

local function copyDefault(): Profile
	local inventory, quality = startingInventory()
	return {
		cash = Config.StartingCash, xp = 0, level = 1, completedOrders = 0,
		inventory = inventory, ingredientQuality = quality,
		equipment = { EspressoMachine = 1, Oven = 1, GelatoDisplay = 1, BakeryCase = 1, Register = 1 },
		playerUpgrades = { Movement = 0, Carry = 0, Interaction = 0 }, staff = {}, pendingDeliveries = {},
	}
end

local function copyNumbers(target, source)
	if type(source) ~= "table" then return end
	for id in target do target[id] = math.max(0, math.floor(tonumber(source[id]) or target[id])) end
end

local function copyQuality(target, source)
	if type(source) ~= "table" then return end
	for id in target do target[id] = math.clamp(tonumber(source[id]) or target[id], 0, 1) end
end

function ProfileService.Get(player: Player): Profile?
	return profiles[player]
end

function ProfileService.Load(player: Player): Profile
	local profile = copyDefault()
	local success, saved = pcall(function()
		return store:GetAsync(`player_{player.UserId}`)
	end)
	if success and type(saved) == "table" then
		profile.cash = math.max(0, tonumber(saved.cash) or profile.cash)
		profile.xp = math.max(0, tonumber(saved.xp) or profile.xp)
		profile.level = math.max(1, tonumber(saved.level) or profile.level)
		profile.completedOrders = math.max(0, tonumber(saved.completedOrders) or profile.completedOrders)
		copyNumbers(profile.inventory, saved.inventory)
		copyQuality(profile.ingredientQuality, saved.ingredientQuality)
		copyNumbers(profile.equipment, saved.equipment)
		copyNumbers(profile.playerUpgrades, saved.playerUpgrades)
		for id, level in profile.equipment do profile.equipment[id] = math.clamp(level, 1, #Economy.Equipment[id].tiers) end
		for id, level in profile.playerUpgrades do profile.playerUpgrades[id] = math.clamp(level, 0, Economy.PlayerUpgrades[id].maxLevel) end
		if type(saved.staff) == "table" then
			for id, value in saved.staff do
				if Economy.Staff[id] and type(value) == "table" then profile.staff[id] = { training = math.clamp(math.floor(tonumber(value.training) or 0), 0, Economy.Training.maxLevel) } end
			end
		end
		if type(saved.pendingDeliveries) == "table" then
			for _, delivery in saved.pendingDeliveries do
				local amount = type(delivery) == "table" and tonumber(delivery.amount) or nil
				local quality = type(delivery) == "table" and tonumber(delivery.quality) or nil
				local arrivesAt = type(delivery) == "table" and tonumber(delivery.arrivesAt) or nil
				if type(delivery) == "table" and Economy.Ingredients[delivery.ingredientId] and amount and quality and arrivesAt then
					table.insert(profile.pendingDeliveries, {
						ingredientId = delivery.ingredientId, amount = math.max(1, math.floor(amount)),
						quality = math.clamp(quality, 0, 1), arrivesAt = math.floor(arrivesAt),
						supplier = tostring(delivery.supplier or "Supplier"),
					})
				end
			end
		end
	elseif not success then
		warn(`Could not load profile for {player.Name}; using session defaults`)
	end
	profiles[player] = profile
	return profile
end

function ProfileService.Save(player: Player): boolean
	local profile = profiles[player]
	if not profile then return true end
	local success, message = pcall(function()
		store:UpdateAsync(`player_{player.UserId}`, function()
			return profile
		end)
	end)
	if not success then warn(`Could not save {player.Name}: {tostring(message)}`) end
	return success
end

function ProfileService.Award(player: Player, cash: number, xp: number)
	local profile = profiles[player]
	if not profile then return end
	profile.cash += math.max(0, math.floor(cash))
	profile.xp += math.max(0, math.floor(xp))
	profile.completedOrders += 1
	profile.level = math.floor(profile.xp / 100) + 1
end

function ProfileService.Start()
	Players.PlayerRemoving:Connect(function(player)
		ProfileService.Save(player)
		profiles[player] = nil
	end)
	task.spawn(function()
		while task.wait(Config.AutoSaveSeconds) do
			for player in profiles do ProfileService.Save(player) end
		end
	end)
	game:BindToClose(function()
		for player in profiles do ProfileService.Save(player) end
	end)
end

return ProfileService
