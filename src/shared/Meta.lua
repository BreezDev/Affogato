--!strict

local Meta = {}

Meta.Furniture = table.freeze({
	CozyTable = { name = "Cozy Table", theme = "Cozy", cost = 90, ambience = 5, size = { 2, 2 }, color = { 133, 87, 55 } },
	WoodChair = { name = "Wood Chair", theme = "Cozy", cost = 45, ambience = 3, size = { 1, 1 }, color = { 154, 103, 67 } },
	Monstera = { name = "Monstera Plant", theme = "Natural", cost = 70, ambience = 6, size = { 1, 1 }, color = { 80, 139, 83 } },
	CreamSofa = { name = "Cream Sofa", theme = "Parisian", cost = 240, ambience = 15, size = { 3, 1 }, color = { 236, 220, 196 } },
	MarbleTable = { name = "Marble Table", theme = "Modern", cost = 180, ambience = 8, size = { 2, 2 }, color = { 220, 220, 214 } },
	PinkFlowers = { name = "Pink Flower Vase", theme = "Pink Café", cost = 85, ambience = 7, size = { 1, 1 }, color = { 232, 153, 175 } },
	VintagePainting = { name = "Vintage Coffee Painting", theme = "Italian Café", cost = 140, ambience = 10, size = { 2, 1 }, color = { 115, 70, 52 } },
	IndustrialLamp = { name = "Industrial Floor Lamp", theme = "Industrial", cost = 120, ambience = 6, size = { 1, 1 }, color = { 67, 68, 69 } },
	LuxuryChandelier = { name = "Luxury Gold Chandelier", theme = "Luxury", cost = 1800, ambience = 25, size = { 2, 2 }, color = { 222, 184, 92 }, unlockLevel = 50 },
	RoseGoldCounter = { name = "Rose Gold Counter", theme = "Premium Decor", cost = 0, ambience = 12, size = { 3, 1 }, color = { 218, 152, 160 }, gamepass = "PremiumDecor" },
})

Meta.Expansions = table.freeze({
	{ name = "Starter Café", cost = 0, halfWidth = 14, halfDepth = 10 },
	{ name = "Larger Seating Area", cost = 800, halfWidth = 18, halfDepth = 13 },
	{ name = "Bakery Kitchen", cost = 2200, halfWidth = 22, halfDepth = 16 },
	{ name = "Large Café Floor", cost = 5000, halfWidth = 27, halfDepth = 20 },
	{ name = "Outdoor Patio", cost = 10000, halfWidth = 32, halfDepth = 23 },
	{ name = "Premium Second Floor", cost = 22000, halfWidth = 36, halfDepth = 27 },
})

Meta.CustomerTypes = table.freeze({
	Normal = { name = "Customer", patience = 1, spending = 1, tip = 1 },
	Student = { name = "Student", patience = 1.2, spending = 0.82, tip = 0.8 },
	OfficeWorker = { name = "Office Worker", patience = 0.72, spending = 1.1, tip = 1.35 },
	ParentChild = { name = "Parent + Child", patience = 1.05, spending = 1.35, tip = 1 },
	CoffeeSnob = { name = "Coffee Snob", patience = 0.9, spending = 1.4, tip = 1.5, minReputation = 2.5 },
	Influencer = { name = "Influencer", patience = 1, spending = 1.45, tip = 1.35, minReputation = 3 },
	Tourist = { name = "Tourist", patience = 1.1, spending = 1.3, tip = 1.2, minReputation = 2 },
	Regular = { name = "Regular", patience = 1.15, spending = 1.15, tip = 1.3, minReputation = 2.5 },
	FoodCritic = { name = "Food Critic", patience = 0.85, spending = 1.6, tip = 1.7, minReputation = 3.5, rare = true },
	Celebrity = { name = "Celebrity", patience = 0.8, spending = 2, tip = 2, minReputation = 4, rare = true },
	CafeInvestor = { name = "Café Investor", patience = 1, spending = 1.7, tip = 1.5, minReputation = 4.25, rare = true },
})

Meta.Events = table.freeze({
	MorningRush = { name = "Morning Rush", description = "Customer traffic is doubled!", duration = 90, spawnMultiplier = 0.5 },
	SchoolRush = { name = "School Rush", description = "Students are filling the café.", duration = 90, spawnMultiplier = 0.6 },
	RainyDay = { name = "Rainy Day", description = "Hot drinks and pastries are popular.", duration = 120, spawnMultiplier = 0.8 },
	HeatWave = { name = "Heat Wave", description = "Iced lattes and affogatos are trending.", duration = 120, spawnMultiplier = 0.8 },
	ViralPost = { name = "Viral Social Post", description = "A huge crowd is arriving!", duration = 75, spawnMultiplier = 0.4 },
	SupplierSale = { name = "Supplier Sale", description = "All supplier prices are 20% lower.", duration = 120, supplierDiscount = 0.8 },
	LocalFestival = { name = "Local Festival", description = "Festival visitors are pouring in!", duration = 100, spawnMultiplier = 0.45 },
	DeliveryDelay = { name = "Delivery Delay", description = "New supplier deliveries take twice as long.", duration = 120, deliveryMultiplier = 2 },
	BirthdayParty = { name = "Birthday Party", description = "A large group wants bakery treats.", duration = 90, spawnMultiplier = 0.65 },
	MachineProblem = { name = "Espresso Machine Problem", description = "Espresso preparation is temporarily slower.", duration = 90, espressoSpeed = 0.7 },
})

Meta.LevelUnlocks = table.freeze({
	{ level = 1, name = "Basic Coffee & Bakery" }, { level = 5, name = "Chocolate Croissant & Local Supplier" },
	{ level = 10, name = "Pistachio Collection" }, { level = 15, name = "Matcha Collection" },
	{ level = 20, name = "Advanced Staff" }, { level = 25, name = "Tiramisu" },
	{ level = 30, name = "Major Café Expansion" }, { level = 40, name = "Macarons" }, { level = 50, name = "Luxury Furniture" },
})

Meta.FameTitles = table.freeze({
	{ rating = 1, name = "Unknown Café" }, { rating = 1.7, name = "Neighborhood Café" },
	{ rating = 2.3, name = "Neighborhood Favorite" }, { rating = 3, name = "Local Hotspot" },
	{ rating = 3.5, name = "City Favorite" }, { rating = 4, name = "Viral Café" },
	{ rating = 4.5, name = "Famous Café" }, { rating = 4.85, name = "World-Famous Café" },
})

Meta.Challenges = table.freeze({
	{ id = "ServeOrders", description = "Serve 10 customer orders", target = 10, rewardCash = 150, rewardXP = 80 },
	{ id = "PerfectOrders", description = "Complete 3 perfect orders", target = 3, rewardCash = 200, rewardXP = 100 },
	{ id = "EarnCash", description = "Earn $300 from orders", target = 300, rewardCash = 125, rewardXP = 75 },
	{ id = "MakeAffogato", description = "Make 5 affogatos", target = 5, rewardCash = 175, rewardXP = 90 },
	{ id = "BakeItems", description = "Bake 8 pastries", target = 8, rewardCash = 140, rewardXP = 85 },
	{ id = "RushOrders", description = "Serve 5 orders during a rush", target = 5, rewardCash = 225, rewardXP = 110 },
})

Meta.Achievements = table.freeze({
	FirstOrder = { name = "First Pour", description = "Complete your first order", kind = "Orders", target = 1, rewardCash = 50, rewardXP = 25 },
	OrderCentury = { name = "Neighborhood Staple", description = "Complete 100 orders", kind = "Orders", target = 100, rewardCash = 1000, rewardXP = 500 },
	AffogatoArtist = { name = "Affogato Artist", description = "Prepare 50 affogatos", kind = "Affogatos", target = 50, rewardCash = 750, rewardXP = 350 },
	FiveStars = { name = "Five-Star Service", description = "Reach a 5-star reputation", kind = "Reputation", target = 5, rewardCash = 1500, rewardXP = 750 },
	Decorator = { name = "Cozy Corner", description = "Reach 50 ambience", kind = "Ambience", target = 50, rewardCash = 400, rewardXP = 200 },
	ExpansionMaster = { name = "Café Empire", description = "Unlock every café expansion", kind = "Expansion", target = 6, rewardCash = 2500, rewardXP = 1000 },
})

Meta.LoginRewards = table.freeze({
	{ kind = "Cash", amount = 75 }, { kind = "Ingredients", amount = 5 }, { kind = "Cash", amount = 150 },
	{ kind = "Furniture", itemId = "PinkFlowers", amount = 1 }, { kind = "PremiumIngredients", amount = 8 },
	{ kind = "XP", amount = 200 }, { kind = "Furniture", itemId = "VintagePainting", amount = 1 },
})

Meta.Gamepasses = table.freeze({ VIP = 0, ExtraEmployeeSlot = 0, PremiumDecor = 0, CafeCat = 0, OutfitPack = 0 })
Meta.DeveloperProducts = table.freeze({ EmergencyRestock = 0, CashSmall = 0, CashMedium = 0, CashLarge = 0, Earnings15 = 0, Earnings30 = 0, InstantDelivery = 0 })

return table.freeze(Meta)
