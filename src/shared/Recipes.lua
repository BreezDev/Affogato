--!strict

export type Recipe = {
	id: string,
	displayName: string,
	category: "Drink" | "Bakery" | "Affogato",
	price: number,
	steps: { string },
	station: string,
	ingredients: { [string]: number },
}

local list: { Recipe } = {
	{ id = "Espresso", displayName = "Espresso", category = "Drink", price = 5, steps = { "SelectCup", "PullEspresso" }, station = "Coffee", ingredients = { CoffeeBeans = 1 } },
	{ id = "Latte", displayName = "Latte", category = "Drink", price = 7, steps = { "SelectCup", "PullEspresso", "AddMilk" }, station = "Coffee", ingredients = { CoffeeBeans = 1, Milk = 1 } },
	{ id = "CaramelLatte", displayName = "Caramel Latte", category = "Drink", price = 8, steps = { "SelectCup", "PullEspresso", "AddMilk", "AddCaramel" }, station = "Coffee", ingredients = { CoffeeBeans = 1, Milk = 1, Syrup = 1 } },
	{ id = "IcedLatte", displayName = "Iced Latte", category = "Drink", price = 8, steps = { "SelectIcedCup", "AddIce", "PullEspresso", "AddMilk" }, station = "Coffee", ingredients = { CoffeeBeans = 1, Milk = 1 } },
	{ id = "ClassicAffogato", displayName = "Classic Vanilla Affogato", category = "Affogato", price = 10, steps = { "SelectVanilla", "ScoopGelato", "PullEspresso", "PourEspresso" }, station = "Affogato", ingredients = { VanillaGelato = 1, CoffeeBeans = 1 } },
	{ id = "ChocolateAffogato", displayName = "Chocolate Mocha Affogato", category = "Affogato", price = 12, steps = { "SelectChocolate", "ScoopGelato", "PullEspresso", "PourEspresso", "AddChocolate" }, station = "Affogato", ingredients = { ChocolateGelato = 1, CoffeeBeans = 1, Chocolate = 1 } },
	{ id = "Cookie", displayName = "Chocolate Chip Cookie", category = "Bakery", price = 4, steps = { "SelectCookieDough", "PortionDough", "Bake" }, station = "Bakery", ingredients = { CookieDough = 1 } },
	{ id = "Croissant", displayName = "Croissant", category = "Bakery", price = 5, steps = { "SelectPastryDough", "ShapeDough", "Bake" }, station = "Bakery", ingredients = { PastryDough = 1 } },
	{ id = "Muffin", displayName = "Blueberry Muffin", category = "Bakery", price = 5, steps = { "SelectMuffinBatter", "PortionBatter", "Bake" }, station = "Bakery", ingredients = { MuffinBatter = 1 } },
}

local byId: { [string]: Recipe } = {}
for _, recipe in list do
	byId[recipe.id] = table.freeze(recipe)
end

return table.freeze({
	List = table.freeze(list),
	ById = table.freeze(byId),
})
