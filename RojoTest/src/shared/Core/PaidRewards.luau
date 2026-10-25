--!strict
-- A paid pet stays reserved across saves until the player has a free slot.
local Rewards = {}

function Rewards.claim(data: any, definition: any, uid: string): any
	if not data.perks.AdminEggPending or #data.pets >= 60 then
		return nil
	end
	local pet = {
		uid = uid,
		id = definition.id,
		name = definition.name,
		boost = definition.boost,
		rarity = definition.rarity,
	}
	table.insert(data.pets, pet)
	data.perks.AdminEggPending = nil
	return pet
end

function Rewards.reserve(data: any)
	if not data.perks.AdminEgg then
		data.perks.AdminEgg = true
		data.perks.AdminEggPending = true
	end
end

return Rewards
