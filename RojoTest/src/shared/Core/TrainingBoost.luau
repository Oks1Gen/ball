--!strict
-- Offers and values are reproducible; clients never submit a multiplier.
local Boost = {}
Boost.Interval = 7
Boost.Delay = 0.6
Boost.TravelTime = 0.85
Boost.HoldTime = 3
Boost.Lifetime = Boost.TravelTime + Boost.HoldTime
Boost.Grace = 0.16
Boost.Paid = { 67, 69, 144 }

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
	return age >= Boost.TravelTime and age <= Boost.Lifetime + math.clamp(allowance, 0, Boost.Grace)
end

function Boost.offer(seed: number, index: number): any
	if index % 5 == 4 then
		local multiplier = Boost.Paid[math.floor(index / 5) % #Boost.Paid + 1]
		return { multiplier = multiplier, product = "TrainingBoost" .. multiplier, color = 6 }
	end
	return {
		multiplier = (50 + math.floor(Boost.sample(seed, index, 7) * 101)) / 10,
		color = 1 + math.floor(Boost.sample(seed, index, 11) * 5),
	}
end

function Boost.reward(gain: number, acceptedCycle: number?, cycle: number, multiplier: number?): number
	return if acceptedCycle == cycle then math.floor(gain * math.clamp(multiplier or 1, 1, 144)) else gain
end

-- Purchased charges are spent only when a real training contact occurs.
function Boost.takeCharge(data: any): number?
	local charges = data.trainingBoosts
	if not charges then
		return nil
	end
	for i = #Boost.Paid, 1, -1 do
		local multiplier = Boost.Paid[i]
		local key = tostring(multiplier)
		if (charges[key] or 0) > 0 then
			charges[key] -= 1
			return multiplier
		end
	end
	return nil
end

return Boost
