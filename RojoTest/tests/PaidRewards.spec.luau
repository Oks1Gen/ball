--!strict
local Data = require("../src/shared/Core/ProfileData")
local Rewards = require("../src/shared/Core/PaidRewards")
local Log = require("../src/server/ProfileLog")
local definition = { id = "AdminDragon", name = "Dragon", rarity = "Mythic", boost = 25 }
local catalog = { stones = {}, trails = {}, pets = { AdminDragon = definition } }

return {
	["a full inventory preserves the paid pet reservation across a save and load"] = function()
		local data = Data.fresh()
		for i = 1, 60 do
			table.insert(data.pets, { uid = tostring(i), id = definition.id, boost = 1 })
		end
		Rewards.reserve(data)
		assert(Rewards.claim(data, definition, "paid") == nil)
		data = Data.normalize(data, catalog)
		assert(data.perks.AdminEgg and data.perks.AdminEggPending and #data.pets == 60)
		table.remove(data.pets)
		local pet = Rewards.claim(data, definition, "paid")
		assert(pet and pet.uid == "paid" and #data.pets == 60 and not data.perks.AdminEggPending)
		Rewards.reserve(data)
		assert(Rewards.claim(data, definition, "duplicate") == nil)
	end,
	["a paid pet with a free slot is issued once"] = function()
		local data = Data.fresh()
		Rewards.reserve(data)
		assert(Rewards.claim(data, definition, "paid"))
		assert(Rewards.claim(data, definition, "duplicate") == nil)
		assert(#data.pets == 1 and data.perks.AdminEgg)
	end,
	["profile diagnostics mask current and legacy keys and embedded user ids"] = function()
		local message =
			Log.redact("Player_123456789 / u_123456789 / user 123456789 / retry 42", nil, "Player_123456789")
		assert(not message:find("123456789", 1, true) and message:find("retry 42", 1, true))
		assert(Log.redact("key x.y[1] failed", nil, "x.y[1]") == "key <key> failed")
	end,
}
