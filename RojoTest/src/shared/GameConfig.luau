--!strict
local C = Color3.fromRGB
-- The pure economy lives in Core/Economy so it can be tested without the engine.
local Economy = require("./Core/Economy")
local WorldRefs = require("./WorldRefs")
local Balance = require("./Core/Balance")
local Config = {}
Config.Balance = Balance
Config.DataVersion = 1
Config.MaxLevel = Economy.MaxLevel
Config.CharacterWalkSpeed = 24
Config.TrainingCycle = 1.2
Config.KickContact = 0.42
-- The training contact and the shot windup are the same moment of the kick.
Config.KickWindup = Config.KickContact
-- World1 was scaled by 0.8 on 2026-11-02 and by 0.75 more on 2026-11-03 (0.6 in all).
-- CourseLength doubled only the route: each current 324-stud location is 2250 m.
Config.DistancePerStud = 1000 / 144
-- One ball size for the hand, the training lane and the kick.
Config.BallDiameter = 1.1
-- Reference origin for progression limits; live shots start at the player's kicking foot.
Config.ShotStartLocal = Vector3.new(-115.6, 1.27, 0.3)
Config.WorldShotProgression = {
	[1] = { requiredPower = 1000000, routeStuds = 2592 },
	[2] = { requiredPower = 100000000, routeStuds = 2592 },
}
Config.RebirthBaseSkill = Economy.RebirthBaseSkill
Config.RebirthSkillGrowth = Economy.RebirthSkillGrowth
function Config.effectiveShotPower(skill, power)
	return Economy.effectiveShotPower(skill, power)
end
function Config.rebirthRequirement(rebirths)
	return Economy.rebirthRequirement(rebirths)
end
function Config.rebirthProgress(skill, rebirths)
	return Economy.rebirthProgress(skill, rebirths)
end
-- The apron is a live scene anchor; map movement must also move gameplay coordinates.
-- The reference origin tracks its front edge when the apron is resized.
function Config.arenaFrame(arena: any): CFrame
	local apron = WorldRefs.kickZoneFloor(arena)
	return apron.CFrame * CFrame.new(115, apron.Size.Y / 2 - 0.6, -apron.Size.Z / 2 - 6.68)
end
-- `fromFront`: studs from the apron's front edge, positive onto the apron, negative towards the course.
function Config.kickZoneCharacterPose(arena: any, root: BasePart, humanoid: Humanoid, fromFront: number): CFrame
	local apron = WorldRefs.kickZoneFloor(arena)
	local height = root.Size.Y / 2 + (humanoid.RigType == Enum.HumanoidRigType.R6 and 2 or humanoid.HipHeight)
	return apron.CFrame * CFrame.new(-1, apron.Size.Y / 2 + height + 0.15, -apron.Size.Z / 2 + fromFront)
end
-- Legacy admin teleport destination. Gameplay kicks keep the player's current position.
Config.KickStanceFromFront = -4.68
-- Spawn point on the apron (7.2 studs deep since the 2026-11-03 scale), clear of the back rim.
Config.KickZoneStandFromFront = 5.6
-- Use the visible orange surface as the shared client/server activation boundary.
function Config.inKickZone(arena: any, position: Vector3): boolean
	local apron = WorldRefs.kickZoneFloor(arena)
	if not apron then
		return false
	end
	local point = apron.CFrame:PointToObjectSpace(position)
	return math.abs(point.X) <= apron.Size.X / 2
		and math.abs(point.Z) <= apron.Size.Z / 2
		and point.Y >= apron.Size.Y / 2
		and point.Y < apron.Size.Y / 2 + 12
end
function Config.trainingSurface(lane: any): number
	local strip = lane.TrainingStrip
	return strip.Position.Y + strip.Size.Y / 2 + (lane:FindFirstChild("ImportedField") and 0.08 or 0)
end
function Config.shotLimit(world, arena, startPosition: Vector3?)
	local definition = Config.WorldShotProgression[world] or Config.WorldShotProgression[1]
	arena = arena or WorldRefs.world(world or 1)
	local field = WorldRefs.field(arena, 8)
	if field then
		local frame = Config.arenaFrame(arena)
		local start = startPosition or frame:PointToWorldSpace(Config.ShotStartLocal)
		local gate = WorldRefs.finish(arena)
		local goal = gate and gate:GetPivot().Position or field.Position + frame.LookVector * (field.Size.Z / 2 - 7)
		return math.max(
			Economy.ShotDistanceFloor,
			math.floor((goal - start):Dot(frame.LookVector) * Config.DistancePerStud)
		)
	end
	-- Seven studs of endpoint setback and the existing launch offset of 0.3 studs.
	return math.floor((definition.routeStuds - 7 - 0.3) * Config.DistancePerStud)
end
function Config.shotDistance(skill, power, world, arena, startPosition: Vector3?)
	local definition = Config.WorldShotProgression[world] or Config.WorldShotProgression[1]
	-- Rebirths and pets already increase earned Skill; do not multiply them again.
	local ratio = Economy.shotRatio(skill, power, definition.requiredPower)
	local limit = Config.shotLimit(world, arena, startPosition)
	return Economy.shotDistance(ratio, limit)
end
function Config.shotDuration(distance: number, _world: number?, intensity: number?): number
	local duration = math.clamp(3.2 + distance / 850, 3.2, 14)
	return duration / (1 + 0.8 * math.clamp(intensity or 0, 0, 1))
end
function Config.shotBounceGain(multiplier)
	return Economy.shotBounceGain(multiplier)
end
Config.StudTexture = "rbxassetid://138746650062134"
Config.Music = "rbxassetid://1836105470"
Config.RiverX = -116
Config.Biomes = {
	{ name = "Palm Beach", distance = 0, color = C(29, 207, 227), bank = C(126, 229, 72), kind = "palm" },
	{ name = "Desert Dunes", distance = 750, color = C(245, 188, 64), bank = C(244, 209, 103), kind = "desert" },
	{ name = "Candy Beach", distance = 1500, color = C(127, 231, 118), bank = C(151, 231, 105), kind = "candy" },
	{ name = "Violet Valley", distance = 2250, color = C(181, 132, 237), bank = C(186, 156, 245), kind = "crystal" },
	{ name = "Ember River", distance = 3000, color = C(255, 137, 48), bank = C(245, 157, 86), kind = "lava" },
	{ name = "Moonlight", distance = 3750, color = C(106, 155, 250), bank = C(165, 187, 248), kind = "moon" },
	{ name = "Frozen Falls", distance = 4500, color = C(129, 225, 255), bank = C(215, 246, 255), kind = "ice" },
	{ name = "Rainbow Paradise", distance = 5250, color = C(238, 124, 230), bank = C(166, 242, 121), kind = "rainbow" },
}
-- Public zone names/colours follow Football City. The kinds are construction-only
-- compatibility for historical generators, which run before the final city pass.
for index, theme in require(script.Parent.FootballCity) do
	Config.Biomes[index].name = theme.name
	Config.Biomes[index].color = theme.pitch
	Config.Biomes[index].bank = theme.paving
end
Config.Lanes = {
	{ multiplier = 1, rebirths = 0, color = C(90, 222, 153) },
	{ multiplier = 2, rebirths = 2, color = C(40, 220, 210) },
	{ multiplier = 4, rebirths = 4, color = C(175, 108, 245) },
	{ multiplier = 8, rebirths = 6, color = C(66, 175, 255) },
	{ multiplier = 16, rebirths = 9, color = C(245, 167, 76) },
	{ multiplier = 32, rebirths = 12, color = C(255, 220, 44) },
	{ multiplier = 64, rebirths = 16, color = C(109, 244, 96) },
}
Config.Trails = {
	{ id = "None", name = "No Trail", boost = 1, cost = 0, color = C(180, 185, 193) },
	-- Ids are saved in profiles: the first five keep their old ids under themed names.
	{ id = "White", name = "Gale Trail", boost = 1.2, cost = 10000, color = C(244, 247, 255) },
	{ id = "Tidal", name = "Tidal Trail", boost = 1.25, cost = 150000, color = C(40, 160, 255) },
	{ id = "Red", name = "Volcanic Trail", boost = 1.3, cost = 750000, color = C(255, 48, 84) },
	{ id = "Electric", name = "Electric Trail", boost = 1.4, cost = 2000000, color = C(255, 214, 40) },
	{ id = "Blue", name = "Frost Trail", boost = 1.5, cost = 5000000, color = C(30, 191, 255) },
	{ id = "Earthquake", name = "Earthquake Trail", boost = 1.65, cost = 12000000, color = C(201, 138, 62) },
	{ id = "Purple", name = "Void Trail", boost = 1.8, cost = 25000000, color = C(181, 75, 255) },
	{ id = "Cosmic", name = "Cosmic Trail", boost = 2.1, cost = 50000000, color = C(122, 96, 255) },
	{ id = "Rainbow", name = "Rainbow Trail", boost = 2.5, cost = 100000000, color = C(255, 184, 62) },
	{ id = "Divine", name = "Divine Trail", boost = 3, cost = 250000000, color = C(255, 205, 60) },
}
Config.Stones = {
	-- Ids stay for saved inventories; names and colours follow the Low Poly V2 meshes.
	{ id = "Pebble", name = "Rubber Ball", color = C(235, 52, 72), displaySlot = 5 },
	{ id = "Smooth", name = "Classic Ball", color = C(223, 232, 243), displaySlot = 4 },
	{ id = "Golden", name = "Beach Ball", color = C(78, 209, 255), displaySlot = 3 },
	{ id = "Ruby", name = "Basketball", color = C(255, 128, 36), displaySlot = 2 },
	{ id = "Emerald", name = "Leather Ball", color = C(214, 120, 62), displaySlot = 1 },
	{ id = "Galaxy", name = "Steel Ball", color = C(160, 170, 240), displaySlot = 10 },
	{ id = "Rainbow", name = "Gold Ball", color = C(255, 214, 46), displaySlot = 9 },
	{ id = "DragonSun", name = "Storm Ball", color = C(120, 108, 245), displaySlot = 8 },
	{ id = "BlackHole", name = "Volcano Ball", color = C(255, 110, 36), displaySlot = 7 },
	{ id = "WorldCreator", name = "Sun Ball", color = C(255, 196, 52), displaySlot = 6 },
}
-- Keep retired red-egg IDs valid for existing saved inventories.
Config.LegacyPets = {
	{ id = "Dog", name = "Dog", boost = 1.2, color = C(193, 126, 69), rarity = "Common", weight = 40 },
	{ id = "Cat", name = "Cat", boost = 1.5, color = C(240, 190, 120), rarity = "Common", weight = 30 },
	{ id = "Bunny", name = "Clover Bun", boost = 2.5, color = C(180, 236, 146), rarity = "Uncommon", weight = 20 },
	{ id = "Fox", name = "Golden Fox", boost = 4, color = C(255, 177, 50), rarity = "Rare", weight = 9 },
	{ id = "Dragon", name = "Crystal Dragon", boost = 8, color = C(171, 99, 249), rarity = "Legendary", weight = 1 },
}
Config.Pets = {
	{
		id = "ScarletMushroom",
		boost = Balance.PetBoosts[1],
		weight = Balance.PetWeights[1],
		name = "Clover Bunny",
		color = C(245, 221, 187),
		rarity = "Common",
		visual = "CloverBunny",
		eggBoost = 1,
	},
	{
		id = "StrawberryCake",
		boost = Balance.PetBoosts[2],
		weight = Balance.PetWeights[2],
		name = "Acorn Squirrel",
		color = C(199, 125, 67),
		rarity = "Uncommon",
		visual = "AcornSquirrel",
		eggBoost = 1,
	},
	{
		-- Keep the saved ID and discovery history for the renamed species.
		id = "AutumnCat",
		boost = Balance.PetBoosts[3],
		weight = Balance.PetWeights[3] - Balance.EpicPetWeight,
		name = "Bloom Fox",
		color = C(242, 121, 81),
		rarity = "Rare",
		visual = "BloomFox",
		eggBoost = 1,
	},
	{
		id = "MoonOwl",
		boost = Balance.PetBoosts[3],
		weight = Balance.EpicPetWeight,
		name = "Moon Owl",
		color = C(196, 150, 202),
		rarity = "Epic",
		visual = "MoonOwl",
		eggBoost = 1,
	},
	{
		id = "FlameCat",
		boost = Balance.PetBoosts[4],
		weight = Balance.PetWeights[4],
		name = "Grove Guardian",
		color = C(193, 190, 135),
		rarity = "Legendary",
		visual = "GroveGuardian",
		eggBoost = 1,
	},
}
-- Frost Egg keeps the four saved species IDs and adds Aurora Lynx.
Config.UncommonPets = {
	{
		id = "Cactus",
		boost = Balance.PetBoosts[1],
		weight = Balance.PetWeights[1],
		name = "Snow Pup",
		color = C(245, 222, 186),
		rarity = "Common",
		visual = "SnowPup",
	},
	{
		id = "Frog",
		boost = Balance.PetBoosts[2],
		weight = Balance.PetWeights[2],
		name = "Snowy Penguin",
		color = C(38, 67, 163),
		rarity = "Uncommon",
		visual = "SnowyPenguin",
	},
	{
		id = "Watermelon",
		boost = Balance.PetBoosts[3],
		weight = Balance.PetWeights[3] - Balance.EpicPetWeight,
		name = "Glacier Walrus",
		color = C(22, 173, 185),
		rarity = "Rare",
		visual = "GlacierWalrus",
	},
	{
		id = "AuroraLynx",
		boost = Balance.PetBoosts[3],
		weight = Balance.EpicPetWeight,
		name = "Aurora Lynx",
		color = C(128, 90, 219),
		rarity = "Epic",
		visual = "AuroraLynx",
	},
	{
		id = "GreenDragon",
		boost = Balance.PetBoosts[4],
		weight = Balance.PetWeights[4],
		name = "Glacier Dragon",
		color = C(43, 158, 220),
		rarity = "Legendary",
		visual = "GlacierDragon",
	},
}
Config.RarePets = {
	{
		id = "Shark",
		boost = Balance.PetBoosts[1],
		weight = Balance.PetWeights[1],
		name = "Coal Mole",
		color = C(48, 53, 70),
		rarity = "Common",
		visual = "CoalMole",
		eggBoost = 5,
	},
	{
		id = "CloudBird",
		boost = Balance.PetBoosts[2],
		weight = Balance.PetWeights[2],
		name = "Cinder Gecko",
		color = C(255, 89, 18),
		rarity = "Uncommon",
		visual = "CinderGecko",
		eggBoost = 5,
	},
	{
		id = "AngelCat",
		boost = Balance.PetBoosts[3],
		weight = Balance.PetWeights[3] - Balance.EpicPetWeight,
		name = "Ember Ram",
		color = C(249, 77, 11),
		rarity = "Rare",
		visual = "EmberRam",
		eggBoost = 5,
	},
	{
		id = "BlazeBat",
		boost = Balance.PetBoosts[3],
		weight = Balance.EpicPetWeight,
		name = "Blaze Bat",
		color = C(84, 33, 141),
		rarity = "Epic",
		visual = "BlazeBat",
		eggBoost = 5,
	},
	{
		id = "IceCat",
		boost = Balance.PetBoosts[4],
		weight = Balance.PetWeights[4],
		name = "Inferno Phoenix",
		color = C(255, 48, 18),
		rarity = "Legendary",
		visual = "InfernoPhoenix",
		eggBoost = 5,
	},
}
Config.RainbowPets = {
	{
		id = "Butterfly",
		boost = Balance.PetBoosts[1],
		weight = Balance.PetWeights[1],
		name = "Dusk Moth",
		color = C(176, 90, 231),
		rarity = "Common",
		visual = "DuskMoth",
		eggBoost = 15,
	},
	{
		id = "MoonCat",
		boost = Balance.PetBoosts[2],
		weight = Balance.PetWeights[2],
		name = "Shadow Kitten",
		color = C(53, 37, 132),
		rarity = "Uncommon",
		visual = "ShadowKitten",
		eggBoost = 15,
	},
	{
		id = "GalaxyCat",
		boost = Balance.PetBoosts[3],
		weight = Balance.PetWeights[3] - Balance.Secret.Weight,
		name = "Orbit Axolotl",
		color = C(72, 84, 199),
		rarity = "Rare",
		visual = "OrbitAxolotl",
		eggBoost = 15,
	},
	{
		id = "CrystalCat",
		boost = Balance.PetBoosts[4],
		weight = Balance.PetWeights[4],
		name = "Rift Wyrm",
		color = C(135, 43, 198),
		rarity = "Legendary",
		visual = "RiftWyrm",
		eggBoost = 15,
	},
	{
		id = "EclipseCat",
		name = "Singularity",
		rarity = "Secret",
		boost = Balance.Secret.BaseBoost,
		weight = Balance.Secret.Weight,
		color = C(165, 60, 246),
		visual = "Singularity",
		eggBoost = Balance.EggTiers.Rainbow,
	},
}
Config.SolarPets = {
	{
		id = "HoneyBee",
		name = "Honey Bee",
		rarity = "Common",
		color = C(255, 189, 16),
		visual = "HoneyBee",
		boost = Balance.PetBoosts[1],
		weight = Balance.PetWeights[1],
	},
	{
		id = "DawnChick",
		name = "Dawn Chick",
		rarity = "Uncommon",
		color = C(255, 178, 50),
		visual = "DawnChick",
		boost = Balance.PetBoosts[2],
		weight = Balance.PetWeights[2],
	},
	{
		id = "SunLion",
		name = "Sun Lion",
		rarity = "Rare",
		color = C(255, 154, 44),
		visual = "SunLion",
		boost = Balance.PetBoosts[3],
		weight = Balance.PetWeights[3] - Balance.EpicPetWeight,
	},
	{
		id = "SkyPegasus",
		name = "Sky Pegasus",
		rarity = "Epic",
		color = C(255, 225, 172),
		visual = "SkyPegasus",
		boost = Balance.SolarEpicBoost,
		weight = Balance.EpicPetWeight,
	},
	{
		id = "SolarSeraph",
		name = "Solar Seraph",
		rarity = "Legendary",
		color = C(255, 199, 26),
		visual = "SolarSeraph",
		boost = Balance.PetBoosts[4],
		weight = Balance.PetWeights[4],
	},
}
-- Descriptor pools without colour or visuals: the egg roll stays engine free.
local PetPools: { [string]: { Economy.PetDescriptor } } = {
	Common = Economy.petDescriptors(Config.Pets :: any),
	Uncommon = Economy.petDescriptors(Config.UncommonPets :: any),
	Rare = Economy.petDescriptors(Config.RarePets :: any),
	Rainbow = Economy.petDescriptors(Config.RainbowPets :: any),
	SolarCrown = Economy.petDescriptors(Config.SolarPets :: any),
}
function Config.eggPets(eggId)
	if eggId == "Uncommon" then
		return Config.UncommonPets
	end
	if eggId == "Rare" then
		return Config.RarePets
	end
	if eggId == "Rainbow" then
		return Config.RainbowPets
	end
	if eggId == "SolarCrown" then
		return Config.SolarPets
	end
	return Config.Pets
end
function Config.rollEggPet(eggId, roll)
	local pool = Config.eggPets(eggId)
	local descriptors = Economy.eggPets(PetPools, eggId)
	local chosen = Economy.rollPet(descriptors, roll)
	-- The pet is looked up by its id, not by the position of the descriptor:
	-- a reordered pool must still hand out the pet that was rolled.
	local pet = Economy.petById(pool, chosen.id)
	assert(pet, "The egg pool does not know the pet " .. tostring(chosen.id))
	return pet
end
Config.AdminPet =
	{ id = "AdminDragon", name = "Glitched Dragon", boost = 25, color = C(111, 255, 20), rarity = "Mythic" }
-- These four stands are generated in both worlds. Solar Crown uses the
-- existing fifth stand in Football City.
type Egg = { id: string, name: string, cost: number, color: Color3, x: number, z: number, boost: number }
Config.BaseEggs = {
	{
		id = "Common",
		name = "Common Egg",
		cost = 50,
		color = C(255, 55, 55),
		x = -130,
		z = 123,
		boost = Balance.EggTiers.Common,
	},
	{
		id = "Uncommon",
		name = "Frost Egg",
		cost = 500,
		color = C(75, 245, 98),
		x = -155,
		z = 123,
		boost = Balance.EggTiers.Uncommon,
	},
	{
		id = "Rare",
		name = "Magma Egg",
		cost = 5000,
		color = C(81, 195, 255),
		x = -130,
		z = 160,
		boost = Balance.EggTiers.Rare,
	},
	{
		id = "Rainbow",
		name = "Void Egg",
		cost = 40000,
		color = C(255, 130, 231),
		x = -155,
		z = 160,
		boost = Balance.EggTiers.Rainbow,
	},
} :: { Egg }
Config.SolarEgg = {
	id = "SolarCrown",
	name = "Solar Crown Egg",
	cost = 300000,
	color = C(255, 208, 69),
	x = -90,
	z = 39,
	boost = Balance.EggTiers.SolarCrown,
}
Config.Eggs = table.clone(Config.BaseEggs)
table.insert(Config.Eggs, Config.SolarEgg)

for index, ball in Config.Stones do
	ball.power = nil
	ball.trainingBonus = Balance.Balls[index].bonus
	ball.cost = Balance.Balls[index].cost
end
function Config.eggsForWorld(world: number): { Egg }
	return if world == 2 then Config.BaseEggs else Config.Eggs
end

function Config.eggCost(egg: { cost: number }, world: number): number
	return egg.cost * (if world == 2 then Balance.OceanEggCost else 1)
end

function Config.eggPetBoost(egg: { boost: number }, petBoost: number, world: number): number
	return 1 + (petBoost - 1) * egg.boost * (if world == 2 then Balance.OceanPetBonus else 1)
end

Config.Gifts = Balance.Gifts
Config.Products = require("./CommerceCatalog")

function Config.find(list, id)
	for _, item in list do
		if item.id == id then
			return item
		end
	end
	return nil
end
function Config.pet(id)
	return id == Config.AdminPet.id and Config.AdminPet
		or Config.find(Config.RarePets, id)
		or Config.find(Config.RainbowPets, id)
		or Config.find(Config.SolarPets, id)
		or Config.find(Config.UncommonPets, id)
		or Config.find(Config.Pets, id)
		or Config.find(Config.LegacyPets, id)
end
function Config.level(skill, rebirths)
	return Economy.level(skill, rebirths)
end
function Config.threshold(level, rebirths)
	return Economy.threshold(level, rebirths)
end
function Config.format(value)
	return Economy.format(value)
end
function Config.formatBoost(value: number): string
	return string.format("%.3f", value):gsub("0+$", ""):gsub("%.$", "")
end
return Config
