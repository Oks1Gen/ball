--!strict
-- Marks for the reveal: a pet whose kind the player did not hold yet is new,
-- every other one shows how many of that kind the player holds with it.
local PetNews = {}

type Pet = { uid: string, id: string }

-- Copies of `hatched` with `fresh` and `owned`. The inventory may already hold
-- the hatched pets (they are skipped by uid), so the server can mark before or
-- after adding them. The profile never stores the marks: they live on copies.
function PetNews.mark<T>(inventory: { Pet }, hatched: { T & Pet }): { T & Pet & { fresh: boolean, owned: number } }
	local skip: { [string]: boolean } = {}
	for _, pet in hatched do
		skip[pet.uid] = true
	end
	local counts: { [string]: number } = {}
	for _, pet in inventory do
		if not skip[pet.uid] then
			counts[pet.id] = (counts[pet.id] or 0) + 1
		end
	end
	local marked = {}
	for _, pet in hatched do
		local owned = (counts[pet.id] or 0) + 1
		counts[pet.id] = owned
		local copy: any = table.clone(pet :: any)
		copy.fresh = owned == 1
		copy.owned = owned
		table.insert(marked, copy)
	end
	return marked
end

return PetNews
