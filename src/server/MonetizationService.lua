--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Economy = require(game.ReplicatedStorage.Affogato.Economy)
local Meta = require(game.ReplicatedStorage.Affogato.Meta)

local MonetizationService = {}
MonetizationService.Changed = Instance.new("BindableEvent")
local profiles
local worldService

function MonetizationService.RefreshPasses(player: Player)
	local profile = profiles.Get(player)
	if not profile then return end
	for name, passId in Meta.Gamepasses do
		if passId > 0 then
			local success, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
			if success then profile.purchasedGamepasses[name] = owns end
		end
	end
	player:SetAttribute("AffogatoVIP", profile.purchasedGamepasses.VIP == true)
	player:SetAttribute("AffogatoOutfitPack", profile.purchasedGamepasses.OutfitPack == true)
	MonetizationService.Changed:Fire(player)
	if worldService then worldService.ShowCafeCat(player, profile.purchasedGamepasses.CafeCat == true) end
	if worldService then worldService.ShowVIPSign(player, profile.purchasedGamepasses.VIP == true) end
end

function MonetizationService.GetEarningsMultiplier(player: Player): number
	local profile = profiles.Get(player)
	if not profile then return 1 end
	return (profile.purchasedGamepasses.VIP and 1.1 or 1) * (profile.earningsBoostEndsAt > os.time() and 2 or 1)
end

local function grantProduct(player: Player, productId: number): boolean
	local profile = profiles.Get(player)
	if not profile then return false end
	if productId == Meta.DeveloperProducts.EmergencyRestock and productId > 0 then
		for id in Economy.Ingredients do profile.inventory[id] = math.max(profile.inventory[id], 20) end
	elseif productId == Meta.DeveloperProducts.CashSmall and productId > 0 then profile.cash += 500
	elseif productId == Meta.DeveloperProducts.CashMedium and productId > 0 then profile.cash += 2000
	elseif productId == Meta.DeveloperProducts.CashLarge and productId > 0 then profile.cash += 6000
	elseif productId == Meta.DeveloperProducts.Earnings15 and productId > 0 then profile.earningsBoostEndsAt = math.max(profile.earningsBoostEndsAt, os.time()) + 15 * 60
	elseif productId == Meta.DeveloperProducts.Earnings30 and productId > 0 then profile.earningsBoostEndsAt = math.max(profile.earningsBoostEndsAt, os.time()) + 30 * 60
	elseif productId == Meta.DeveloperProducts.InstantDelivery and productId > 0 then
		for _, delivery in profile.pendingDeliveries do delivery.arrivesAt = os.time() end
	else return false end
	MonetizationService.Changed:Fire(player)
	return true
end

function MonetizationService.Start(profileService, world)
	profiles = profileService
	worldService = world
	MarketplaceService.ProcessReceipt = function(receipt)
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
		return grantProduct(player, receipt.ProductId) and Enum.ProductPurchaseDecision.PurchaseGranted or Enum.ProductPurchaseDecision.NotProcessedYet
	end
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, _, purchased)
		if purchased then MonetizationService.RefreshPasses(player) end
	end)
end

return MonetizationService
