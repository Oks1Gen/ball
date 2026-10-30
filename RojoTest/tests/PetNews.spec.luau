--!strict
local PetNews = require("../src/shared/Core/PetNews")

return {
	["a kind the player did not hold is new"] = function()
		local inventory = { { uid = "a", id = "Cat" } }
		local marked = PetNews.mark(inventory, { { uid = "b", id = "Dog" } })
		assert(marked[1].fresh == true and marked[1].owned == 1)
	end,
	["a duplicate shows how many of its kind the player holds"] = function()
		local inventory = { { uid = "a", id = "Cat" }, { uid = "c", id = "Cat" } }
		local marked = PetNews.mark(inventory, { { uid = "b", id = "Cat" } })
		assert(marked[1].fresh == false and marked[1].owned == 3)
	end,
	["the same kind twice in a triple: the first is new, the next a duplicate"] = function()
		local hatched = { { uid = "1", id = "Cat" }, { uid = "2", id = "Cat" }, { uid = "3", id = "Dog" } }
		local marked = PetNews.mark({}, hatched)
		assert(marked[1].fresh and marked[1].owned == 1)
		assert(not marked[2].fresh and marked[2].owned == 2)
		assert(marked[3].fresh and marked[3].owned == 1)
	end,
	["marks ignore the hatched pets already in the inventory and stay off the profile"] = function()
		local pet = { uid = "1", id = "Cat" }
		local inventory = { pet, { uid = "0", id = "Cat" } }
		local marked = PetNews.mark(inventory, { pet })
		assert(marked[1].owned == 2 and not marked[1].fresh, "The inventory copy is not counted twice")
		assert((pet :: any).fresh == nil and (pet :: any).owned == nil, "The stored pet stays unmarked")
		assert(marked[1] ~= pet)
	end,
}
