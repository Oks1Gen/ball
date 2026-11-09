--!strict
local Data = require("../src/shared/Core/ProfileData")
local Craft = require("../src/shared/Core/PetCrafting")
local V = require("../src/shared/Core/PetVariants")
local B = require("../src/shared/Core/Balance")
local Net = require("../src/shared/Net")
local function near(a: number, b: number)
	assert(math.abs(a - b) < 1e-7, tostring(a) .. " ~= " .. tostring(b))
end
local function fixture(): any
	local d = Data.fresh()
	d.petMaterial = 100
	for i = 1, 5 do
		table.insert(d.pets, {
			uid = tostring(i),
			id = "Cactus",
			name = "Cactus",
			rarity = "Common",
			boost = 1.15,
			eggId = "Uncommon",
			sourceWorld = 1,
		})
	end
	return d
end
return {
	["each form tier advances without changing species and Rainbow remains mutable"] = function()
		for _, form in { "Golden", "Diamond" } do
			local d = fixture()
			for _, pet in d.pets do
				pet.form = form
				pet.baseBoost = 1.15
				pet.boost = V.boost(pet)
			end
			assert(Craft.fuse(d, { "1", "2", "3", "4", "5" }, 0, 0.5))
			assert(#d.pets == 1 and d.pets[1].id == "Cactus")
			assert(d.pets[1].form == (if form == "Golden" then "Diamond" else "Rainbow"))
			if form == "Diamond" then
				assert(not Craft.fuse(d, { "1" }, 1, 0.5))
				assert(Craft.mutate(d, "1", 1, 0))
				near(d.pets[1].boost, 2.5)
			end
		end
	end,
	["form outcomes include failure and normalize for all material counts"] = function()
		for _, form in { "Normal", "Golden", "Diamond" } do
			for n = 1, 5 do
				local odds = V.odds(form, n)
				local total = 0
				for _, entry in odds do
					total += entry.chance
				end
				near(total, 1)
				near(odds[1].chance, 1 - n / 5)
			end
		end
		near(V.odds("Normal", 4)[3].chance, 0.008)
		assert(V.roll(V.odds("Normal", 5), 0) == "Golden")
		assert(V.roll(V.odds("Normal", 5), 0.99) == "Diamond")
		assert(V.roll(V.odds("Normal", 5), 0.9995) == "Rainbow")
	end,
	["fusion consumes materials atomically preserves primary mutation and blocks replay"] = function()
		local d = fixture()
		d.pets[1].mutation = "Cosmic"
		assert(Craft.fuse(d, { "1", "2", "3", "4", "5" }, 0, 0.5))
		assert(#d.pets == 1 and d.pets[1].form == "Golden" and d.pets[1].mutation == "Cosmic")
		near(d.pets[1].boost, 1.6)
		assert(not Craft.fuse(d, { "1", "2", "3", "4", "5" }, 0, 0.5))
		assert(not Craft.mutate(d, "1", 0, 0))
	end,
	["failure consumes exact selection and duplicate invalid origin and equipped reject without spend"] = function()
		local d = fixture()
		assert(not Craft.fuse(d, { "1", "1" }, 0, 0))
		assert(#d.pets == 5)
		d.pets[2].sourceWorld = 2
		assert(not Craft.fuse(d, { "1", "2" }, 0, 0))
		d.equipped = { "1" }
		assert(not Craft.fuse(d, { "1" }, 0, 0))
		d.equipped = {}
		assert(Craft.fuse(d, { "1" }, 0, 0))
		assert(#d.pets == 4)
	end,
	["mutation overwrites stronger with weaker spends once and leaves form intact"] = function()
		local d = fixture()
		local pet = d.pets[1]
		pet.form = "Diamond"
		pet.mutation = "Cosmic"
		assert(Craft.mutate(d, "1", 0, 0))
		assert(pet.mutation == "Wind" and pet.form == "Diamond" and d.petMaterial == 90)
		near(pet.boost, 1.75)
		assert(not Craft.mutate(d, "1", 0, 0))
		assert(d.petMaterial == 90)
		assert(Craft.mutate(d, "1", 1, 0.999))
		assert(pet.mutation == "Cosmic")
		d.petMaterial = 0
		assert(not Craft.mutate(d, "1", 2, 0))
		assert(pet.mutation == "Cosmic")
	end,
	["all five mutations have exact enumerated weights"] = function()
		local outcomes = {}
		local counts = {}
		for _, m in B.Mutations do
			table.insert(outcomes, { id = m.id, chance = m.weight / 10000 })
			counts[m.id] = 0
		end
		for i = 1, 10000 do
			local id = V.roll(outcomes, (i - 0.5) / 10000)
			counts[id] += 1
		end
		for _, m in B.Mutations do
			assert(counts[m.id] == m.weight)
		end
	end,
	["legacy upgrade refund happens once and variant power survives reload without compounding"] = function()
		local d = fixture()
		d.pets = { d.pets[1] }
		d.pets[1].boost = 1.351
		d.pets[1].upgradeLevel = 3
		local catalog = {
			stones = { Pebble = true },
			trails = { None = true },
			pets = {
				Cactus = { name = "Cactus", rarity = "Common", boost = 1.15 },
			},
		}
		local loaded = Data.normalize(d, catalog)
		assert(loaded.petMaterial == 170 and loaded.pets[1].upgradeLevel == 0)
		near(loaded.pets[1].boost, 1.27)
		assert(Craft.mutate(loaded, "1", 0, 0.999))
		loaded.pets[1].form = "Rainbow"
		loaded.pets[1].boost = V.boost(loaded.pets[1])
		for _ = 1, 3 do
			loaded = Data.normalize(loaded, catalog)
			assert(loaded.petMaterial == 160)
			near(loaded.pets[1].boost, 5.32)
		end
	end,
	["network rejects sparse oversized malformed and invented reward payloads"] = function()
		assert(Net.validAction("FusePets", 0, { "a", "b" }))
		assert(not Net.validAction("FusePets", 0, { [2] = "a" }))
		assert(not Net.validAction("FusePets", 0, { "a", "b", "c", "d", "e", "f" }))
		assert(not Net.validAction("FusePets", 0, { uid = "a" }))
		assert(not Net.validAction("MutatePet", "a", 0 / 0))
		assert(not Net.validAction("UpgradePet", "a", nil))
	end,
}
