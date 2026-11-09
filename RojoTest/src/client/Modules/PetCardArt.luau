--!strict
-- One complete independently generated PNG per pet.
local Art = {}
-- Bottom is the last occupied row plus one on the 512px portrait.
local outlinedPortraits: { [string]: { image: string, bottom: number } } = {
	ScarletMushroom = { image = "rbxassetid://115200199975380", bottom = 496 },
	StrawberryCake = { image = "rbxassetid://92661951811505", bottom = 496 },
	AutumnCat = { image = "rbxassetid://124490712371263", bottom = 494 },
	MoonOwl = { image = "rbxassetid://93803273203661", bottom = 496 },
	FlameCat = { image = "rbxassetid://117525307875285", bottom = 496 },
	Cactus = { image = "rbxassetid://75723867072532", bottom = 455 },
	Frog = { image = "rbxassetid://126093246946268", bottom = 495 },
	Watermelon = { image = "rbxassetid://120375371975993", bottom = 477 },
	AuroraLynx = { image = "rbxassetid://78349984252832", bottom = 495 },
	GreenDragon = { image = "rbxassetid://124608994969151", bottom = 454 },
	Shark = { image = "rbxassetid://84998984605018", bottom = 496 },
	CloudBird = { image = "rbxassetid://140219385075272", bottom = 496 },
	AngelCat = { image = "rbxassetid://133635334101448", bottom = 496 },
	BlazeBat = { image = "rbxassetid://110245325486876", bottom = 479 },
	IceCat = { image = "rbxassetid://121150376848083", bottom = 452 },
	Butterfly = { image = "rbxassetid://130654387175615", bottom = 483 },
	MoonCat = { image = "rbxassetid://131420614917369", bottom = 496 },
	GalaxyCat = { image = "rbxassetid://105488122352898", bottom = 479 },
	CrystalCat = { image = "rbxassetid://120521616667730", bottom = 464 },
	EclipseCat = { image = "rbxassetid://83286800944557", bottom = 437 },
	HoneyBee = { image = "rbxassetid://104500212086314", bottom = 496 },
	DawnChick = { image = "rbxassetid://118337928180503", bottom = 496 },
	SunLion = { image = "rbxassetid://98235141340146", bottom = 446 },
	SkyPegasus = { image = "rbxassetid://116087970002123", bottom = 452 },
	SolarSeraph = { image = "rbxassetid://138388696956168", bottom = 472 },
}

function Art.outlinedImage(id: string): string?
	local portrait = outlinedPortraits[id]
	return if portrait then portrait.image else nil
end

function Art.outlinedImageIds(): { string }
	local ids = {}
	for _, portrait in outlinedPortraits do
		table.insert(ids, portrait.image)
	end
	return ids
end

function Art.hatchFootOffset(id: string): number?
	local portrait = outlinedPortraits[id]
	return if portrait then portrait.bottom / 512 - 0.5 else nil
end

return Art
