--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Config = require(game.ReplicatedStorage.Affogato.Config)
local Economy = require(game.ReplicatedStorage.Affogato.Economy)
local Meta = require(game.ReplicatedStorage.Affogato.Meta)

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
	reputation: number,
	reputationSamples: number,
	lastServiceScore: number,
	furnitureOwned: { [string]: number },
	furniturePlacements: { any },
	expansion: number,
	challengeDay: number,
	dailyChallenges: { any },
	lastLoginDay: number,
	loginStreak: number,
	menu: { string },
	settings: { [string]: any },
	purchasedGamepasses: { [string]: boolean },
	earningsBoostEndsAt: number,
}

local ProfileService = {}
local store = DataStoreService:GetDataStore(Config.DataStoreName)
local backupStore = DataStoreService:GetDataStore(Config.DataStoreName .. "_Backup")
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
		reputation = 1, reputationSamples = 0, lastServiceScore = 0,
		furnitureOwned = { CozyTable = 2, WoodChair = 4 }, furniturePlacements = {}, expansion = 1,
		challengeDay = 0, dailyChallenges = {}, lastLoginDay = 0, loginStreak = 0,
		menu = { "Espresso", "Latte", "ClassicAffogato", "Cookie", "Croissant" },
		settings = { music = true, sound = true, reducedMotion = false }, purchasedGamepasses = {}, earningsBoostEndsAt = 0,
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
	local key = `player_{player.UserId}`
	local success, saved
	for attempt = 1, 3 do
		success, saved = pcall(function() return store:GetAsync(key) end)
		if success then break end
		task.wait(attempt)
	end
	if not success then success, saved = pcall(function() return backupStore:GetAsync(key) end) end
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
		profile.reputation = math.clamp(tonumber(saved.reputation) or profile.reputation, 1, 5)
		profile.reputationSamples = math.max(0, math.floor(tonumber(saved.reputationSamples) or 0))
		profile.lastServiceScore = math.clamp(tonumber(saved.lastServiceScore) or 0, 0, 1)
		profile.expansion = math.clamp(math.floor(tonumber(saved.expansion) or 1), 1, #Meta.Expansions)
		copyNumbers(profile.furnitureOwned, saved.furnitureOwned)
		if type(saved.furnitureOwned) == "table" then
			for id, count in saved.furnitureOwned do if Meta.Furniture[id] then profile.furnitureOwned[id] = math.max(0, math.floor(tonumber(count) or 0)) end end
		end
		if type(saved.furniturePlacements) == "table" then
			for _, placement in saved.furniturePlacements do
				if type(placement) == "table" and Meta.Furniture[placement.itemId] and type(placement.id) == "string" then
					table.insert(profile.furniturePlacements, { id = placement.id, itemId = placement.itemId, x = math.round(tonumber(placement.x) or 0), z = math.round(tonumber(placement.z) or 0), rotation = math.round((tonumber(placement.rotation) or 0) / 90) * 90 % 360 })
				end
			end
		end
		profile.challengeDay = math.floor(tonumber(saved.challengeDay) or 0)
		if type(saved.dailyChallenges) == "table" then
			for _, progress in saved.dailyChallenges do
				local valid
				if type(progress) == "table" then for _, challenge in Meta.Challenges do if challenge.id == progress.id then valid = challenge break end end end
				if valid then table.insert(profile.dailyChallenges, { id = valid.id, progress = math.clamp(math.floor(tonumber(progress.progress) or 0), 0, valid.target), target = valid.target, claimed = progress.claimed == true }) end
			end
		end
		profile.lastLoginDay = math.floor(tonumber(saved.lastLoginDay) or 0)
		profile.loginStreak = math.clamp(math.floor(tonumber(saved.loginStreak) or 0), 0, 7)
		if type(saved.menu) == "table" then profile.menu = saved.menu end
		if type(saved.settings) == "table" then for keyName in profile.settings do if type(saved.settings[keyName]) == "boolean" then profile.settings[keyName] = saved.settings[keyName] end end end
		if type(saved.purchasedGamepasses) == "table" then for id, owned in saved.purchasedGamepasses do if Meta.Gamepasses[id] and type(owned) == "boolean" then profile.purchasedGamepasses[id] = owned end end end
		profile.earningsBoostEndsAt = math.max(0, math.floor(tonumber(saved.earningsBoostEndsAt) or 0))
	elseif not success then
		warn(`Could not load profile for {player.Name}; using session defaults`)
	end
	profiles[player] = profile
	return profile
end

function ProfileService.Save(player: Player): boolean
	local profile = profiles[player]
	if not profile then return true end
	local key = `player_{player.UserId}`
	local success, message
	for attempt = 1, 3 do
		success, message = pcall(function() store:UpdateAsync(key, function() return profile end) end)
		if success then break end
		task.wait(attempt)
	end
	if success then task.spawn(function() pcall(function() backupStore:SetAsync(key, profile) end) end) end
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
	task.spawn(function()
		while task.wait(Config.AutoSaveSeconds) do
			for player in profiles do ProfileService.Save(player) end
		end
	end)
	game:BindToClose(function()
		for player in profiles do ProfileService.Save(player) end
	end)
end

function ProfileService.Release(player: Player)
	profiles[player] = nil
end

return ProfileService
