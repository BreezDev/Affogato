--!strict

local Recipes = require(game.ReplicatedStorage.Affogato.Recipes)

local PreparationService = {}

type Session = { recipeId: string, step: number, qualities: { number }, startedAt: number }
local sessions: { [Player]: Session } = {}
local prepared: { [Player]: { any } } = {}
local lastAction: { [Player]: number } = {}

function PreparationService.GetPrepared(player: Player)
	prepared[player] = prepared[player] or {}
	return prepared[player]
end

function PreparationService.StartRecipe(player: Player, recipeId: string, station: string): (boolean, any)
	local recipe = Recipes.ById[recipeId]
	if not recipe or recipe.station ~= station then return false, "That recipe is not available here." end
	if sessions[player] then return false, "Finish your current item first." end
	sessions[player] = { recipeId = recipeId, step = 1, qualities = {}, startedAt = os.clock() }
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
		if now - session.startedAt < 4 then return false, "The pastry needs a little longer in the oven." end
	end
	table.insert(session.qualities, quality)
	session.step += 1
	if session.step <= #recipe.steps then
		return true, { recipeId = recipe.id, displayName = recipe.displayName, step = recipe.steps[session.step], stepNumber = session.step, totalSteps = #recipe.steps }
	end
	local total = 0
	for _, score in session.qualities do total += score end
	local finalQuality = total / #session.qualities
	local inventory = PreparationService.GetPrepared(player)
	table.insert(inventory, { recipeId = recipe.id, quality = finalQuality })
	sessions[player] = nil
	return true, { completed = true, recipeId = recipe.id, displayName = recipe.displayName, quality = finalQuality }
end

function PreparationService.Cancel(player: Player)
	sessions[player] = nil
end

function PreparationService.Cleanup(player: Player)
	sessions[player] = nil
	prepared[player] = nil
	lastAction[player] = nil
end

return PreparationService
