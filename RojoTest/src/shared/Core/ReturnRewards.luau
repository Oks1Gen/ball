--!strict
-- Server-owned calendar and offline accrual. No engine dependencies.
local Data = require("./ProfileData")
local Rewards = {}

Rewards.OfflineFraction = 0.25
Rewards.OfflineCapSeconds = 12 * 60 * 60
Rewards.Days = {
	{ skill = 100, wins = 0 },
	{ skill = 0, wins = 500 },
	{ skill = 500, wins = 0 },
	{ skill = 0, wins = 1500 },
	{ skill = 2000, wins = 0 },
	{ skill = 0, wins = 5000 },
	{ skill = 10000, wins = 10000 },
}

-- Best unlocked lane, permanent multipliers only; friends are online-only.
function Rewards.offlineRate(data: any, lanes: any, ballPower: number): number
	local gain = 1
	for _, lane in lanes do
		if data.rebirths >= lane.rebirths then
			gain = math.max(gain, lane.multiplier)
		end
	end
	local pets = 1
	for _, uid in data.equipped do
		for _, pet in data.pets do
			if pet.uid == uid then
				pets += math.max(0, (pet.boost or 1) - 1)
				break
			end
		end
	end
	local multiplier = (1 + data.rebirths)
		* pets
		* ballPower
		* (if data.perks.DoubleSkill then 2 else 1)
		* (if data.world == 2 then 3 else 1)
	return math.min(Data.MaxProgress, gain * multiplier * 7 / 0.8 * Rewards.OfflineFraction)
end

function Rewards.arrive(data: any, now: number)
	local elapsed = if data.lastSeen > 0 then math.clamp(now - data.lastSeen, 0, Rewards.OfflineCapSeconds) else 0
	Data.add(data, "offlinePending", elapsed * data.offlineRate)
	data.lastSeen = now
end

function Rewards.claimOffline(data: any): number
	local amount = data.offlinePending
	data.offlinePending = 0
	Data.add(data, "skill", amount)
	return amount
end

function Rewards.calendar(data: any, now: number): any
	local today = math.floor(now / 86400)
	local ready = data.daily < today
	local claimed = if ready then data.dailyCount % #Rewards.Days else math.max(1, data.dailyCount)
	return {
		ready = ready,
		day = if ready then claimed + 1 else claimed,
		claimed = claimed,
		nextAt = (today + 1) * 86400,
	}
end

function Rewards.claimDaily(data: any, now: number): any?
	local calendar = Rewards.calendar(data, now)
	if not calendar.ready then
		return nil
	end
	local reward = Rewards.Days[calendar.day]
	data.daily = math.floor(now / 86400)
	data.dailyCount = calendar.day
	Data.add(data, "skill", reward.skill)
	Data.add(data, "wins", reward.wins)
	return reward
end

return Rewards
