local Meta = require("../src/shared/Meta")

local furnitureCount = 0
for id, item in Meta.Furniture do
	furnitureCount += 1
	assert(item.cost > 0 or item.gamepass ~= nil, `{id} must have a cash price or cosmetic-pass gate`)
	assert(item.ambience > 0, `{id} must provide ambience`)
	assert(#item.size == 2 and #item.color == 3, `{id} must define portable size and color data`)
end
assert(furnitureCount >= 8, "build mode should offer multiple furniture themes")

for index, expansion in Meta.Expansions do
	assert(index == 1 or expansion.cost > Meta.Expansions[index - 1].cost, "expansion costs must increase")
	assert(index == 1 or expansion.halfWidth > Meta.Expansions[index - 1].halfWidth, "expansion bounds must grow")
end

local customerCount = 0
for _, customer in Meta.CustomerTypes do
	customerCount += 1
	assert(customer.patience > 0 and customer.spending > 0 and customer.tip > 0, "customer modifiers must be positive")
end
assert(customerCount >= 10, "Phase 7 requires a varied customer roster")

for id, event in Meta.Events do
	assert(event.duration > 0, `{id} must have a duration`)
	assert(event.name ~= "" and event.description ~= "", `{id} must have player-facing copy`)
end

for _, challenge in Meta.Challenges do
	assert(challenge.target > 0 and challenge.rewardCash > 0 and challenge.rewardXP > 0, "challenges need positive targets and rewards")
end

assert(#Meta.LoginRewards == 7, "login progression must contain seven rewards")
local achievementCount = 0
for id, achievement in Meta.Achievements do
	achievementCount += 1
	assert(achievement.target > 0 and achievement.rewardCash > 0 and achievement.rewardXP > 0, `{id} needs a target and rewards`)
end
assert(achievementCount >= 6, "post-Phase-8 progression requires varied achievements")

for _, id in Meta.Gamepasses do assert(id >= 0, "gamepass IDs cannot be negative") end
for _, id in Meta.DeveloperProducts do assert(id >= 0, "developer-product IDs cannot be negative") end

print(`meta_catalog_spec: validated {furnitureCount} furniture items, {#Meta.Expansions} café sizes, and {customerCount} customer types`)
