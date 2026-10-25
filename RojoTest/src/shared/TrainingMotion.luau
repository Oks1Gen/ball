--!strict
-- One timeline drives both server rewards and visible ground contacts.
local Config = require(script.Parent.GameConfig)
local Motion = {}
Motion.FlightTime = 0.65

function Motion.hitCount(laneIndex)
	return laneIndex <= 3 and 3 or 4
end

function Motion.hitTime(laneIndex, hit)
	return Config.KickContact + Motion.FlightTime * hit / Motion.hitCount(laneIndex)
end

function Motion.position(start: Vector3, finish: Vector3, phase: number, laneIndex: number): Vector3
	local alpha = math.clamp((phase - Config.KickContact) / Motion.FlightTime, 0, 1)
	local hops = Motion.hitCount(laneIndex)
	local segment = math.min(math.floor(alpha * hops), hops - 1)
	local localAlpha = alpha * hops - segment
	local height = (1.7 - segment * 0.27) * math.sin(localAlpha * math.pi)
	-- Early hops stay on the turf. The final hop lifts toward the chosen net height.
	local lift = math.clamp(alpha * hops - (hops - 1), 0, 1)
	local rise = lift * lift * (3 - 2 * lift) * (finish.Y - start.Y)
	local flatFinish = Vector3.new(finish.X, start.Y, finish.Z)
	return start:Lerp(flatFinish, alpha) + Vector3.new(0, math.max(0, height) + rise, 0)
end

-- Fractional carry keeps small rewards and multipliers exact across contacts.
function Motion.reward(cycleGain, laneIndex, remainder)
	local raw = cycleGain / Motion.hitCount(laneIndex) + (remainder or 0)
	local gain = math.floor(raw + 1e-9)
	return gain, math.max(0, raw - gain)
end

return Motion
