--!strict
local Zones = {}
function Zones.multiplier(zone: number): number
	return (10 + math.clamp(math.floor(zone), 1, 8) - 1) / 10
end
function Zones.award(base: number, zone: number): number
	-- Integer tenths avoid rounding 100 * 1.2 down to 119.
	return math.floor(math.floor(base) * (10 + math.clamp(math.floor(zone), 1, 8) - 1) / 10)
end
function Zones.reached(crossings: { any }, alpha: number): number
	local zone = 1
	for _, crossing in crossings do
		if alpha >= crossing.alpha then
			zone = math.max(zone, crossing.zone)
		end
	end
	return zone
end
function Zones.pulse(age: number): number
	if age < 0 or age >= 0.4 then
		return 0
	end
	if age < 0.08 then
		return 7 * math.sin(age / 0.08 * math.pi / 2)
	end
	return 7 * (1 - (age - 0.08) / 0.32) ^ 2
end
return Zones
