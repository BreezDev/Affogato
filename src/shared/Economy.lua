--!strict

local Economy = {}

Economy.Ingredients = table.freeze({
	CoffeeBeans = { name = "Coffee Beans", unit = "drinks", starting = 20 },
	Milk = { name = "Milk", unit = "drinks", starting = 12 },
	OatMilk = { name = "Oat Milk", unit = "drinks", starting = 0 },
	VanillaGelato = { name = "Vanilla Gelato", unit = "scoops", starting = 10 },
	ChocolateGelato = { name = "Chocolate Gelato", unit = "scoops", starting = 6 },
	Syrup = { name = "Syrup", unit = "servings", starting = 8 },
	Chocolate = { name = "Chocolate", unit = "servings", starting = 6 },
	PastryDough = { name = "Pastry Dough", unit = "pastries", starting = 12 },
	CookieDough = { name = "Cookie Dough", unit = "cookies", starting = 10 },
	MuffinBatter = { name = "Muffin Batter", unit = "muffins", starting = 8 },
})

Economy.Suppliers = table.freeze({
	Budget = {
		name = "Budget Supplier", unlockLevel = 1, quality = 0.82, deliverySeconds = 20,
		products = {
			CoffeeBeans = { cost = 20, amount = 20 }, Milk = { cost = 8, amount = 10 },
			VanillaGelato = { cost = 15, amount = 10 }, ChocolateGelato = { cost = 17, amount = 10 },
			Syrup = { cost = 8, amount = 10 }, Chocolate = { cost = 10, amount = 10 },
			PastryDough = { cost = 12, amount = 12 }, CookieDough = { cost = 10, amount = 10 },
			MuffinBatter = { cost = 11, amount = 10 },
		},
	},
	Local = {
		name = "Local Supplier", unlockLevel = 5, quality = 0.92, deliverySeconds = 35,
		products = {
			CoffeeBeans = { cost = 38, amount = 30 }, Milk = { cost = 15, amount = 20 }, OatMilk = { cost = 18, amount = 15 },
			VanillaGelato = { cost = 27, amount = 20 }, ChocolateGelato = { cost = 30, amount = 20 },
			Syrup = { cost = 15, amount = 20 }, Chocolate = { cost = 18, amount = 20 },
			PastryDough = { cost = 21, amount = 24 }, CookieDough = { cost = 18, amount = 20 }, MuffinBatter = { cost = 19, amount = 20 },
		},
	},
	Premium = {
		name = "Premium Supplier", unlockLevel = 12, quality = 1, deliverySeconds = 50,
		products = {
			CoffeeBeans = { cost = 65, amount = 40 }, Milk = { cost = 25, amount = 30 }, OatMilk = { cost = 30, amount = 25 },
			VanillaGelato = { cost = 45, amount = 30 }, ChocolateGelato = { cost = 49, amount = 30 },
			Syrup = { cost = 25, amount = 30 }, Chocolate = { cost = 30, amount = 30 },
			PastryDough = { cost = 35, amount = 36 }, CookieDough = { cost = 29, amount = 30 }, MuffinBatter = { cost = 31, amount = 30 },
		},
	},
})

Economy.Equipment = table.freeze({
	EspressoMachine = {
		name = "Espresso Machine",
		tiers = {
			{ name = "Starter", cost = 0, speed = 1, quality = 0 }, { name = "Improved", cost = 250, speed = 1.15, quality = 0.02 },
			{ name = "Commercial", cost = 700, speed = 1.35, quality = 0.06 }, { name = "Dual", cost = 1600, speed = 1.6, quality = 0.08 },
			{ name = "Premium", cost = 3500, speed = 2, quality = 0.12 },
		},
	},
	Oven = { name = "Oven", tiers = {
		{ name = "Starter", cost = 0, speed = 1, capacity = 1 }, { name = "Double", cost = 400, speed = 1.15, capacity = 2 },
		{ name = "Commercial", cost = 1300, speed = 1.5, capacity = 4 }, { name = "Premium", cost = 3000, speed = 1.9, capacity = 6 },
	} },
	GelatoDisplay = { name = "Gelato Display", tiers = {
		{ name = "Starter", cost = 0, capacity = 2 }, { name = "Four Flavor", cost = 350, capacity = 4 },
		{ name = "Six Flavor", cost = 900, capacity = 6 }, { name = "Premium", cost = 2200, capacity = 10 },
	} },
	BakeryCase = { name = "Bakery Display Case", tiers = {
		{ name = "Starter", cost = 0, capacity = 12 }, { name = "Medium", cost = 300, capacity = 24 },
		{ name = "Large", cost = 850, capacity = 40 }, { name = "Premium", cost = 2000, capacity = 70 },
	} },
	Register = { name = "Register", tiers = {
		{ name = "Basic", cost = 0, speed = 1 }, { name = "Digital", cost = 300, speed = 1.15 },
		{ name = "Smart", cost = 850, speed = 1.3 }, { name = "Self-order Kiosk", cost = 2000, speed = 1.5 },
	} },
})

Economy.PlayerUpgrades = table.freeze({
	Movement = { name = "Movement Speed", costs = { 100, 250, 500, 900, 1500, 2400 }, maxLevel = 6 },
	Carry = { name = "Carry Capacity", costs = { 175, 450, 900, 1750 }, maxLevel = 4 },
	Interaction = { name = "Interaction Speed", costs = { 125, 300, 650, 1200, 2200 }, maxLevel = 5 },
})

Economy.Staff = table.freeze({
	Ava = { name = "Ava", role = "Barista", hireCost = 300, wage = 45, speed = 3, accuracy = 4, friendliness = 5 },
	Marco = { name = "Marco", role = "Baker", hireCost = 450, wage = 60, speed = 5, accuracy = 3, friendliness = 3 },
	Mia = { name = "Mia", role = "Server", hireCost = 250, wage = 40, speed = 4, accuracy = 4, friendliness = 4 },
})

Economy.Training = table.freeze({ costs = { 500, 1200, 2500, 5000 }, maxLevel = 4 })

return table.freeze(Economy)
