--!strict
local C = Color3.fromRGB
local Catalog = {}
Catalog.entries = {
	{
		id = "Common",
		station = "Egg_Common",
		seat = "Common",
		theme = "Kelp",
		rarity = "Common",
		color = C(237, 190, 52),
	},
	{
		id = "Uncommon",
		station = "Egg_Uncommon",
		seat = "Uncommon",
		theme = "Leviathan",
		rarity = "Uncommon",
		color = C(42, 215, 215),
	},
	{
		id = "Rare",
		station = "Egg_Rare",
		seat = "Volcanic",
		theme = "Treasure",
		rarity = "Rare",
		color = C(255, 208, 69),
	},
	{
		id = "Rainbow",
		station = "Egg_Rainbow",
		seat = "Rare",
		theme = "Abyss",
		rarity = "Epic",
		color = C(117, 143, 255),
	},
	{
		id = "AdminEgg",
		station = "VolcanicEgg",
		seat = "Rainbow",
		theme = "Jelly",
		rarity = "Legendary",
		color = C(198, 143, 255),
	},
}
type Entry = typeof(Catalog.entries[1])
function Catalog.find(id: string, world: number): Entry?
	if world == 2 then
		for _, entry in Catalog.entries do
			if entry.id == id then
				return entry
			end
		end
	end
	return nil
end
return Catalog
