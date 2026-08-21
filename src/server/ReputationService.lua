--!strict

local Meta = require(game.ReplicatedStorage.Affogato.Meta)

local ReputationService = {}
local profiles
local buildService

function ReputationService.RecordOrder(player: Player, metrics)
	local profile = profiles.Get(player)
	if not profile then return end
	local ambience = math.clamp(buildService.GetAmbience(player) / 100, 0, 1)
	local score = math.clamp(metrics.accuracy * 0.35 + metrics.speed * 0.25 + metrics.quality * 0.3 + ambience * 0.1, 0, 1)
	profile.reputationSamples += 1
	local alpha = 1 / math.min(profile.reputationSamples, 25)
	profile.reputation = math.clamp(profile.reputation * (1 - alpha) + (1 + score * 4) * alpha, 1, 5)
	if metrics.customerType == "Food Critic" and score >= 0.9 then profile.reputation = math.min(5, profile.reputation + 0.2) end
	profile.lastServiceScore = score
	return score
end

function ReputationService.GetFame(rating: number): string
	local title = Meta.FameTitles[1].name
	for _, entry in Meta.FameTitles do if rating >= entry.rating then title = entry.name end end
	return title
end

function ReputationService.Start(profileService, builds)
	profiles, buildService = profileService, builds
end

return ReputationService
