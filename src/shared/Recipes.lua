--!strict

export type Recipe = {
	id: string,
	displayName: string,
	category: "Drink" | "Bakery" | "Affogato",
	price: number,
	steps: { string },
	station: string,
}

local list: { Recipe } = {
	{ id = "Espresso", displayName = "Espresso", category = "Drink", price = 5, steps = { "SelectCup", "PullEspresso" }, station = "Coffee" },
	{ id = "Latte", displayName = "Latte", category = "Drink", price = 7, steps = { "SelectCup", "PullEspresso", "AddMilk" }, station = "Coffee" },
	{ id = "CaramelLatte", displayName = "Caramel Latte", category = "Drink", price = 8, steps = { "SelectCup", "PullEspresso", "AddMilk", "AddCaramel" }, station = "Coffee" },
	{ id = "IcedLatte", displayName = "Iced Latte", category = "Drink", price = 8, steps = { "SelectIcedCup", "AddIce", "PullEspresso", "AddMilk" }, station = "Coffee" },
	{ id = "ClassicAffogato", displayName = "Classic Vanilla Affogato", category = "Affogato", price = 10, steps = { "SelectVanilla", "ScoopGelato", "PullEspresso", "PourEspresso" }, station = "Affogato" },
	{ id = "ChocolateAffogato", displayName = "Chocolate Mocha Affogato", category = "Affogato", price = 12, steps = { "SelectChocolate", "ScoopGelato", "PullEspresso", "PourEspresso", "AddChocolate" }, station = "Affogato" },
	{ id = "Cookie", displayName = "Chocolate Chip Cookie", category = "Bakery", price = 4, steps = { "SelectCookieDough", "PortionDough", "Bake" }, station = "Bakery" },
	{ id = "Croissant", displayName = "Croissant", category = "Bakery", price = 5, steps = { "SelectPastryDough", "ShapeDough", "Bake" }, station = "Bakery" },
	{ id = "Muffin", displayName = "Blueberry Muffin", category = "Bakery", price = 5, steps = { "SelectMuffinBatter", "PortionBatter", "Bake" }, station = "Bakery" },
}

local byId: { [string]: Recipe } = {}
for _, recipe in list do
	byId[recipe.id] = table.freeze(recipe)
end

return table.freeze({
	List = table.freeze(list),
	ById = table.freeze(byId),
})
