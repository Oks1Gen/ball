--!strict
local Balance = require("../src/shared/Core/Balance")
local Craft = require("../src/shared/Core/PetCrafting")
local Challenges = require("../src/shared/Core/Challenges")
local Migration = require("../src/shared/Core/PetMigration")
local Data = require("../src/shared/Core/ProfileData")
local Economy = require("../src/shared/Core/Economy")
local Timing = require("../src/shared/Core/KickTiming")
local Boost = require("../src/shared/Core/TrainingBoost")
local Rewards = require("../src/shared/Core/ReturnRewards")
local function near(a: number, b: number)
	assert(math.abs(a - b) < 1e-7, tostring(a) .. " != " .. tostring(b))
end
return {
	["ball and pet bonuses add before unchanged rebirth multiplier"] = function()
		local d = Data.fresh()
		d.pets = { { uid = "a", boost = 2 }, { uid = "b", boost = 1.5 } }
		d.equipped = { "a", "b" }
		near(Balance.trainingMultiplier(d, 5), 7.5)
		d.rebirths = 3
		d.perks.DoubleSkill = true
		near(Balance.trainingMultiplier(d, 5, 2, 3), 7.5 * 4 * 2 * 1.2 * 3)
		assert(Economy.rebirthRequirement(0) == 50000 and Economy.rebirthRequirement(1) == 80000)
		near(
			Rewards.offlineRate(d, { { multiplier = 1, rebirths = 0 } }, 5),
			7.5 * 4 * 2 * Balance.TrainingSkillPerSecond * Rewards.OfflineFraction
		)
	end,
	["timing cannot skip the course at twenty thousand Skill"] = function()
		local weak = Economy.shotDistance(Economy.shotRatio(20000, Timing.MinCombined, 1000000), 17897)
		local perfect = Economy.shotDistance(Economy.shotRatio(20000, Timing.MaxCombined, 1000000), 17897)
		local neutral = Economy.shotDistance(Economy.shotRatio(20000, 1, 1000000), 17897)
		assert(weak > 2800 and weak < neutral and perfect < 4000 and perfect > neutral)
		assert(Boost.Interval == 14)
		for i = 0, 25 do
			local offer = Boost.offer(73123, i)
			assert(offer.product or (offer.multiplier >= 5 and offer.multiplier <= 15))
		end
	end,
	["secret occupies exactly five of ten thousand equally likely outcomes"] = function()
		local pool = {}
		for i, weight in Balance.PetWeights do
			table.insert(pool, {
				id = tostring(i),
				name = tostring(i),
				rarity = "Common",
				boost = 1,
				weight = weight - (if i == 3 then Balance.Secret.Weight else 0),
			})
		end
		table.insert(
			pool,
			{ id = "secret", name = "Secret", rarity = "Secret", boost = 1, weight = Balance.Secret.Weight }
		)
		assert(Economy.totalWeight(pool) == 10000)
		local count = 0
		for roll = 1, 10000 do
			if Economy.rollPet(pool, roll).id == "secret" then
				count += 1
			end
		end
		assert(count == 5)
	end,
	["normal pet migration is idempotent and preserves paid and custom boosts"] = function()
		local def = { boost = 2.2 }
		local pet = { id = "CrystalCat", boost = 120 }
		local migrated = Migration.fields(pet, def)
		near(migrated.boost, 6.4)
		migrated.id = pet.id
		near(Migration.fields(migrated, def).boost, 6.4)
		near(Migration.fields({ id = "AdminDragon", boost = 25 }, { boost = 25 }).boost, 25)
		near(Migration.fields({ id = "CrystalCat", boost = 123.45 }, def).boost, 123.45)
		near(Migration.fields({ id = "CrystalCat", boost = 360 }, def).boost, 17.2)
	end,
	["recycling never consumes equipped secret or paid pets and duplicate uid pays once"] = function()
		local d = Data.fresh()
		d.pets = { { uid = "a", id = "Cactus", rarity = "Common", boost = 1.15 } }
		d.equipped = { "a" }
		assert(not Craft.salvage(d, "a") and #d.pets == 1)
		d.equipped = {}
		assert(Craft.salvage(d, "a") and d.petMaterial == 1 and #d.pets == 0)
		assert(not Craft.salvage(d, "a") and d.petMaterial == 1)
		for _, pet in
			{
				{ uid = "s", id = "EclipseCat", rarity = "Secret", boost = 7.75 },
				{ uid = "p", id = "AdminDragon", rarity = "Mythic", boost = 25 },
			}
		do
			d.pets = { pet }
			assert(not Craft.salvage(d, pet.uid))
		end
	end,
	["challenge rewards require authoritative manual hits and cannot pay twice across reload"] = function()
		local d = Data.fresh()
		Challenges.shot(d, 1, 8, Timing.MaxCombined, false)
		assert(not Challenges.claim(d, "first-kick"))
		Challenges.shot(d, 1, 1, 1, true)
		assert(Challenges.claim(d, "first-kick"))
		assert(d.wins == 40 and d.petMaterial == 1)
		local catalog = { stones = { Pebble = true }, trails = { None = true }, pets = {} }
		d = Data.normalize(d, catalog)
		assert(not Challenges.claim(d, "first-kick") and d.wins == 40)
		d.world = 2
		assert(not Challenges.claim(d, "first-kick"))
		Challenges.shot(d, 2, 1, 1, true)
		assert(Challenges.claim(d, "first-kick") and d.wins == 80)
	end,
	["accurate zone challenges reject weak shots and bound malformed saved counts"] = function()
		local d = Data.fresh()
		for _ = 1, 20 do
			Challenges.shot(d, 1, 8, 1, true)
		end
		assert(not Challenges.claim(d, "zone-3"))
		for _ = 1, 2 do
			Challenges.shot(d, 1, 3, 1.25, true)
		end
		assert(Challenges.claim(d, "zone-3"))
		local loaded = Data.normalize({
			petMaterial = 0 / 0,
			challengeProgress = { ["1:zone-3"] = math.huge },
			challengeClaims = { ["1:zone-3"] = "true" },
		}, { stones = {}, trails = {}, pets = {} })
		assert(
			loaded.petMaterial == 0
				and loaded.challengeProgress["1:zone-3"] == 0
				and not loaded.challengeClaims["1:zone-3"]
		)
	end,
}
