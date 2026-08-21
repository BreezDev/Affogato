local Economy = require("../src/shared/Economy")
local Recipes = require("../src/shared/Recipes")
local Config = require("../src/shared/Config")

local totalDuration = 0
for _, period in Config.DayPeriods do
	assert(period.duration > 0, "day periods must have positive durations")
	assert(period.spawnInterval > 0, "spawn intervals must be positive")
	totalDuration += period.duration
end
assert(totalDuration >= 12 * 60 and totalDuration <= 15 * 60, "café day must last 12–15 minutes")

for _, recipe in Recipes.List do
	assert(recipe.price > 0, `{recipe.id} must have a positive price`)
	assert(#recipe.steps > 0, `{recipe.id} must have preparation steps`)
	assert((recipe.unlockLevel or 1) >= 1, `{recipe.id} has an invalid unlock level`)
	for ingredientId, amount in recipe.ingredients do
		assert(Economy.Ingredients[ingredientId], `{recipe.id} references unknown ingredient {ingredientId}`)
		assert(amount > 0 and amount % 1 == 0, `{recipe.id} ingredient costs must be positive integers`)
	end
end

for supplierId, supplier in Economy.Suppliers do
	assert(supplier.unlockLevel >= 1, `{supplierId} has an invalid unlock level`)
	assert(supplier.quality > 0 and supplier.quality <= 1, `{supplierId} has invalid quality`)
	for ingredientId, product in supplier.products do
		assert(Economy.Ingredients[ingredientId], `{supplierId} sells unknown ingredient {ingredientId}`)
		assert(product.cost > 0 and product.amount > 0, `{supplierId}/{ingredientId} must have a positive cost and amount`)
	end
end

for ingredientId in Economy.Ingredients do
	local sold = false
	for _, supplier in Economy.Suppliers do if supplier.products[ingredientId] then sold = true break end end
	assert(sold, `{ingredientId} is used by the economy but unavailable from every supplier`)
end

for equipmentId, equipment in Economy.Equipment do
	assert(equipment.tiers[1].cost == 0, `{equipmentId} starter tier must be free`)
	for tier = 2, #equipment.tiers do
		assert(equipment.tiers[tier].cost > equipment.tiers[tier - 1].cost, `{equipmentId} tier costs must increase`)
	end
end

print(`catalog_spec: validated {#Recipes.List} recipes and a {totalDuration}-second café day`)
