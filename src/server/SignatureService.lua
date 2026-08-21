--!strict

local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local Recipes = require(game.ReplicatedStorage.Affogato.Recipes)

local SignatureService = {}
SignatureService.Changed = Instance.new("BindableEvent")
local profiles
local orderService

local BASES = { Latte = true, IcedLatte = true, ClassicAffogato = true }
local FLAVORS = { None = true, Caramel = true, Chocolate = true, Pistachio = true, Matcha = true }
local TOPPINGS = { None = true, WhippedCream = true, CookieCrumb = true, ChocolateDrizzle = true }

local function cleanName(value: any): string
	local name = tostring(value or "My Signature Drink"):gsub("[%c<>]", ""):sub(1, 28)
	return #name >= 3 and name or "My Signature Drink"
end

local function filterName(player: Player, value: any): string?
	local cleaned = cleanName(value)
	local success, filtered = pcall(function()
		return TextService:FilterStringAsync(cleaned, player.UserId):GetNonChatStringForBroadcastAsync()
	end)
	return success and cleanName(filtered) or nil
end

function SignatureService.Create(player: Player, payload): (boolean, string)
	local profile = profiles.Get(player)
	if not profile or type(payload) ~= "table" then return false, "Invalid signature recipe." end
	if #profile.signatureDrinks >= 3 then return false, "You can save up to three signature drinks." end
	local baseId, flavor, topping = tostring(payload.baseId), tostring(payload.flavor), tostring(payload.topping)
	if not BASES[baseId] or not FLAVORS[flavor] or not TOPPINGS[topping] then return false, "Choose valid signature ingredients." end
	local prepId = baseId
	if flavor == "Caramel" and baseId ~= "ClassicAffogato" then prepId = "CaramelLatte"
	elseif flavor == "Matcha" then prepId = baseId == "ClassicAffogato" and "MatchaAffogato" or "MatchaLatte"
	elseif flavor == "Pistachio" and baseId == "ClassicAffogato" then prepId = "PistachioAffogato"
	elseif flavor == "Chocolate" and baseId == "ClassicAffogato" then prepId = "ChocolateAffogato" end
	local prepRecipe = Recipes.ById[prepId]
	if profile.level < (prepRecipe.unlockLevel or 1) then return false, `Reach level {prepRecipe.unlockLevel} to use that component.` end
	local name = filterName(player, payload.name)
	if not name then return false, "Roblox could not filter that name. Please try another." end
	local id = "Signature_" .. HttpService:GenerateGUID(false)
	local recipe = { id = id, name = name, baseId = baseId, prepId = prepId, flavor = flavor, topping = topping, price = math.clamp(math.floor((tonumber(payload.price) or 10) * 2 + 0.5) / 2, 5, 18), sold = 0 }
	table.insert(profile.signatureDrinks, recipe)
	table.insert(profile.menu, id)
	SignatureService.Changed:Fire(player)
	return true, `{recipe.name} is now on your menu!`
end

function SignatureService.Delete(player: Player, signatureId: string): (boolean, string)
	local profile = profiles.Get(player)
	if not profile then return false, "Profile unavailable." end
	if orderService then for _, order in orderService.GetQueue() do for _, itemId in order.items do if itemId == signatureId then return false, "Finish the active order for this drink before deleting it." end end end end
	for index, recipe in profile.signatureDrinks do
		if recipe.id == signatureId then
			table.remove(profile.signatureDrinks, index)
			for menuIndex = #profile.menu, 1, -1 do if profile.menu[menuIndex] == signatureId then table.remove(profile.menu, menuIndex) end end
			SignatureService.Changed:Fire(player)
			return true, `{recipe.name} removed.`
		end
	end
	return false, "Signature drink not found."
end

function SignatureService.Start(profileService, orders)
	profiles = profileService
	orderService = orders
end

return SignatureService
