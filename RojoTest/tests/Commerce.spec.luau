--!strict
local Catalog = require("../src/shared/CommerceCatalog")
local PassRewards = require("../src/shared/Core/PassRewards")
local Data = require("../src/shared/Core/ProfileData")
return {
	["Dev reset clears paid benefits spending charges and reserved pets but preserves fulfillment records"] = function()
		local data = Data.fresh()
		PassRewards.apply(data, "StarterPack")
		PassRewards.apply(data, "AutoThrow")
		PassRewards.apply(data, "DoubleWins")
		data.skill, data.donated = 1000000, 500
		data.receipts["paid-once"] = true
		data.trainingBoosts["144"] = 2
		data.perks.AdminEggPending, data.adminEggPendingCount = true, 2
		data.settings.sound = 43
		local reset = Data.resetProgress(data)
		assert(reset.skill == 0 and reset.wins == 0 and reset.donated == 0)
		assert(next(reset.perks) == nil and reset.trainingBoosts["144"] == 0 and reset.adminEggPendingCount == nil)
		assert(#reset.pets == 0 and reset.receipts["paid-once"] and reset.passGrants.StarterPack)
		assert(reset.settings.sound == 43 and reset.settings ~= data.settings)
		reset = Data.normalize(reset, { stones = {}, trails = {}, pets = {} })
		assert(PassRewards.apply(reset, "StarterPack"))
		assert(reset.wins == 0 and reset.perks.StarterPack and reset.perks.DoubleSkill)
	end,
	["legacy Starter Pack markers migrate before reset so ownership restoration cannot pay twice"] = function()
		local old = Data.fresh()
		old.passGrants = nil
		old.perks.StarterPack = true
		local data = Data.normalize(old, { stones = {}, trails = {}, pets = {} })
		assert(data.passGrants.StarterPack)
		local reset = Data.resetProgress(old)
		PassRewards.apply(reset, "StarterPack")
		assert(reset.wins == 0 and reset.passGrants.StarterPack)
	end,
	["Roblox catalog has unique configured IDs and grants for every repeatable product"] = function()
		local ids, passes, products = {}, 0, 0
		for key, item in Catalog do
			assert(item.id > 0 and item.id % 1 == 0 and not ids[item.id], key)
			ids[item.id] = true
			assert(item.price > 0 and item.price % 1 == 0, key)
			if item.kind == "GamePass" then
				passes += 1
				local data = Data.fresh()
				assert(PassRewards.apply(data, key), key)
				assert(PassRewards.owned(data, key, item.kind), key)
			elseif item.kind == "DeveloperProduct" then
				products += 1
				assert(item.skill or item.trainingBoost or key == "SkipRebirth" or key == "AdminEgg", key)
			else
				error("Unknown kind: " .. item.kind)
			end
		end
		assert(passes == 4 and products == 8)
	end,
	["Starter Pack restores permanent Skill and grants its Wins exactly once across reload"] = function()
		local data = Data.fresh()
		assert(PassRewards.apply(data, "StarterPack"))
		assert(data.wins == 10000 and data.perks.DoubleSkill and data.perks.StarterPack)
		data = Data.normalize(data, { stones = {}, trails = {}, pets = {} })
		assert(not PassRewards.apply(data, "StarterPack"))
		assert(data.wins == 10000)
		data.perks.DoubleSkill = nil
		assert(PassRewards.apply(data, "StarterPack"))
		assert(data.perks.DoubleSkill and data.wins == 10000)
	end,
	["separate Skill pass and Starter Pack do not stack or revoke other ownership"] = function()
		local data = Data.fresh()
		PassRewards.apply(data, "DoubleSkill")
		PassRewards.apply(data, "StarterPack")
		PassRewards.apply(data, "DoubleWins")
		assert(data.perks.DoubleSkill == true and data.perks.DoubleWins and data.wins == 10000)
		assert(not PassRewards.apply(data, "DoubleSkill"))
	end,
	["paid eggs and boosts remain repeatable even after a prior purchase"] = function()
		local data = Data.fresh()
		data.perks.AdminEgg = true
		assert(not PassRewards.owned(data, "AdminEgg", "DeveloperProduct"))
		assert(not PassRewards.apply(data, "AdminEgg"))
		assert(not PassRewards.apply(data, "Skill10M"))
	end,
}
