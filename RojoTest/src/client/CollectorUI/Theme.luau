local C = Color3.fromRGB
return {
	Outline = C(12, 20, 39), Body = C(24, 43, 65), Recess = C(15, 29, 47),
	Text = C(255, 255, 255), Muted = C(181, 204, 226), Gold = C(255, 221, 83),
	Colors = {
		Pets = C(16, 177, 255), Eggs = C(171, 71, 255), Trails = C(14, 206, 229), Shop = C(255, 45, 137),
		Green = C(94, 237, 28), Blue = C(27, 183, 247), Red = C(255, 59, 89), Slate = C(87, 110, 137),
	},
	Rarity = {Common = C(139, 162, 190), Uncommon = C(87, 220, 129), Rare = C(43, 176, 255),
		Epic = C(181, 100, 255), Legendary = C(255, 197, 61), Mythic = C(255, 75, 158)},
	Motion = {Frequency = 5, DampingRatio = 1, Lift = 4, PressDepth = 3, Brighten = 0.12,
		Darken = 0.1, WindowRise = 24, WindowFrequency = 4.5},
}
