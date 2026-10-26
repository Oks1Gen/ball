--!strict
-- One clock for the slow backswing, fast strike, flight launch and server rewards.
local Timing = require("./KickTiming")
local Perfect = {}
Perfect.Contact = 0.42
Perfect.PoseDuration = 0.86

function Perfect.power(multiplier: number): boolean
	return multiplier >= Timing.multiplier(Timing.PerfectHeight)
end

function Perfect.count(power: number, accuracy: number): number
	return (if Perfect.power(power) then 1 else 0) + (if accuracy >= 3 - 1e-8 then 1 else 0)
end

function Perfect.windup(count: number): number
	return if count >= 2 then 0.92 elseif count >= 1 then 0.78 else Perfect.Contact
end

function Perfect.phase(elapsed: number, count: number): number
	if count <= 0 or elapsed <= 0 then
		return elapsed
	end
	local contact = Perfect.windup(count)
	local slowEnd = contact - 0.12
	if elapsed < slowEnd then
		return 0.31 * math.sin(elapsed / slowEnd * math.pi / 2)
	elseif elapsed < contact then
		local strike = (elapsed - slowEnd) / 0.12
		return 0.31 + (Perfect.Contact - 0.31) * strike * strike
	end
	return Perfect.Contact + (elapsed - contact) * 1.35
end

function Perfect.selectionFov(age: number): number
	if age < 0 or age >= 0.52 then
		return 0
	end
	local rise = math.min(1, age / 0.10)
	local fall = math.max(0, 1 - math.max(0, age - 0.10) / 0.42)
	return -8 * rise * rise * (3 - 2 * rise) * fall * fall
end

function Perfect.charge(elapsed: number, windup: number): number
	local t = math.clamp(elapsed / math.max(0.01, windup - 0.12), 0, 1)
	return t * t * (3 - 2 * t)
end

function Perfect.impactFov(age: number, count: number): number
	if age < 0 or count <= 0 then
		return 0
	end
	return (8 + count * 3) * (1 - math.exp(-age * 40)) * math.exp(-age * 4.8)
		+ math.sin(age * 32) * (2 + count) * math.exp(-age * 7)
end

return Perfect
