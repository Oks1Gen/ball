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
	local remaining = math.max(0, (data.adminEggPendingCount or 1) - 1)
	data.adminEggPendingCount = remaining
	data.perks.AdminEggPending = if remaining > 0 then true else nil
	return pet
end

function Rewards.reserve(data: any)
	local pending = if data.perks.AdminEggPending then data.adminEggPendingCount or 1 else 0
	data.adminEggPendingCount = pending + 1
	data.perks.AdminEgg = true
	data.perks.AdminEggPending = true
end

return Rewards
