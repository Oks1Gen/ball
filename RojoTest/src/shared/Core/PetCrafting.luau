--!strict
local Balance = require("./Balance")
local Data = require("./ProfileData")
local Craft = {}

function Craft.salvage(data: any, uid: string): (boolean, string)
	for index, pet in data.pets do
		if pet.uid ~= uid then
			continue
		end
		local amount = Balance.Crafting.Yield[pet.rarity]
		if not amount or pet.id == "AdminDragon" then
			return false, "This pet cannot be recycled"
		end
		if table.find(data.equipped, uid) then
			return false, "Unequip this pet before recycling"
		end
		table.remove(data.pets, index)
		Data.add(data, "petMaterial", amount)
		return true, "+" .. amount .. " Pet Shards"
	end
	return false, "Pet not found"
end

local V = require("./PetVariants")
function Craft.fuse(data: any, uids: { string }, revision: number, unit: number): (boolean, string, any)
	local primary: any = nil
	local selected: { [string]: boolean } = {}
	if #uids < 1 or #uids > Balance.FusionCount then
		return false, "Select 1–5 matching pets", nil
	end
	for _, uid in uids do
		if selected[uid] then
			return false, "Duplicate selection", nil
		end
		selected[uid] = true
		local pet: any = nil
		for _, candidate in data.pets do
			if candidate.uid == uid then
				pet = candidate
				break
			end
		end
		if not pet then
			return false, "Pet not found", nil
		end
		if pet.id == "AdminDragon" or table.find(data.equipped, uid) then
			return false, "Unequip pets first; paid pets are protected", nil
		end
		if not primary then
			primary = pet
		elseif not V.same(primary, pet) then
			return false, "Pets must match species, origin and form", nil
		end
	end
	if (primary.craftRevision or 0) ~= revision then
		return false, "Selection changed; try again", nil
	end
	if not Balance.FormOutcomes[V.form(primary)] then
		return false, "Rainbow is the highest form", nil
	end
	local outcome = V.roll(V.odds(V.form(primary), #uids), unit)
	local result = table.clone(primary)
	result.baseBoost = V.base(primary)
	result.form = outcome
	result.upgradeLevel = 0
	result.variantVersion = 1
	result.craftRevision = revision + 1
	for i = #data.pets, 1, -1 do
		if selected[data.pets[i].uid] then
			table.remove(data.pets, i)
		end
	end
	if outcome ~= "Fail" then
		result.boost = V.boost(result)
		table.insert(data.pets, result)
	end
	return true,
		if outcome == "Fail" then "Craft failed — selected pets were consumed" else V.name(result),
		{
			kind = "Fusion",
			outcome = outcome,
			pet = if outcome ~= "Fail" then result else nil,
			source = primary,
			count = #uids,
		}
end
function Craft.mutate(data: any, uid: string, revision: number, unit: number): (boolean, string, any)
	local pet: any = nil
	for _, candidate in data.pets do
		if candidate.uid == uid then
			pet = candidate
			break
		end
	end
	if not pet or pet.id == "AdminDragon" then
		return false, "Pet unavailable for mutation", nil
	end
	if (pet.craftRevision or 0) ~= revision then
		return false, "Pet changed; try again", nil
	end
	if data.petMaterial < Balance.MutationCost then
		return false, "Need " .. Balance.MutationCost .. " Shards", nil
	end
	local total = 0
	for _, entry in Balance.Mutations do
		total += entry.weight
	end
	local outcomes = {}
	for _, entry in Balance.Mutations do
		table.insert(outcomes, { id = entry.id, chance = entry.weight / total })
	end
	local previous = pet.mutation
	local outcome = V.roll(outcomes, unit)
	data.petMaterial -= Balance.MutationCost
	pet.baseBoost = V.base(pet)
	pet.mutation = outcome
	pet.upgradeLevel = 0
	pet.variantVersion = 1
	pet.craftRevision = revision + 1
	pet.boost = V.boost(pet)
	return true,
		outcome .. " mutation",
		{ kind = "Mutation", outcome = outcome, previous = previous, pet = table.clone(pet) }
end
return Craft
