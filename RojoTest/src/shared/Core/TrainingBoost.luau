--!strict
-- No client-supplied multiplier, hit location or clock is needed for a practice boost.
local Boost = {}
Boost.Multiplier = 2
Boost.MinimumGap = 3

-- Keep at least three empty seconds after a missed target's windup ends.
-- The shared cadence also prevents requesting bonuses on the intervening kicks.
function Boost.available(cycle: number, period: number, windup: number): boolean
	local stride = math.max(1, math.ceil((Boost.MinimumGap + windup) / period))
	return cycle >= 0 and cycle % 1 == 0 and cycle % stride == 0
end

function Boost.inWindow(
	started: number,
	cycle: number,
	now: number,
	period: number,
	windup: number,
	allowance: number
): boolean
	local phase = now - started - cycle * period
	return Boost.available(cycle, period, windup) and phase >= 0 and phase <= windup + math.clamp(allowance, 0, 0.16)
end

function Boost.reward(gain: number, acceptedCycle: number?, cycle: number): number
	return if acceptedCycle == cycle then gain * Boost.Multiplier else gain
end

return Boost
