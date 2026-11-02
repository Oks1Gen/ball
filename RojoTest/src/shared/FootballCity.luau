--!strict
-- Shared identities; legacy biome kinds stay in GameConfig for the old builders only.
local C = Color3.fromRGB
return {
	{
		name = "Football Field",
		pitch = C(92, 205, 48),
		paving = C(169, 173, 180),
		accent = C(255, 190, 38),
		earth = C(214, 139, 62),
	},
	{
		name = "Park Football",
		pitch = C(76, 194, 63),
		paving = C(199, 173, 121),
		accent = C(255, 190, 38),
		earth = C(214, 139, 62),
	},
	{
		name = "Street Football",
		pitch = C(62, 158, 226),
		paving = C(103, 125, 143),
		accent = C(255, 154, 38),
		earth = C(214, 139, 62),
	},
	{
		name = "Dockyard Pitch",
		pitch = C(40, 185, 187),
		paving = C(167, 181, 182),
		accent = C(255, 190, 38),
		earth = C(214, 139, 62),
	},
	{
		name = "Factory Arena",
		pitch = C(64, 185, 108),
		paving = C(146, 162, 165),
		accent = C(255, 168, 38),
		earth = C(214, 139, 62),
	},
	{
		name = "Rooftop Football",
		pitch = C(52, 180, 199),
		paving = C(123, 145, 171),
		accent = C(255, 165, 49),
		earth = C(214, 139, 62),
	},
	{
		name = "Pro Academy",
		pitch = C(62, 197, 88),
		paving = C(174, 186, 191),
		pavingPattern = { length = 36, light = C(239, 243, 238), west = C(40, 150, 222), east = C(40, 150, 222) },
		accent = C(51, 167, 244),
		earth = C(214, 139, 62),
	},
	{
		name = "City Stadium",
		pitch = C(92, 205, 48),
		paving = C(163, 177, 192),
		pavingPattern = { length = 28, light = C(245, 241, 228), west = C(229, 72, 56), east = C(43, 154, 237) },
		accent = C(255, 204, 69),
		earth = C(214, 139, 62),
	},
}
