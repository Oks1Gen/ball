--!strict
local Rewards = require("../src/shared/Core/ReturnRewards")
local Data = require("../src/shared/Core/ProfileData")
local catalog = { stones = { Pebble = true }, trails = { None = true }, pets = {} }

return {
	["offline accrual starts only with a real prior timestamp and caps at twelve hours"] = function()
		local data = Data.fresh()
		data.offlineRate = 2.1875
		Rewards.arrive(data, 100000)
		assert(data.offlinePending == 0)
		Rewards.arrive(data, 100004)
		assert(data.offlinePending == 8)
		data.offlinePending = 0
		Rewards.arrive(data, 100004 + 86400 * 10)
		assert(data.offlinePending == math.floor(2.1875 * 43200))
		local pending = data.offlinePending
		Rewards.arrive(data, data.lastSeen - 100)
		assert(data.offlinePending == pending)
	end,
	["unclaimed offline reward survives normalization and a claim cannot pay twice"] = function()
		local data = Data.fresh()
		data.offlinePending = 500
		data.offlineRate = 2.1875
		data.lastSeen = 1000
		data = Data.normalize(data, catalog)
		assert(data.offlineRate == 2.1875 and data.offlinePending == 500)
		assert(Rewards.claimOffline(data) == 500 and data.skill == 500)
		assert(Rewards.claimOffline(data) == 0 and data.skill == 500)
	end,
	["calendar follows UTC days and blocks duplicate claims across a reload"] = function()
		local data = Data.fresh()
		local now = 100 * 86400 + 86399
		local reward = Rewards.claimDaily(data, now)
		assert(reward and reward.skill == 100 and data.skill == 100)
		data = Data.normalize(data, catalog)
		assert(Rewards.claimDaily(data, now) == nil)
		assert(not Rewards.calendar(data, now).ready)
		assert(Rewards.calendar(data, now + 1).day == 2)
		Rewards.claimDaily(data, now + 1)
		assert(data.wins == 500)
	end,
	["missed days keep calendar progress and the seventh claim opens a new cycle tomorrow"] = function()
		local data = Data.fresh()
		for day = 1, 7 do
			local now = day * 3 * 86400
			assert(Rewards.calendar(data, now).day == day)
			assert(Rewards.claimDaily(data, now))
			local calendar = Rewards.calendar(data, now)
			assert(not calendar.ready and calendar.claimed == day)
		end
		local calendar = Rewards.calendar(data, 22 * 86400)
		assert(calendar.ready and calendar.day == 1 and calendar.claimed == 0)
	end,
	["legacy daily claims and malformed return fields normalize without inventing offline rewards"] = function()
		local data = Data.normalize({ daily = 100, dailyCount = 99, offlineRate = 0 / 0, lastSeen = -5 }, catalog)
		assert(data.dailyCount == 7 and data.offlineRate == 0 and data.lastSeen == 0)
		data = Data.normalize({ daily = 100 }, catalog)
		assert(data.dailyCount == 1 and not Rewards.calendar(data, 100 * 86400).ready)
		Rewards.arrive(data, 101 * 86400)
		assert(data.offlinePending == 0)
	end,
	["offline rate uses the best unlocked lane and permanent boosts"] = function()
		local data = Data.fresh()
		local lanes = { { multiplier = 1, rebirths = 0 }, { multiplier = 2, rebirths = 2 } }
		assert(Rewards.offlineRate(data, lanes, 1) == 7 / 0.8 * 0.25)
		data.rebirths = 2
		data.world = 2
		data.perks.DoubleSkill = true
		data.pets = { { uid = "pet", boost = 2 } }
		data.equipped = { "pet" }
		assert(Rewards.offlineRate(data, lanes, 5) == 2 * 3 * 3 * 2 * 2 * 5 * 7 / 0.8 * 0.25)
	end,
	["return rewards use the same progression cap as every other accrual"] = function()
		local data = Data.fresh()
		data.skill = Data.MaxProgress - 1
		data.offlinePending = 1000
		Rewards.claimOffline(data)
		assert(data.skill == Data.MaxProgress)
		Rewards.claimDaily(data, 100 * 86400)
		assert(data.skill == Data.MaxProgress)
	end,
}
