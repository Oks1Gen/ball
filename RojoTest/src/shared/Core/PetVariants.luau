--!strict
local Balance = require("./Balance")
local V = {}
function V.form(pet: any): string
	return if Balance.Forms[pet.form] then pet.form else "Normal"
end
function V.mutation(id: any): any
	for _, entry in Balance.Mutations do
		if entry.id == id then
			return entry
		end
	end
	return nil
end
-- Frozen +10% per v2 level for in-session compatibility before normalization.
function V.base(pet: any): number
	return pet.baseBoost or (1 + (pet.boost - 1) / (1 + (pet.upgradeLevel or 0) * 0.1))
end
function V.boost(pet: any): number
	local mutation = V.mutation(pet.mutation)
	return 1 + (V.base(pet) - 1) * Balance.Forms[V.form(pet)].multiplier * (if mutation then mutation.multiplier else 1)
end
function V.name(pet: any): string
	return (if V.form(pet) ~= "Normal" then V.form(pet) .. " " else "")
		.. (if V.mutation(pet.mutation) then pet.mutation .. " " else "")
		.. pet.name
end
function V.odds(form: string, count: number): { any }
	local outcomes = Balance.FormOutcomes[form]
	if not outcomes then
		return {}
	end
	local success = math.clamp(count / Balance.FusionCount, 0, 1)
	local result = { { id = "Fail", chance = 1 - success } }
	local total = 0
	for _, entry in outcomes do
		total += entry.weight
	end
	for _, entry in outcomes do
		table.insert(result, { id = entry.id, chance = success * entry.weight / total })
	end
	return result
end
function V.roll(outcomes: { any }, unit: number): string
	assert(unit >= 0 and unit < 1, "RNG must be in [0,1)")
	local sum = 0
	for _, entry in outcomes do
		sum += entry.chance
		if unit < sum then
			return entry.id
		end
	end
	return outcomes[#outcomes].id
end
function V.same(a: any, b: any): boolean
	return a.id == b.id
		and V.form(a) == V.form(b)
		and a.eggId == b.eggId
		and a.sourceWorld == b.sourceWorld
		and math.abs(V.base(a) - V.base(b)) < 0.000001
end
return V
