--!strict

local Recipes = require(game.ReplicatedStorage.Affogato.Recipes)

local PreparationService = {}

type Session = { recipeId: string, step: number, qualities: { number }, startedAt: number, ingredientQuality: number }
local sessions: { [Player]: Session } = {}
local prepared: { [Player]: { any } } = {}
local lastAction: { [Player]: number } = {}
local economyService
local profileService

function PreparationService.GetPrepared(player: Player)
	prepared[player] = prepared[player] or {}
	return prepared[player]
end

function PreparationService.StartRecipe(player: Player, recipeId: string, station: string): (boolean, any)
	local recipe = Recipes.ById[recipeId]
	if not recipe or recipe.station ~= station then return false, "That recipe is not available here." end
	if sessions[player] then return false, "Finish your current item first." end
	local profile = profileService.Get(player)
	local capacity = 1 + (profile and profile.playerUpgrades.Carry or 0)
	if #PreparationService.GetPrepared(player) >= capacity then return false, `Your tray is full ({capacity} items).` end
	local consumed, message, ingredientQuality = economyService.ConsumeRecipe(player, recipeId)
	if not consumed then return false, message end
	sessions[player] = { recipeId = recipeId, step = 1, qualities = {}, startedAt = os.clock(), ingredientQuality = ingredientQuality }
	return true, { recipeId = recipeId, displayName = recipe.displayName, step = recipe.steps[1], stepNumber = 1, totalSteps = #recipe.steps }
end

function PreparationService.CompleteStep(player: Player, reportedQuality: number): (boolean, any)
	local session = sessions[player]
	if not session then return false, "Start a recipe at a station." end
	local now = os.clock()
	if now - (lastAction[player] or 0) < 0.2 then return false, "Slow down." end
	lastAction[player] = now
	local recipe = Recipes.ById[session.recipeId]
	local quality = math.clamp(tonumber(reportedQuality) or 0, 0, 1)
	if recipe.steps[session.step] == "Bake" then
		-- A short server-enforced bake keeps the prototype forgiving and non-blocking.
		local profile = profileService.Get(player)
		local ovenTier = profile and profile.equipment.Oven or 1
		local oven = require(game.ReplicatedStorage.Affogato.Economy).Equipment.Oven.tiers[ovenTier]
		if now - session.startedAt < 4 / oven.speed then return false, "The pastry needs a little longer in the oven." end
	end
	table.insert(session.qualities, quality)
	session.step += 1
	if session.step <= #recipe.steps then
		return true, { recipeId = recipe.id, displayName = recipe.displayName, step = recipe.steps[session.step], stepNumber = session.step, totalSteps = #recipe.steps }
	end
	local total = 0
	for _, score in session.qualities do total += score end
	local interactionQuality = total / #session.qualities
	local profile = profileService.Get(player)
	local bonus = 0
	if recipe.station == "Coffee" or recipe.station == "Affogato" then
		local tier = profile and profile.equipment.EspressoMachine or 1
		bonus = require(game.ReplicatedStorage.Affogato.Economy).Equipment.EspressoMachine.tiers[tier].quality or 0
	end
	local finalQuality = math.clamp(interactionQuality * 0.6 + session.ingredientQuality * 0.4 + bonus, 0, 1)
	local inventory = PreparationService.GetPrepared(player)
	table.insert(inventory, { recipeId = recipe.id, quality = finalQuality })
	sessions[player] = nil
	return true, { completed = true, recipeId = recipe.id, displayName = recipe.displayName, quality = finalQuality }
end

function PreparationService.Cancel(player: Player)
	local session = sessions[player]
	if session then economyService.RefundRecipe(player, session.recipeId) end
	sessions[player] = nil
end

function PreparationService.Cleanup(player: Player)
	PreparationService.Cancel(player)
	prepared[player] = nil
	lastAction[player] = nil
end

function PreparationService.AddPrepared(player: Player, recipeId: string, quality: number): boolean
	local profile = profileService.Get(player)
	local inventory = PreparationService.GetPrepared(player)
	if #inventory >= 1 + (profile and profile.playerUpgrades.Carry or 0) then return false end
	table.insert(inventory, { recipeId = recipeId, quality = math.clamp(quality, 0, 1) })
	return true
end

function PreparationService.Start(economy, profiles)
	economyService = economy
	profileService = profiles
end

return PreparationService
