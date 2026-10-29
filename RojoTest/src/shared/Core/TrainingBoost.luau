--!strict
-- Shared schedule; the server independently validates every offer and reward.
local Boost = {}
Boost.Interval = 6
Boost.Delay = 0.6
Boost.TravelTime = 0.85
Boost.Lifetime = 3
Boost.Grace = 0.16
local values = { 1.6, 2, 2.5, 3, 4 }
local cumulative = { 45, 75, 90, 98, 100 }

function Boost.sample(seed: number, offer: number, salt: number): number
	local value = (seed + offer * 104729 + salt * 7919) % 2147483647
	value = (value * 48271) % 2147483647
	value = (value * 48271) % 2147483647
	return value / 2147483647
end
function Boost.index(elapsed: number): number
	return math.floor((elapsed - Boost.Delay) / Boost.Interval)
end
function Boost.age(started: number, offer: number, now: number): number
	return now - started - Boost.Delay - offer * Boost.Interval
end
function Boost.inWindow(started: number, offer: number, now: number, allowance: number): boolean
	if offer < 0 or offer % 1 ~= 0 then
		return false
	end
	local age = Boost.age(started, offer, now)
	return age >= 0.15 and age <= Boost.Lifetime + math.clamp(allowance, 0, Boost.Grace)
end
function Boost.multiplier(seed: number, offer: number): number
	local roll = Boost.sample(seed, offer, 7) * 100
	for i, threshold in cumulative do
		if roll < threshold then
			return values[i]
		end
	end
	return 4
end
function Boost.reward(gain: number, acceptedCycle: number?, cycle: number, multiplier: number?): number
	return if acceptedCycle == cycle then math.floor(gain * math.clamp(multiplier or 2, 1, 4)) else gain
end
return Boost
