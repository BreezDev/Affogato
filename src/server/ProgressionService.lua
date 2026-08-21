--!strict

local Meta = require(game.ReplicatedStorage.Affogato.Meta)

local ProgressionService = {}
ProgressionService.Changed = Instance.new("BindableEvent")
local profiles

local function utcDay(): number
	return math.floor(os.time() / 86400)
end

local function newChallenges(day: number)
	local first = day % #Meta.Challenges + 1
	local second = first % #Meta.Challenges + 1
	local result = {}
	for _, index in { first, second } do
		local challenge = Meta.Challenges[index]
		table.insert(result, { id = challenge.id, progress = 0, target = challenge.target, claimed = false })
	end
	return result
end

function ProgressionService.OnLoad(player: Player): string?
	local profile = profiles.Get(player)
	if not profile then return nil end
	local today = utcDay()
	if profile.challengeDay ~= today then profile.challengeDay = today profile.dailyChallenges = newChallenges(today) end
	if profile.lastLoginDay == today then return nil end
	local gap = today - profile.lastLoginDay
	profile.loginStreak = gap <= 2 and math.min(profile.loginStreak + 1, 7) or 1
	profile.lastLoginDay = today
	local reward = Meta.LoginRewards[profile.loginStreak]
	local message
	if reward.kind == "Cash" then profile.cash += reward.amount message = `+${reward.amount}`
	elseif reward.kind == "XP" then profile.xp += reward.amount profile.level = math.floor(profile.xp / 100) + 1 message = `+{reward.amount} XP`
	elseif reward.kind == "Furniture" then profile.furnitureOwned[reward.itemId] = (profile.furnitureOwned[reward.itemId] or 0) + reward.amount message = `+{reward.amount} {Meta.Furniture[reward.itemId].name}`
	else
		local premium = reward.kind == "PremiumIngredients"
		for id in profile.inventory do
			profile.inventory[id] += reward.amount
			if premium then profile.ingredientQuality[id] = math.max(profile.ingredientQuality[id], 1) end
		end
		message = `+{reward.amount} of every {premium and "premium " or ""}ingredient`
	end
	ProgressionService.Changed:Fire(player)
	return `Daily reward Day {profile.loginStreak}: {message}!`
end

function ProgressionService.Record(player: Player, kind: string, amount: number)
	local profile = profiles.Get(player)
	if not profile then return end
	for _, progress in profile.dailyChallenges do
		if not progress.claimed and progress.id == kind then progress.progress = math.min(progress.target, progress.progress + amount) end
	end
	ProgressionService.Changed:Fire(player)
end

function ProgressionService.CheckAchievements(player: Player, metrics): { string }
	local profile = profiles.Get(player)
	local unlocked = {}
	if not profile then return unlocked end
	local values = {
		Orders = profile.completedOrders, Affogatos = profile.stats.Affogatos,
		Reputation = metrics.reputation or profile.reputation, Ambience = metrics.ambience or 0,
		Expansion = metrics.expansion or profile.expansion,
	}
	for id, achievement in Meta.Achievements do
		if not profile.achievements[id] and (values[achievement.kind] or 0) >= achievement.target then
			profile.achievements[id] = true
			profile.cash += achievement.rewardCash
			profile.xp += achievement.rewardXP
			profile.level = math.floor(profile.xp / 100) + 1
			table.insert(unlocked, `{achievement.name}: +${achievement.rewardCash}, +{achievement.rewardXP} XP`)
		end
	end
	if #unlocked > 0 then ProgressionService.Changed:Fire(player) end
	return unlocked
end

function ProgressionService.Claim(player: Player, challengeId: string): (boolean, string)
	local profile = profiles.Get(player)
	if not profile then return false, "Profile unavailable." end
	for _, progress in profile.dailyChallenges do
		if progress.id == challengeId then
			if progress.claimed then return false, "Already claimed." end
			if progress.progress < progress.target then return false, "Challenge is not complete." end
			for _, challenge in Meta.Challenges do
				if challenge.id == challengeId then
					progress.claimed = true
					profile.cash += challenge.rewardCash
					profile.xp += challenge.rewardXP
					profile.level = math.floor(profile.xp / 100) + 1
					ProgressionService.Changed:Fire(player)
					return true, `Challenge claimed: +${challenge.rewardCash}, +{challenge.rewardXP} XP!`
				end
			end
		end
	end
	return false, "Challenge not found."
end

function ProgressionService.Start(profileService)
	profiles = profileService
end

return ProgressionService
