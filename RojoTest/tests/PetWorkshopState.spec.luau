--!strict
local Snapshot = require("../src/client/Modules/Snapshot")
local State = require("../src/shared/Core/PetWorkshopState")
return {
	["workshop reads real split inventory and keeps it through progress-only snapshots"] = function()
		local pets = { { uid = "one", id = "Cactus", name = "Cactus" }, { uid = "two", id = "Frog", name = "Frog" } }
		local first =
			Snapshot.apply({ data = { petMaterial = 10 }, inventory = { pets = pets, equipped = { "one", "two" } } })
		assert(first.data.pets == nil and #State.inventory(first).pets == 2)
		assert(#State.inventory(Snapshot.apply({ data = { petMaterial = 11 } })).pets == 2)
		local next = Snapshot.apply({ data = { petMaterial = 11 }, inventory = { pets = { pets[2] }, equipped = {} } })
		assert(#State.inventory(next).pets == 1 and #State.inventory(next).equipped == 0)
	end,
	["equipped and terminal pets remain visible with actionable eligibility reasons"] = function()
		local pet = { uid = "a", id = "Cactus", form = "Normal" }
		assert(State.reason(pet, { "a" }, "Fusion") == "Equipped")
		assert(State.reason(pet, { "a" }, "Mutation") == nil)
		assert(State.reason(pet, {}, "Fusion") == nil)
		pet.form = "Rainbow"
		assert(State.reason(pet, {}, "Fusion") == "Max form")
		assert(State.reason(pet, {}, "Mutation") == nil)
		pet.id = "AdminDragon"
		assert(State.reason(pet, {}, "Mutation") == "Paid pet")
		assert(State.empty(0) ~= State.empty(3))
	end,
}
