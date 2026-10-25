--!strict
-- Shared clock curve: rendering and server validation use exactly the same phase.
local Timing = {}
Timing.Cycle = 1.6
Timing.PerfectHeight = 0.95

function Timing.height(elapsed: number): number
	local phase = math.max(0, elapsed) / (Timing.Cycle / 2) % 2
	local height = if phase <= 1 then phase else 2 - phase
	-- Round just the last 4% of a pass; keep the readable, constant-speed middle.
	local edge = 0.04
	local function roundEnd(x: number): number
		local t = x / edge
		return x * t * (2 - t)
	end
	if height < edge then
		return roundEnd(height)
	elseif height > 1 - edge then
		return 1 - roundEnd(1 - height)
	end
	return height
end

function Timing.multiplier(height: number): number
	return 2 ^ (2 * math.clamp(height, 0, 1) - 1)
end

function Timing.quality(multiplier: number): number
	return math.clamp(multiplier - 1, 0, 1)
end

function Timing.validRelease(started: number, pressed: number, now: number, allowance: number): boolean
	return pressed == pressed
		and math.abs(pressed) < math.huge
		and pressed >= started
		and pressed <= now + 0.05
		and now - pressed <= allowance
end

return Timing
