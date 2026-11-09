--!strict
local Balance = require("./Balance")
local V = require("./PetVariants")
local Migration = {}
-- Frozen v2 upgrade contract. These values describe refunds, never current balance.
Migration.LegacyMaxLevel = 3
Migration.LegacyBonus = 0.1
function Migration.refund(level: number): number
	return 10 * (2 ^ math.clamp(level, 0, Migration.LegacyMaxLevel) - 1)
end
-- Frozen v1 source values: never tune these when balancing the new catalog.
local OLD_BASE: { [string]: number } = {
	ScarletMushroom = 1.2,
	StrawberryCake = 1.5,
	AutumnCat = 2.5,
	FlameCat = 8,
	Cactus = 1.2,
	Frog = 1.5,
	Watermelon = 2.5,
	GreenDragon = 8,
	Shark = 1.2,
	CloudBird = 1.5,
	AngelCat = 2.5,
	IceCat = 8,
	Butterfly = 1.2,
	MoonCat = 1.5,
	GalaxyCat = 2.5,
	CrystalCat = 8,
}
local OLD_TIERS = { Common = 1, Uncommon = 2, Rare = 5, Rainbow = 15 }
local OLD_EGGS: { [string]: string } = {}
local oldPools: { [string]: { string } } = {
	Common = { "ScarletMushroom", "StrawberryCake", "AutumnCat", "FlameCat" },
	Uncommon = { "Cactus", "Frog", "Watermelon", "GreenDragon" },
	Rare = { "Shark", "CloudBird", "AngelCat", "IceCat" },
	Rainbow = { "Butterfly", "MoonCat", "GalaxyCat", "CrystalCat" },
}
for egg, ids in oldPools do
	for _, id in ids do
		OLD_EGGS[id] = egg
	end
end

function Migration.fields(pet: any, definition: any): any
	local result: any = {
		boost = pet.boost,
		upgradeLevel = math.clamp(math.floor(pet.upgradeLevel or 0), 0, Migration.LegacyMaxLevel),
	}
	if pet.id == "AdminDragon" or type(definition.boost) ~= "number" then
		return result
	end
	local egg = pet.eggId
	local world = if pet.sourceWorld == 2 then 2 else 1
	if type(egg) ~= "string" or not Balance.EggTiers[egg] then
		egg = nil
		local base = OLD_BASE[pet.id]
		local sourceEgg = OLD_EGGS[pet.id]
		if base and sourceEgg then
			local tier = OLD_TIERS[sourceEgg]
			for _, candidateWorld in { 1, 2 } do
				local old = base * tier * (if candidateWorld == 2 then 3 else 1)
				if math.abs(pet.boost - old) < 0.000001 then
					egg, world = sourceEgg, candidateWorld
				end
			end
		end
	end
	if egg then
		result.eggId, result.sourceWorld, result.balanceVersion = egg, world, Balance.Version
	end
	result.baseBoost = if result.eggId
		then Balance.petBoost(definition.boost, result.eggId, result.sourceWorld)
		else V.base(pet)
	result.form = V.form(pet)
	result.mutation = if V.mutation(pet.mutation) then pet.mutation else nil
	result.craftRevision = if type(pet.craftRevision) == "number" and pet.craftRevision == pet.craftRevision
		then math.clamp(math.floor(pet.craftRevision), 0, 1e9)
		else 0
	result.variantVersion = 1
	result.upgradeLevel = 0
	result.boost = V.boost(result)
	return result
end

return Migration
