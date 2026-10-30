--!strict
-- Transparent 1024px portraits with a common 660px ball-body diameter.
-- Padding and decorations are normalized offline, not by stretching the UI.
-- Sources, measurements and upload IDs: Assets/UI/Balls/v1/.
local Art = {}
local images: { [string]: string } = {
	Pebble = "rbxassetid://137848046238083",
	Smooth = "rbxassetid://130456623916416",
	Golden = "rbxassetid://138798892323387",
	Ruby = "rbxassetid://75061821961654",
	Emerald = "rbxassetid://110480672818112",
	Galaxy = "rbxassetid://128146623637570",
	Rainbow = "rbxassetid://137267685038826",
	DragonSun = "rbxassetid://70485750646082",
	BlackHole = "rbxassetid://97406813561808",
	WorldCreator = "rbxassetid://81900835885471",
}

function Art.image(id: string): string
	return images[id] or images.Pebble
end

return Art
