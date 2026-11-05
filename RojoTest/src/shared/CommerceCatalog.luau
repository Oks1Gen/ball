--!strict
-- Roblox catalog for this experience. Base prices are metadata; clients display live Roblox prices.
export type Product = {
	id: number,
	kind: string,
	name: string,
	price: number,
	skill: number?,
	trainingBoost: number?,
}
local products: { [string]: Product } = {
	AutoThrow = { id = 2070553162, kind = "GamePass", name = "Auto Kick", price = 25 },
	DoubleSkill = { id = 2070002509, kind = "GamePass", name = "2x Skill", price = 5 },
	DoubleWins = { id = 2067146709, kind = "GamePass", name = "2x Wins", price = 59 },
	StarterPack = { id = 2071564747, kind = "GamePass", name = "Starter Pack", price = 99 },
	Skill10M = { id = 3728591695, kind = "DeveloperProduct", name = "10 Million Skill", price = 25, skill = 10000000 },
	Skill100M = {
		id = 3728591727,
		kind = "DeveloperProduct",
		name = "100 Million Skill",
		price = 95,
		skill = 100000000,
	},
	Skill1B = { id = 3728591755, kind = "DeveloperProduct", name = "1 Billion Skill", price = 185, skill = 1000000000 },
	SkipRebirth = { id = 3728591793, kind = "DeveloperProduct", name = "Skip Rebirth", price = 49 },
	AdminEgg = { id = 3728591825, kind = "DeveloperProduct", name = "Admin Egg - Glitched Dragon", price = 175 },
	TrainingBoost67 = {
		id = 3728591855,
		kind = "DeveloperProduct",
		name = "67x Training Kick",
		price = 5,
		trainingBoost = 67,
	},
	TrainingBoost69 = {
		id = 3728591889,
		kind = "DeveloperProduct",
		name = "69x Training Kick",
		price = 5,
		trainingBoost = 69,
	},
	TrainingBoost144 = {
		id = 3728591926,
		kind = "DeveloperProduct",
		name = "144x Training Kick",
		price = 9,
		trainingBoost = 144,
	},
}
return products
