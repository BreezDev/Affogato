--!strict

local HttpService = game:GetService("HttpService")
local Meta = require(game.ReplicatedStorage.Affogato.Meta)

local BuildService = {}
BuildService.Changed = Instance.new("BindableEvent")
local profiles
local world

local function findPlacement(profile, placementId: string)
	for index, placement in profile.furniturePlacements do
		if placement.id == placementId then return placement, index end
	end
	return nil, nil
end

local function validPosition(profile, x: number, z: number, ignoreId: string?): boolean
	local expansion = Meta.Expansions[profile.expansion]
	if math.abs(x) > expansion.halfWidth or math.abs(z) > expansion.halfDepth then return false end
	for _, placement in profile.furniturePlacements do
		if placement.id ~= ignoreId and placement.x == x and placement.z == z then return false end
	end
	return true
end

function BuildService.GetAmbience(player: Player): number
	local profile = profiles.Get(player)
	if not profile then return 0 end
	local total = 0
	for _, placement in profile.furniturePlacements do
		local item = Meta.Furniture[placement.itemId]
		if item then total += item.ambience end
	end
	return total
end

function BuildService.Buy(player: Player, itemId: string): (boolean, string)
	local profile = profiles.Get(player)
	local item = Meta.Furniture[itemId]
	if not profile or not item then return false, "Unknown furniture." end
	if profile.cash < item.cost then return false, "You do not have enough cash." end
	profile.cash -= item.cost
	profile.furnitureOwned[itemId] = (profile.furnitureOwned[itemId] or 0) + 1
	BuildService.Changed:Fire(player)
	return true, `{item.name} added to storage.`
end

function BuildService.Place(player: Player, itemId: string, rawX: number, rawZ: number, rotation: number?): (boolean, string)
	local profile = profiles.Get(player)
	local item = Meta.Furniture[itemId]
	if not profile or not item then return false, "Unknown furniture." end
	if (profile.furnitureOwned[itemId] or 0) < 1 then return false, "Buy or store that furniture first." end
	local x, z = math.round(rawX / 2) * 2, math.round(rawZ / 2) * 2
	if not validPosition(profile, x, z) then return false, "That grid cell is occupied or outside your café." end
	local placement = { id = HttpService:GenerateGUID(false), itemId = itemId, x = x, z = z, rotation = math.round((rotation or 0) / 90) * 90 % 360 }
	table.insert(profile.furniturePlacements, placement)
	profile.furnitureOwned[itemId] -= 1
	world.RenderFurniture(player, profile.furniturePlacements)
	BuildService.Changed:Fire(player)
	return true, `{item.name} placed.`
end

function BuildService.Edit(player: Player, action: string, placementId: string, rawX: number?, rawZ: number?): (boolean, string)
	local profile = profiles.Get(player)
	if not profile then return false, "Profile unavailable." end
	local placement, index = findPlacement(profile, placementId)
	if not placement or not index then return false, "Furniture not found." end
	local item = Meta.Furniture[placement.itemId]
	if action == "Rotate" then
		placement.rotation = (placement.rotation + 90) % 360
	elseif action == "Move" and rawX and rawZ then
		local x, z = math.round(rawX / 2) * 2, math.round(rawZ / 2) * 2
		if not validPosition(profile, x, z, placement.id) then return false, "That grid cell is unavailable." end
		placement.x, placement.z = x, z
	elseif action == "Store" then
		profile.furnitureOwned[placement.itemId] = (profile.furnitureOwned[placement.itemId] or 0) + 1
		table.remove(profile.furniturePlacements, index)
	elseif action == "Sell" then
		profile.cash += math.floor(item.cost * 0.5)
		table.remove(profile.furniturePlacements, index)
	else
		return false, "Unknown build action."
	end
	world.RenderFurniture(player, profile.furniturePlacements)
	BuildService.Changed:Fire(player)
	return true, action == "Sell" and `Sold {item.name} for ${math.floor(item.cost * 0.5)}.` or `{item.name}: {action:lower()} complete.`
end

function BuildService.Expand(player: Player): (boolean, string)
	local profile = profiles.Get(player)
	if not profile then return false, "Profile unavailable." end
	local nextExpansion = Meta.Expansions[profile.expansion + 1]
	if not nextExpansion then return false, "Your café is fully expanded." end
	if profile.cash < nextExpansion.cost then return false, "You do not have enough cash." end
	profile.cash -= nextExpansion.cost
	profile.expansion += 1
	world.RenderExpansion(player, profile.expansion)
	BuildService.Changed:Fire(player)
	return true, `{nextExpansion.name} unlocked!`
end

function BuildService.LoadPlayer(player: Player)
	local profile = profiles.Get(player)
	if profile then world.RenderExpansion(player, profile.expansion) world.RenderFurniture(player, profile.furniturePlacements) end
end

function BuildService.Start(profileService, worldService)
	profiles, world = profileService, worldService
end

return BuildService
