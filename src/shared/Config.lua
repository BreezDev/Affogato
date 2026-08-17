--!strict

local Config = {
	StartingCash = 75,
	AutoSaveSeconds = 60,
	DayDurationSeconds = 13 * 60,
	CustomerPatienceSeconds = 105,
	MaximumQueueSize = 6,
	BaseWalkSpeed = 16,
	DataStoreName = "AffogatoCafe_Phase1_v1",
	BaseStaffSlots = 3,
}

Config.DayPeriods = {
	{ name = "Morning", duration = 150, spawnInterval = 24, preferences = { "Espresso", "Latte", "Croissant", "Muffin" } },
	{ name = "Morning Rush", duration = 120, spawnInterval = 11, preferences = { "Espresso", "Latte", "Croissant" } },
	{ name = "Afternoon", duration = 180, spawnInterval = 20, preferences = { "IcedLatte", "Cookie", "Muffin" } },
	{ name = "Evening Rush", duration = 150, spawnInterval = 12, preferences = { "ClassicAffogato", "ChocolateAffogato", "Cookie" } },
	{ name = "Closing / Restock", duration = 180, spawnInterval = 45, preferences = { "ClassicAffogato", "Espresso" } },
}

return table.freeze(Config)
